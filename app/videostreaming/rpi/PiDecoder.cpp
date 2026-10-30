#include "PiDecoder.hpp"
extern "C" {
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
}
#include <linux/dma-heap.h>
#include <linux/dma-buf.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <atomic>
#include <cstring>
#include <stdexcept>

namespace nxp {
PiDecoder::PiDecoder(bool hevc, bool reorder) {
    const auto* decoder = avcodec_find_decoder(hevc ? AV_CODEC_ID_HEVC : AV_CODEC_ID_H264);
    if (!decoder) throw std::runtime_error("Pi FFmpeg decoder unavailable");
    codec_ = avcodec_alloc_context3(decoder);
    frame_ = av_frame_alloc();
    if (!codec_ || !frame_) { avcodec_free_context(&codec_); av_frame_free(&frame_); throw std::bad_alloc(); }
    codec_->thread_count = 4;
    codec_->thread_type = FF_THREAD_SLICE;
    if (!reorder) codec_->flags |= AV_CODEC_FLAG_LOW_DELAY;
    codec_->pkt_timebase = AVRational{1, 1000000};
    if (avcodec_open2(codec_, decoder, nullptr) < 0) {
        avcodec_free_context(&codec_); av_frame_free(&frame_);
        throw std::runtime_error("Pi FFmpeg decoder open failed");
    }
    for (const char* path : {"/dev/dma_heap/linux,cma", "/dev/dma_heap/vidbuf_cached", "/dev/dma_heap/system"}) {
        heap_ = open(path, O_RDWR | O_CLOEXEC);
        if (heap_ >= 0) break;
    }
    if (heap_ < 0) {
        avcodec_free_context(&codec_); av_frame_free(&frame_);
        throw std::runtime_error("Pi decoder requires a DMA heap (vc4 KMS/CMA)");
    }
}
PiDecoder::~PiDecoder() {
    sws_freeContext(conversion_); av_frame_free(&frame_);
    avcodec_free_context(&codec_); if (heap_ >= 0) close(heap_);
}
void PiDecoder::push(std::vector<uint8_t>& bytes, uint64_t receivedUs, const Output& output) {
    auto* packet = av_packet_alloc();
    if (!packet) throw std::bad_alloc();
    if (av_new_packet(packet, int(bytes.size())) < 0) { av_packet_free(&packet); throw std::bad_alloc(); }
    std::memcpy(packet->data, bytes.data(), bytes.size());
    packet->pts = packet->dts = int64_t(receivedUs);
    int result = avcodec_send_packet(codec_, packet);
    if (result == AVERROR(EAGAIN)) { receive(output); result = avcodec_send_packet(codec_, packet); }
    av_packet_free(&packet);
    if (result < 0) throw std::runtime_error("Pi decoder rejected access unit");
    receive(output);
}
void PiDecoder::drain(const Output& output) {
    int result = avcodec_send_packet(codec_, nullptr);
    if (result == AVERROR(EAGAIN)) { receive(output); result = avcodec_send_packet(codec_, nullptr); }
    if (result < 0 && result != AVERROR_EOF) throw std::runtime_error("Pi decoder drain failed");
    receive(output);
}
void PiDecoder::receive(const Output& output) {
    int result;
    while ((result = avcodec_receive_frame(codec_, frame_)) >= 0) {
        if (frame_->width < 1 || frame_->height < 1 || frame_->width > 4096 || frame_->height > 4096)
            throw std::runtime_error("Pi decoder unsupported frame dimensions");
        const size_t stride = (size_t(frame_->width) + 63) & ~size_t(63);
        const size_t height = (size_t(frame_->height) + 1) & ~size_t(1);
        const size_t size = (stride * height * 3 / 2 + 4095) & ~size_t(4095);
        auto decoded = std::make_shared<DecodedFrame>();
        // Bound display leases across primary, secondary and decoder restarts.
        static auto outstanding = std::make_shared<std::atomic<unsigned>>(0);
        if (outstanding->fetch_add(1) >= 16) { --*outstanding; av_frame_unref(frame_); continue; }
        auto count = outstanding;
        dma_heap_allocation_data allocation{};
        allocation.len = size; allocation.fd_flags = O_RDWR | O_CLOEXEC;
        if (ioctl(heap_, DMA_HEAP_IOCTL_ALLOC, &allocation) < 0) {
            --*count; throw std::runtime_error("Pi DMA heap allocation failed");
        }
        decoded->fd = int(allocation.fd);
        decoded->release = [fd = decoded->fd, count] { close(fd); --*count; };
        auto* mapping = static_cast<uint8_t*>(mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, decoded->fd, 0));
        if (mapping == MAP_FAILED) throw std::runtime_error("Pi DMA heap mmap failed");
        dma_buf_sync sync{DMA_BUF_SYNC_START | DMA_BUF_SYNC_WRITE};
        if (ioctl(decoded->fd, DMA_BUF_IOCTL_SYNC, &sync) < 0) { munmap(mapping, size); throw std::runtime_error("Pi DMA write sync failed"); }
        conversion_ = sws_getCachedContext(conversion_, frame_->width, frame_->height,
            AVPixelFormat(frame_->format), frame_->width, frame_->height, AV_PIX_FMT_NV12,
            SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
        uint8_t* planes[] = {mapping, mapping + stride * height, nullptr, nullptr};
        int strides[] = {int(stride), int(stride), 0, 0};
        const int rows = conversion_ ? sws_scale(conversion_, frame_->data, frame_->linesize, 0, frame_->height, planes, strides) : -1;
        sync.flags = DMA_BUF_SYNC_END | DMA_BUF_SYNC_WRITE;
        const int synced = ioctl(decoded->fd, DMA_BUF_IOCTL_SYNC, &sync);
        munmap(mapping, size);
        if (rows != frame_->height || synced < 0) throw std::runtime_error("Pi NV12 conversion/sync failed");
        decoded->width = frame_->width; decoded->height = frame_->height;
        decoded->paddedWidth = stride; decoded->paddedHeight = height;
        decoded->yStride = decoded->uvStride = stride; decoded->uvOffset = stride * height;
        decoded->receivedUs = frame_->pts == AV_NOPTS_VALUE ? 0 : uint64_t(frame_->pts);
        av_frame_unref(frame_);
        output(std::move(decoded));
    }
    if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) throw std::runtime_error("Pi decoder output failed");
}
}
