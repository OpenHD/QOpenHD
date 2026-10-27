#pragma once
#include "DecodedFrame.hpp"
#include <memory>
#include <mutex>
#include <atomic>
#include <thread>

struct wl_display;
struct wl_surface;
namespace nxp {
// Own event queue and presentation thread. Never waits for Qt frameSwapped,
// update(), scenegraph rendering, or a parent wl_surface.commit.
class WaylandVideo {
public:
    WaylandVideo(wl_display* display, wl_surface* parent);
    ~WaylandVideo();
    void submit(std::shared_ptr<DecodedFrame> frame);
    void resize(int width, int height, bool stretch, int rotation);
    std::atomic<uint64_t> committed{0}, replaced{0}, released{0};
    std::atomic<uint64_t> presented{0}, discarded{0}, totalPresentUs{0}, maxPresentUs{0};
    std::atomic<bool> hasPresentationFeedback{false};
    std::atomic<int> state{0}; // 0: connecting, 1: ready, -1: failed
private:
    void run(wl_display* display, wl_surface* parent);
    std::mutex mutex_;
    std::shared_ptr<DecodedFrame> latest_;
    int width_ = 1280, height_ = 720, rotation_ = 0;
    bool stretch_ = false;
    std::atomic<bool> stop_{false};
    int wake_;
    std::thread thread_;
};
}
