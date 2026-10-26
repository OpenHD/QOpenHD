#include "HantroDecoder.hpp"
#include "VpuApi.hpp"
#include <imxdmabuffer/imxdmabuffer.h>
#include <stdexcept>
#include <cstdio>

namespace nxp {
static void check(ImxVpuApiDecReturnCodes result) {
    if (result != IMX_VPU_API_DEC_RETURN_CODE_OK)
        throw std::runtime_error(vpu().imx_vpu_api_dec_return_code_string(result));
}
DecodedFrame::~DecodedFrame() { if (owner) owner->release(raw.fb_dma_buffer); }
int DecodedFrame::dmaFd() const { return vpu().imx_dma_buffer_get_fd(raw.fb_dma_buffer); }
HantroDecoder::HantroDecoder(bool hevc, bool reorder) {
    try {
        int error = 0;
        allocator_ = vpu().imx_dma_buffer_allocator_new(&error);
        if (!allocator_) throw std::runtime_error("cannot create NXP DMA allocator");
        auto global = vpu().imx_vpu_api_dec_get_global_info();
        if (!(global->flags & IMX_VPU_API_DEC_GLOBAL_INFO_FLAG_DECODED_FRAMES_ARE_FROM_BUFFER_POOL))
            throw std::runtime_error("this backend requires Hantro framebuffer pool output");
        if (global->min_required_stream_buffer_size) {
            stream_ = vpu().imx_dma_buffer_allocate(allocator_, global->min_required_stream_buffer_size,
                                            global->required_stream_buffer_physaddr_alignment, &error);
            if (!stream_) throw std::runtime_error("cannot allocate VPU stream buffer");
        }
        ImxVpuApiDecOpenParams params{};
        params.compression_format = hevc ? IMX_VPU_API_COMPRESSION_FORMAT_H265 : IMX_VPU_API_COMPRESSION_FORMAT_H264;
        // Request linear NV12. Only the local boot movie enables reordering;
        // live flight streams retain immediate decode-order output.
        params.flags = IMX_VPU_API_DEC_OPEN_PARAMS_FLAG_USE_SEMI_PLANAR_COLOR_FORMAT;
        if (reorder) params.flags |= IMX_VPU_API_DEC_OPEN_PARAMS_FLAG_ENABLE_FRAME_REORDERING;
        check(vpu().imx_vpu_api_dec_open(&decoder_, &params, stream_));
    } catch (...) {
        if (decoder_) vpu().imx_vpu_api_dec_close(decoder_);
        if (stream_) vpu().imx_dma_buffer_deallocate(stream_);
        if (allocator_) vpu().imx_dma_buffer_allocator_destroy(allocator_);
        throw;
    }
}
HantroDecoder::~HantroDecoder() {
    if (decoder_) vpu().imx_vpu_api_dec_close(decoder_);
    for (auto buffer : buffers_) vpu().imx_dma_buffer_deallocate(buffer);
    if (stream_) vpu().imx_dma_buffer_deallocate(stream_);
    if (allocator_) vpu().imx_dma_buffer_allocator_destroy(allocator_);
}
void HantroDecoder::release(ImxDmaBuffer* buffer) {
    std::lock_guard<std::mutex> lock(mutex_);
    vpu().imx_vpu_api_dec_return_framebuffer_to_decoder(decoder_, buffer);
}
void HantroDecoder::addBuffers(size_t count) {
    if (buffers_.size() + count > 16) throw std::runtime_error("VPU framebuffer limit exceeded");
    std::vector<ImxDmaBuffer*> added;
    for (size_t i = 0; i < count; ++i) {
        int error = 0;
        auto buffer = vpu().imx_dma_buffer_allocate(allocator_, info_.min_fb_pool_framebuffer_size,
                                            info_.fb_pool_framebuffer_alignment, &error);
        if (!buffer) throw std::runtime_error("cannot allocate VPU framebuffer");
        buffers_.push_back(buffer); added.push_back(buffer);
    }
    check(vpu().imx_vpu_api_dec_add_framebuffers_to_pool(decoder_, added.data(), nullptr, added.size()));
}
void HantroDecoder::push(std::vector<uint8_t>& bytes, uint64_t receivedUs,
                        const std::function<void(std::shared_ptr<DecodedFrame>)>& output) {
    ImxVpuApiEncodedFrame encoded{};
    encoded.data = bytes.data(); encoded.data_size = bytes.size(); encoded.pts = receivedUs;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        check(vpu().imx_vpu_api_dec_push_encoded_frame(decoder_, &encoded));
    }
    readOutput(output, false);
}
void HantroDecoder::drain(const std::function<void(std::shared_ptr<DecodedFrame>)>& output) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        vpu().imx_vpu_api_dec_enable_drain_mode(decoder_);
    }
    readOutput(output, true);
}
void HantroDecoder::readOutput(const std::function<void(std::shared_ptr<DecodedFrame>)>& output, bool draining) {
    std::unique_lock<std::mutex> lock(mutex_);
    for (unsigned steps = 0; steps < 256; ++steps) {
        ImxVpuApiDecOutputCodes code;
        check(vpu().imx_vpu_api_dec_decode(decoder_, &code));
        switch (code) {
        case IMX_VPU_API_DEC_OUTPUT_CODE_MORE_INPUT_DATA_NEEDED: return;
        case IMX_VPU_API_DEC_OUTPUT_CODE_EOS:
            if (draining) return;
            throw std::runtime_error("unexpected VPU end of stream");
        case IMX_VPU_API_DEC_OUTPUT_CODE_NEW_STREAM_INFO_AVAILABLE:
            info_ = *vpu().imx_vpu_api_dec_get_stream_info(decoder_);
            if (info_.color_format != IMX_VPU_API_COLOR_FORMAT_SEMI_PLANAR_YUV420_8BIT ||
                (info_.flags & IMX_VPU_API_DEC_STREAM_INFO_FLAG_INTERLACED))
                throw std::runtime_error("unsupported VPU output: progressive linear NV12 required");
            std::fprintf(stderr, "NXP stream: %zux%zu NV12, minimum buffers=%zu\n",
                         info_.decoded_frame_framebuffer_metrics.actual_frame_width,
                         info_.decoded_frame_framebuffer_metrics.actual_frame_height, info_.min_num_required_framebuffers);
            std::fprintf(stderr, "NXP geometry: aligned=%zux%zu crop=%zu,%zu %zux%zu stride=%zu/%zu\n",
                info_.decoded_frame_framebuffer_metrics.aligned_frame_width,
                info_.decoded_frame_framebuffer_metrics.aligned_frame_height,
                info_.crop_left, info_.crop_top, info_.crop_width, info_.crop_height,
                info_.decoded_frame_framebuffer_metrics.y_stride, info_.decoded_frame_framebuffer_metrics.uv_stride);
            addBuffers(info_.min_num_required_framebuffers);
            break;
        case IMX_VPU_API_DEC_OUTPUT_CODE_NEED_ADDITIONAL_FRAMEBUFFER: addBuffers(1); break;
        case IMX_VPU_API_DEC_OUTPUT_CODE_DECODED_FRAME_AVAILABLE: {
            auto frame = std::make_shared<DecodedFrame>();
            check(vpu().imx_vpu_api_dec_get_decoded_frame(decoder_, &frame->raw));
            frame->owner = shared_from_this(); frame->info = info_;
            // Output can release an older frame; never invoke it under the VPU lock.
            lock.unlock(); output(std::move(frame)); lock.lock();
            break;
        }
        case IMX_VPU_API_DEC_OUTPUT_CODE_FRAME_SKIPPED: {
            ImxVpuApiDecSkippedFrameReasons reason; void* context; uint64_t pts, dts;
            vpu().imx_vpu_api_dec_get_skipped_frame_info(decoder_, &reason, &context, &pts, &dts);
            break;
        }
        case IMX_VPU_API_DEC_OUTPUT_CODE_NO_OUTPUT_YET_AVAILABLE: break;
        default: throw std::runtime_error("VPU stream changed or ended; reopen at next keyframe");
        }
    }
    throw std::runtime_error("VPU decoder made no bounded progress");
}
}
