#pragma once
#include "../nxp/DecodedFrame.hpp"
#include <rk_mpi.h>
#include <functional>
#include <memory>
#include <vector>

namespace nxp {
// MPP is asynchronous. poll() is called even when no new AU arrives, and
// while input is backpressured, so output/pool provisioning never waits on RX.
class MppDecoder : public std::enable_shared_from_this<MppDecoder> {
public:
    using Output = std::function<void(std::shared_ptr<DecodedFrame>)>;
    explicit MppDecoder(bool hevc, bool reorder = false);
    ~MppDecoder();
    void push(std::vector<uint8_t>& bytes, uint64_t receivedUs, const Output& output);
    void poll(const Output& output);
    void drain(const Output& output);
private:
    void packet(const uint8_t* data, size_t size, uint64_t pts, const Output& output, bool eos = false);
    MppCtx ctx_ = nullptr;
    MppApi* api_ = nullptr;
    MppBufferGroup group_ = nullptr;
    bool hevc_, reorder_, eos_ = false;
};
}
