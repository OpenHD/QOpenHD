#include "WaylandVideo.hpp"
#include "linux-dmabuf-client-protocol.h"
#include "viewporter-client-protocol.h"
#include "presentation-time-client-protocol.h"
#include "UdpVideo.hpp"
#include <wayland-client.h>
#include <imxdmabuffer/imxdmabuffer.h>
#include <drm_fourcc.h>
#include <sys/eventfd.h>
#include <unistd.h>
#include <poll.h>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <cerrno>

namespace nxp {
namespace {
struct Buffer {
    wl_buffer* proxy = nullptr;
    std::shared_ptr<DecodedFrame> frame;
    bool busy = true;
};
void bufferRelease(void* data, wl_buffer*) {
    auto buffer = static_cast<Buffer*>(data);
    buffer->busy = false; buffer->frame.reset();
}
const wl_buffer_listener bufferListener{bufferRelease};
struct Feedback {
    struct wp_presentation_feedback* proxy = nullptr;
    WaylandVideo* video;
    uint64_t receivedUs;
};
void syncOutput(void*, struct wp_presentation_feedback*, wl_output*) {}
void presented(void* data, struct wp_presentation_feedback* proxy, uint32_t, uint32_t, uint32_t,
               uint32_t, uint32_t, uint32_t, uint32_t) {
    auto& feedback = *static_cast<Feedback*>(data);
    auto elapsed = monotonicUs() - feedback.receivedUs;
    ++feedback.video->presented;
    feedback.video->totalPresentUs += elapsed;
    feedback.video->maxPresentUs = std::max(feedback.video->maxPresentUs.load(), elapsed);
    wp_presentation_feedback_destroy(proxy); feedback.proxy = nullptr;
}
void discarded(void* data, struct wp_presentation_feedback* proxy) {
    auto& feedback = *static_cast<Feedback*>(data);
    ++feedback.video->discarded;
    wp_presentation_feedback_destroy(proxy); feedback.proxy = nullptr;
}
const wp_presentation_feedback_listener feedbackListener{syncOutput, presented, discarded};
void clockId(void*, wp_presentation*, uint32_t) {}
const wp_presentation_listener presentationListener{clockId};
struct Globals {
    wl_compositor* compositor = nullptr;
    wl_subcompositor* subcompositor = nullptr;
    zwp_linux_dmabuf_v1* dmabuf = nullptr;
    wp_viewporter* viewporter = nullptr;
    wp_presentation* presentation = nullptr;
    bool linearNv12 = false;
};
void format(void*, zwp_linux_dmabuf_v1*, uint32_t) {}
void modifier(void* data, zwp_linux_dmabuf_v1*, uint32_t f, uint32_t hi, uint32_t lo) {
    if (f == DRM_FORMAT_NV12 && hi == 0 && lo == 0) static_cast<Globals*>(data)->linearNv12 = true;
}
const zwp_linux_dmabuf_v1_listener dmaListener{format, modifier};
void global(void* data, wl_registry* registry, uint32_t id, const char* name, uint32_t version) {
    auto& g = *static_cast<Globals*>(data);
    if (!std::strcmp(name, "wl_compositor"))
        g.compositor = static_cast<wl_compositor*>(wl_registry_bind(registry, id, &wl_compositor_interface, std::min(version, 4u)));
    else if (!std::strcmp(name, "wl_subcompositor"))
        g.subcompositor = static_cast<wl_subcompositor*>(wl_registry_bind(registry, id, &wl_subcompositor_interface, 1));
    else if (!std::strcmp(name, "wp_viewporter"))
        g.viewporter = static_cast<wp_viewporter*>(wl_registry_bind(registry, id, &wp_viewporter_interface, 1));
    else if (!std::strcmp(name, "wp_presentation")) {
        g.presentation = static_cast<wp_presentation*>(wl_registry_bind(registry, id, &wp_presentation_interface, 1));
        wp_presentation_add_listener(g.presentation, &presentationListener, nullptr);
    }
    else if (!std::strcmp(name, "zwp_linux_dmabuf_v1") && version >= 3) {
        g.dmabuf = static_cast<zwp_linux_dmabuf_v1*>(wl_registry_bind(registry, id, &zwp_linux_dmabuf_v1_interface, 3));
        zwp_linux_dmabuf_v1_add_listener(g.dmabuf, &dmaListener, &g);
    }
}
void removed(void*, wl_registry*, uint32_t) {}
const wl_registry_listener registryListener{global, removed};
}
WaylandVideo::WaylandVideo(wl_display* display, wl_surface* parent) {
    wake_ = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (wake_ < 0) throw std::runtime_error("video eventfd failed");
    try { thread_ = std::thread([=] { run(display, parent); }); }
    catch (...) { close(wake_); throw; }
}
WaylandVideo::~WaylandVideo() {
    stop_ = true; uint64_t one = 1; (void)write(wake_, &one, sizeof(one));
    thread_.join(); close(wake_);
}
void WaylandVideo::resize(int width, int height, bool stretch, int rotation) {
    std::lock_guard<std::mutex> lock(mutex_);
    width_ = width; height_ = height; stretch_ = stretch; rotation_ = rotation;
}
void WaylandVideo::submit(std::shared_ptr<DecodedFrame> frame) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (latest_) ++replaced;
        latest_ = std::move(frame);
    }
    uint64_t one = 1; (void)write(wake_, &one, sizeof(one));
}
void WaylandVideo::run(wl_display* display, wl_surface* parent) {
    Globals g;
    auto queue = wl_display_create_queue(display);
    auto wrapper = static_cast<wl_display*>(wl_proxy_create_wrapper(display));
    wl_proxy_set_queue(reinterpret_cast<wl_proxy*>(wrapper), queue);
    auto registry = wl_display_get_registry(wrapper);
    wl_proxy_wrapper_destroy(wrapper);
    wl_registry_add_listener(registry, &registryListener, &g);
    wl_surface* surface = nullptr; wl_subsurface* sub = nullptr; wp_viewport* viewport = nullptr;
    std::vector<std::unique_ptr<Buffer>> buffers;
    std::vector<std::unique_ptr<Feedback>> feedbacks;
    try {
        if (wl_display_roundtrip_queue(display, queue) < 0 || wl_display_roundtrip_queue(display, queue) < 0)
            throw std::runtime_error("Wayland registry failed");
        if (!g.compositor || !g.subcompositor || !g.dmabuf || !g.viewporter || !g.linearNv12)
            throw std::runtime_error("Wayland requires subcompositor, viewporter, linux-dmabuf v3 and linear NV12");
        surface = wl_compositor_create_surface(g.compositor);
        sub = wl_subcompositor_get_subsurface(g.subcompositor, surface, parent);
        wl_subsurface_place_below(sub, parent);
        wl_subsurface_set_desync(sub);
        viewport = wp_viewporter_get_viewport(g.viewporter, surface);
        auto region = wl_compositor_create_region(g.compositor);
        wl_surface_set_input_region(surface, region); wl_region_destroy(region);
        std::fprintf(stderr, "NXP video: independent desynchronized DMA-BUF subsurface ready\n");
        state = 1;
        hasPresentationFeedback = g.presentation != nullptr;
        while (!stop_) {
            if (wl_display_dispatch_queue_pending(display, queue) < 0) break;
            for (auto i = buffers.begin(); i != buffers.end();) {
                if (!(*i)->busy) { wl_buffer_destroy((*i)->proxy); i = buffers.erase(i); ++released; }
                else ++i;
            }
            feedbacks.erase(std::remove_if(feedbacks.begin(), feedbacks.end(),
                [](const auto& feedback) { return feedback->proxy == nullptr; }), feedbacks.end());
            std::shared_ptr<DecodedFrame> next;
            int width, height, rotation; bool stretch;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (buffers.size() < 2) next.swap(latest_);
                width = width_; height = height_; rotation = rotation_; stretch = stretch_;
            }
            if (next && width > 0 && height > 0) {
                auto& m = next->info.decoded_frame_framebuffer_metrics;
                int fd = next->dmaFd();
                if (fd < 0) throw std::runtime_error("VPU allocator did not export a DMA-BUF fd");
                auto params = zwp_linux_dmabuf_v1_create_params(g.dmabuf);
                zwp_linux_buffer_params_v1_add(params, fd, 0, m.y_offset, m.y_stride, 0, 0);
                zwp_linux_buffer_params_v1_add(params, fd, 1, m.u_offset, m.uv_stride, 0, 0);
                auto buffer = std::make_unique<Buffer>(); buffer->frame = next;
                buffer->proxy = zwp_linux_buffer_params_v1_create_immed(params, m.aligned_frame_width,
                    m.aligned_frame_height, DRM_FORMAT_NV12, 0);
                zwp_linux_buffer_params_v1_destroy(params);
                wl_buffer_add_listener(buffer->proxy, &bufferListener, buffer.get());
                int transform = rotation == 90 ? WL_OUTPUT_TRANSFORM_90 : rotation == 180 ? WL_OUTPUT_TRANSFORM_180 :
                                rotation == 270 ? WL_OUTPUT_TRANSFORM_270 : WL_OUTPUT_TRANSFORM_NORMAL;
                wl_surface_set_buffer_transform(surface, transform);
                // Source coordinates are expressed after buffer transform. Use actual
                // visible size; padding is excluded by the viewport source rectangle.
                double sw = next->info.crop_width, sh = next->info.crop_height;
                double sx = next->info.crop_left, sy = next->info.crop_top;
                if (rotation == 90) { std::swap(sw, sh); std::swap(sx, sy); sy = m.aligned_frame_width - next->info.crop_left - next->info.crop_width; }
                else if (rotation == 180) { sx = m.aligned_frame_width - sx - sw; sy = m.aligned_frame_height - sy - sh; }
                else if (rotation == 270) { std::swap(sw, sh); std::swap(sx, sy); sx = m.aligned_frame_height - next->info.crop_top - next->info.crop_height; }
                wp_viewport_set_source(viewport, wl_fixed_from_double(sx), wl_fixed_from_double(sy),
                                       wl_fixed_from_double(sw), wl_fixed_from_double(sh));
                int dw = width, dh = height;
                if (!stretch) {
                    double scale = std::min(width / sw, height / sh);
                    dw = std::max(1, int(sw * scale)); dh = std::max(1, int(sh * scale));
                }
                wp_viewport_set_destination(viewport, dw, dh);
                wl_subsurface_set_position(sub, (width-dw)/2, (height-dh)/2);
                wl_surface_attach(surface, buffer->proxy, 0, 0);
                wl_surface_damage(surface, 0, 0, dw, dh);
                if (g.presentation && feedbacks.size() < 16) {
                    auto feedback = std::make_unique<Feedback>();
                    feedback->video = this; feedback->receivedUs = next->raw.pts;
                    feedback->proxy = wp_presentation_feedback(g.presentation, surface);
                    wp_presentation_feedback_add_listener(feedback->proxy, &feedbackListener, feedback.get());
                    feedbacks.push_back(std::move(feedback));
                }
                wl_surface_commit(surface);
                buffers.push_back(std::move(buffer)); ++committed;
            }
            // Use libwayland's multi-reader protocol alongside Qt's event reader.
            while (wl_display_prepare_read_queue(display, queue) != 0)
                if (wl_display_dispatch_queue_pending(display, queue) < 0) throw std::runtime_error("Wayland dispatch failed");
            int flushed = wl_display_flush(display);
            if (flushed < 0 && errno != EAGAIN) {
                wl_display_cancel_read(display);
                throw std::runtime_error("Wayland flush failed");
            }
            pollfd fds[] = {{wl_display_get_fd(display), short(POLLIN | (flushed < 0 ? POLLOUT : 0)), 0}, {wake_, POLLIN, 0}};
            int result = poll(fds, 2, 100);
            if (result > 0 && (fds[0].revents & POLLIN)) {
                if (wl_display_read_events(display) < 0) throw std::runtime_error("Wayland read failed");
            } else wl_display_cancel_read(display);
            if (result > 0 && (fds[0].revents & (POLLERR | POLLHUP | POLLNVAL)))
                throw std::runtime_error("Wayland connection closed");
            if (fds[1].revents & POLLIN) { uint64_t value; (void)read(wake_, &value, sizeof(value)); }
        }
    } catch (const std::exception& error) { std::fprintf(stderr, "NXP presentation: %s\n", error.what()); }
    state = -1;
    if (surface) { wl_surface_attach(surface, nullptr, 0, 0); wl_surface_commit(surface); }
    if (viewport) wp_viewport_destroy(viewport);
    if (sub) wl_subsurface_destroy(sub);
    if (surface) wl_surface_destroy(surface);
    for (auto& buffer : buffers) wl_buffer_destroy(buffer->proxy);
    for (auto& feedback : feedbacks) if (feedback->proxy) wp_presentation_feedback_destroy(feedback->proxy);
    if (g.presentation) wp_presentation_destroy(g.presentation);
    if (g.viewporter) wp_viewporter_destroy(g.viewporter);
    if (g.dmabuf) zwp_linux_dmabuf_v1_destroy(g.dmabuf);
    if (g.subcompositor) wl_subcompositor_destroy(g.subcompositor);
    if (g.compositor) wl_compositor_destroy(g.compositor);
    wl_registry_destroy(registry); wl_display_flush(display); wl_event_queue_destroy(queue);
}
}
