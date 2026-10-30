#pragma once
#include "../nxp/DecodedFrame.hpp"
#include <memory>
#include <vector>

struct AVCodecContext;
struct AVFrame;
struct SwsContext;
namespace nxp {
// Pi 5 H.264 uses FFmpeg, then linear NV12 DMA-BUFs for the shared
// independent Wayland presenter and secondary EGL scene-graph item.
class PiDecoder {
public:
    explicit PiDecoder(bool hevc, bool reorder = false);
    ~PiDecoder();
    using Output = std::function<void(std::shared_ptr<DecodedFrame>)>;
    void push(std::vector<uint8_t>& bytes, uint64_t receivedUs, const Output& output);
    void drain(const Output& output);
private:
    void receive(const Output& output);
    AVCodecContext* codec_ = nullptr;
    AVFrame* frame_ = nullptr;
    SwsContext* conversion_ = nullptr;
    int heap_ = -1;
};
}
