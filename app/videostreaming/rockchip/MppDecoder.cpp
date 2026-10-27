#include "MppDecoder.hpp"
#include <mpp_buffer.h>
#include <mpp_frame.h>
#include <mpp_packet.h>
#include <chrono>
#include <thread>
#include <stdexcept>
#include <cstdio>
#include <limits>

namespace nxp {
namespace {
void check(MPP_RET ret, const char* what) {
    if (ret != MPP_OK) throw std::runtime_error(what);
}
struct FrameGuard {
    MppFrame value = nullptr;
    ~FrameGuard() { if (value) mpp_frame_deinit(&value); }
};
}
MppDecoder::MppDecoder(bool hevc, bool reorder) : hevc_(hevc), reorder_(reorder) {
    try {
        check(mpp_create(&ctx_, &api_), "MPP create failed");
        RK_U32 split = 0;
        check(api_->control(ctx_, MPP_DEC_SET_PARSER_SPLIT_MODE, &split), "MPP complete-picture parser setup failed");
        check(mpp_init(ctx_, MPP_CTX_DEC, hevc ? MPP_VIDEO_CodingHEVC : MPP_VIDEO_CodingAVC), "MPP codec init failed");
        RK_S32 block = MPP_POLL_NON_BLOCK;
        check(api_->control(ctx_, MPP_SET_OUTPUT_TIMEOUT, &block), "MPP nonblocking output setup failed");
        MppFrameFormat fmt = MPP_FMT_YUV420SP;
        check(api_->control(ctx_, MPP_DEC_SET_OUTPUT_FORMAT, &fmt), "MPP NV12 setup failed");
        if (!reorder) {
            RK_U32 on = 1;
            // Optional latency hints differ across BSP MPP revisions. Required
            // layout/pool controls are checked; hints cannot relax validation.
            api_->control(ctx_, MPP_DEC_SET_IMMEDIATE_OUT, &on);
            api_->control(ctx_, MPP_DEC_SET_ENABLE_FAST_PLAY, &on);
        }
    } catch (...) {
        if (ctx_) mpp_destroy(ctx_);
        ctx_ = nullptr; throw;
    }
}
MppDecoder::~MppDecoder() {
    if (ctx_) mpp_destroy(ctx_);
    if (group_) mpp_buffer_group_put(group_);
}
void MppDecoder::packet(const uint8_t* data, size_t size, uint64_t pts, const Output& output, bool eos) {
    MppPacket p = nullptr;
    check(mpp_packet_init(&p, const_cast<uint8_t*>(data), size), "MPP packet init failed");
    mpp_packet_set_pts(p, pts);
    if (eos) mpp_packet_set_eos(p);
    try {
        // Local movie callbacks pace B frames by PTS. Their deliberate sleep
        // must not look like a stalled live decoder. Live input stays bounded.
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(reorder_ ? 1000 : 100);
        while (api_->decode_put_packet(ctx_, p) != MPP_OK) {
            poll(output);
            if (std::chrono::steady_clock::now() >= deadline)
                throw std::runtime_error("MPP input stalled beyond its retry budget");
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    } catch (...) { mpp_packet_deinit(&p); throw; }
    mpp_packet_deinit(&p);
    poll(output);
}
void MppDecoder::push(std::vector<uint8_t>& bytes, uint64_t receivedUs, const Output& output) {
    // Vendor MPP expects non-VCL headers separately, but all slices of one
    // picture together. The RTP parser already supplies bounded Annex-B AUs.
    std::vector<uint8_t> picture;
    for (size_t pos = 0; pos + 4 < bytes.size();) {
        size_t end = pos + 4;
        while (end + 3 < bytes.size() && !(bytes[end] == 0 && bytes[end+1] == 0 && bytes[end+2] == 0 && bytes[end+3] == 1)) ++end;
        if (end + 3 >= bytes.size()) end = bytes.size();
        const unsigned type = hevc_ ? (bytes[pos+4] >> 1) & 63 : bytes[pos+4] & 31;
        const bool vcl = hevc_ ? type < 32 : type == 1 || type == 5;
        if (vcl) picture.insert(picture.end(), bytes.begin()+pos, bytes.begin()+end);
        else packet(bytes.data()+pos, end-pos, receivedUs, output);
        pos = end;
    }
    if (!picture.empty()) packet(picture.data(), picture.size(), receivedUs, output);
}
void MppDecoder::poll(const Output& output) {
    for (unsigned i = 0; i < 32; ++i) {
        FrameGuard frame;
        const auto ret = api_->decode_get_frame(ctx_, &frame.value);
        if (ret == MPP_ERR_TIMEOUT) return;
        check(ret, "MPP get frame failed");
        if (!frame.value) return;
        auto f = frame.value;
        if (mpp_frame_get_info_change(f)) {
            // Parameter-set changes in UdpVideo create a new decoder generation.
            // An unannounced layout change must also reopen at the next IDR.
            if (group_) throw std::runtime_error("MPP layout changed; reacquire keyframe");
            auto ret = mpp_buffer_group_get_internal(&group_, MPP_BUFFER_TYPE_DRM);
            if (ret != MPP_OK) ret = mpp_buffer_group_get_internal(&group_, MPP_BUFFER_TYPE_ION);
            check(ret, "MPP DMA output pool allocation failed");
            const auto size = mpp_frame_get_buf_size(f);
            if (!size || size > 128U * 1024U * 1024U) throw std::runtime_error("MPP invalid output pool size");
            check(mpp_buffer_group_limit_config(group_, size, 16), "MPP output pool limit failed");
            check(api_->control(ctx_, MPP_DEC_SET_EXT_BUF_GROUP, group_), "MPP output pool registration failed");
            check(api_->control(ctx_, MPP_DEC_SET_INFO_CHANGE_READY, nullptr), "MPP info-change acknowledgement failed");
            std::fprintf(stderr, "Rockchip MPP: %ux%u stride=%ux%u pool=16 bytes=%zu\n",
                         mpp_frame_get_width(f), mpp_frame_get_height(f),
                         mpp_frame_get_hor_stride(f), mpp_frame_get_ver_stride(f), size);
            continue;
        }
        if (mpp_frame_get_eos(f)) eos_ = true;
        auto buffer = mpp_frame_get_buffer(f);
        if (!buffer) continue;
        if (mpp_frame_get_errinfo(f) || mpp_frame_get_discard(f))
            throw std::runtime_error("MPP corrupt frame; reacquire keyframe");
        const auto fmt = mpp_frame_get_fmt(f);
        if (fmt != MPP_FMT_YUV420SP || (mpp_frame_get_mode(f) & MPP_FRAME_FLAG_PAIRED_FIELD))
            throw std::runtime_error("MPP requires progressive linear 8-bit NV12");
        auto decoded = std::make_shared<DecodedFrame>();
        decoded->width = mpp_frame_get_width(f); decoded->height = mpp_frame_get_height(f);
        decoded->paddedWidth = mpp_frame_get_hor_stride(f); decoded->paddedHeight = mpp_frame_get_ver_stride(f);
        decoded->yStride = decoded->uvStride = decoded->paddedWidth;
        const uint64_t uv = uint64_t(decoded->yStride) * decoded->paddedHeight;
        const uint64_t end = uv + uint64_t(decoded->uvStride) * ((decoded->paddedHeight+1)/2);
        decoded->fd = mpp_buffer_get_fd(buffer);
        if (decoded->fd < 0 || !decoded->width || !decoded->height ||
            decoded->paddedWidth < decoded->width || decoded->paddedHeight < decoded->height ||
            end > mpp_buffer_get_size(buffer) || uv > std::numeric_limits<uint32_t>::max())
            throw std::runtime_error("MPP invalid DMA-BUF layout or extent");
        decoded->uvOffset = size_t(uv);
        decoded->receivedUs = mpp_frame_get_pts(f);
        decoded->release = [owner = shared_from_this(), f]() mutable { mpp_frame_deinit(&f); };
        frame.value = nullptr;
        output(std::move(decoded));
    }
}
void MppDecoder::drain(const Output& output) {
    packet(nullptr, 0, 0, output, true);
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    while (!eos_) {
        poll(output);
        if (std::chrono::steady_clock::now() >= deadline) throw std::runtime_error("MPP EOS timeout");
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
}
}
