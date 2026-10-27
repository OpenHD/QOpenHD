#pragma once
#include <cstddef>
#include <cstdint>
#include <functional>

namespace nxp {
// Linear NV12 lease shared by the native decoders and both presenters. The
// release callback retains its original decoder generation until display/GPU
// ownership ends. No vendor frame types escape into the presenter.
struct DecodedFrame {
    int fd = -1;
    size_t width = 0, height = 0;
    size_t paddedWidth = 0, paddedHeight = 0;
    size_t cropLeft = 0, cropTop = 0;
    size_t yOffset = 0, uvOffset = 0, yStride = 0, uvStride = 0;
    uint64_t receivedUs = 0;
    std::function<void()> release;
    DecodedFrame() = default;
    DecodedFrame(const DecodedFrame&) = delete;
    DecodedFrame& operator=(const DecodedFrame&) = delete;
    ~DecodedFrame() { if (release) release(); }
    int dmaFd() const { return fd; }
};
}
