#include "UdpVideo.hpp"
#include "RtpAccessUnit.hpp"
#include "VpuApi.hpp"
#include <arpa/inet.h>
#include <sys/socket.h>
#include <poll.h>
#include <unistd.h>
#include <array>
#include <chrono>
#include <cstdio>
#include <stdexcept>

namespace nxp {
uint64_t monotonicUs() {
    return std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}
UdpVideo::UdpVideo(bool hevc, const std::string& bindAddress, int port, Output output)
    : hevc_(hevc), output_(std::move(output)) {
    // Resolve the vendor dependency tree before accepting packets, so loader
    // startup cannot turn the first keyframe into an input-queue overrun.
    (void)vpu();
    socket_ = ::socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (socket_ < 0) throw std::runtime_error("NXP UDP socket failed");
    sockaddr_in addr{}; addr.sin_family = AF_INET; addr.sin_port = htons(port);
    int size = 256 * 1024;
    setsockopt(socket_, SOL_SOCKET, SO_RCVBUF, &size, sizeof(size));
    if (port < 1 || port > 65535 || inet_pton(AF_INET, bindAddress.c_str(), &addr.sin_addr) != 1 ||
        ::bind(socket_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        ::close(socket_); socket_ = -1;
        throw std::runtime_error("NXP UDP bind failed (address or port already in use)");
    }
    try {
        decodeThread_ = std::thread([this] { decode(); });
        rxThread_ = std::thread([this, hevc] { receive(hevc); });
    } catch (...) {
        stop_ = true; ready_.notify_all();
        if (decodeThread_.joinable()) decodeThread_.join();
        ::close(socket_); throw;
    }
}
UdpVideo::~UdpVideo() {
    stop_ = true; ready_.notify_all();
    if (rxThread_.joinable()) rxThread_.join();
    if (decodeThread_.joinable()) decodeThread_.join();
    ::close(socket_);
}
void UdpVideo::receive(bool hevc) {
    std::array<std::vector<uint8_t>, 3> config;
    RtpAccessUnit parser(hevc, [&](std::vector<uint8_t> data, bool key) {
        bool picture = false, parametersChanged = false;
        // Keep the latest parameter sets for decoder restarts after loss/overload.
        for (size_t pos = 0; pos + 4 < data.size();) {
            size_t end = pos + 4;
            while (end + 3 < data.size() && !(data[end] == 0 && data[end+1] == 0 && data[end+2] == 0 && data[end+3] == 1)) ++end;
            if (end + 3 >= data.size()) end = data.size();
            unsigned type = hevc ? (data[pos+4] >> 1) & 63 : data[pos+4] & 31;
            picture |= hevc ? type < 32 : (type == 1 || type == 5);
            int slot = hevc ? int(type) - 32 : (type == 7 ? 0 : (type == 8 ? 1 : -1));
            if (slot >= 0 && slot < (hevc ? 3 : 2)) {
                std::vector<uint8_t> updated(data.begin()+pos, data.begin()+end);
                parametersChanged |= !config[slot].empty() && config[slot] != updated;
                config[slot] = std::move(updated);
            }
            pos = end;
        }
        if (parametersChanged) {
            std::lock_guard<std::mutex> lock(mutex_);
            dropped += queue_.size(); queue_.clear(); discontinuity_ = true;
        }
        if (!picture) return;
        if (key) {
            std::vector<uint8_t> withConfig;
            for (const auto& part : config) withConfig.insert(withConfig.end(), part.begin(), part.end());
            withConfig.insert(withConfig.end(), data.begin(), data.end()); data = std::move(withConfig);
        }
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.size() >= 2) {
            dropped += queue_.size(); queue_.clear(); discontinuity_ = true;
        }
        if (discontinuity_ && !key) { ++dropped; return; }
        queue_.push_back({std::move(data), key, discontinuity_, monotonicUs()});
        if (key) discontinuity_ = false;
        ready_.notify_one();
    });
    std::array<uint8_t, 65536> packet;
    while (!stop_) {
        pollfd pfd{socket_, POLLIN, 0};
        if (::poll(&pfd, 1, 100) <= 0) continue;
        auto size = ::recv(socket_, packet.data(), packet.size(), 0);
        if (size > 0) parser.push(packet.data(), size_t(size));
    }
}
void UdpVideo::decode() {
    std::shared_ptr<HantroDecoder> decoder;
    while (!stop_) {
        Input input;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            ready_.wait(lock, [&] { return stop_ || !queue_.empty(); });
            if (stop_) return;
            input = std::move(queue_.front()); queue_.pop_front();
        }
        try {
            if (input.reset) decoder.reset();
            if (!decoder && input.key) decoder = std::make_shared<HantroDecoder>(hevc_);
            if (!decoder) continue;
            decoder->push(input.data, input.receivedUs, [this](std::shared_ptr<DecodedFrame> frame) {
                ++decoded; output_(std::move(frame));
            });
        } catch (const std::exception& error) {
            ++errors; std::fprintf(stderr, "NXP decode: %s\n", error.what());
            decoder.reset();
            std::lock_guard<std::mutex> lock(mutex_);
            queue_.clear(); discontinuity_ = true;
        }
    }
}
}
