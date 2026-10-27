#pragma once
#ifdef QOPENHD_ENABLE_ROCKCHIP_VIDEO
#include "../rockchip/MppDecoder.hpp"
#else
#include "HantroDecoder.hpp"
#endif
#include <atomic>
#include <condition_variable>
#include <deque>
#include <string>
#include <thread>

namespace nxp {
class UdpVideo {
public:
    using Output = std::function<void(std::shared_ptr<DecodedFrame>)>;
    UdpVideo(bool hevc, const std::string& bindAddress, int port, Output output);
    ~UdpVideo();
    std::atomic<uint64_t> decoded{0}, dropped{0}, errors{0};
private:
    struct Input { std::vector<uint8_t> data; bool key; bool reset; uint64_t receivedUs; };
    void receive(bool hevc);
    void decode();
    int socket_ = -1;
    std::atomic<bool> stop_{false};
    std::mutex mutex_;
    std::condition_variable ready_;
    std::deque<Input> queue_;
    bool discontinuity_ = true;
    bool hevc_;
    Output output_;
    std::thread rxThread_, decodeThread_;
};
uint64_t monotonicUs();
}
