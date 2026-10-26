#pragma once
#include <imxvpuapi2/imxvpuapi2.h>
#include <functional>
#include <memory>
#include <mutex>
#include <vector>

namespace nxp {
class HantroDecoder;
struct DecodedFrame {
    std::shared_ptr<HantroDecoder> owner;
    ImxVpuApiRawFrame raw{};
    ImxVpuApiDecStreamInfo info{};
    int dmaFd() const;
    ~DecodedFrame();
};
// Each generation owns its own VPU session and buffers. Displayed frames keep
// that generation alive across resolution/codec changes, including GPU use.
class HantroDecoder : public std::enable_shared_from_this<HantroDecoder> {
public:
    explicit HantroDecoder(bool hevc, bool reorder = false);
    ~HantroDecoder();
    void push(std::vector<uint8_t>& bytes, uint64_t receivedUs,
              const std::function<void(std::shared_ptr<DecodedFrame>)>& output);
    void release(ImxDmaBuffer* buffer);
    void drain(const std::function<void(std::shared_ptr<DecodedFrame>)>& output);
private:
    void readOutput(const std::function<void(std::shared_ptr<DecodedFrame>)>& output, bool draining);
    void addBuffers(size_t count);
    std::mutex mutex_;
    ImxDmaBufferAllocator* allocator_ = nullptr;
    ImxDmaBuffer* stream_ = nullptr;
    ImxVpuApiDecoder* decoder_ = nullptr;
    ImxVpuApiDecStreamInfo info_{};
    std::vector<ImxDmaBuffer*> buffers_;
};
}
