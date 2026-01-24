#ifndef RK3588_VIDEO_LINK_H
#define RK3588_VIDEO_LINK_H

#include <cstdint>

#if defined(__linux__) && defined(IS_PLATFORM_ROCK)
#include <atomic>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <vector>

class Rk3588VideoLink {
public:
    static Rk3588VideoLink& instance();
    void ensure_started();
    void present_if_pending();

private:
    Rk3588VideoLink() = default;
    ~Rk3588VideoLink();
    Rk3588VideoLink(const Rk3588VideoLink&) = delete;
    Rk3588VideoLink& operator=(const Rk3588VideoLink&) = delete;

    struct FrameMeta {
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t fourcc = 0;
        uint32_t num_planes = 0;
        uint32_t fd_count = 0;
        uint32_t strides[4]{};
        uint32_t offsets[4]{};
        uint64_t modifiers[4]{};
        uint64_t pts_ms = 0;
    };

    struct FbEntry {
        uint32_t fb_id = 0;
        uint32_t bo_handles[4]{};
        FrameMeta meta{};
    };

    struct CacheKey {
        uint64_t inode = 0;
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t fourcc = 0;
        uint32_t num_planes = 0;
        uint32_t strides[4]{};
        uint32_t offsets[4]{};
        uint64_t modifiers[4]{};
    };

    struct CacheKeyHash {
        size_t operator()(const CacheKey& key) const noexcept;
    };
    struct CacheKeyEq {
        bool operator()(const CacheKey& a, const CacheKey& b) const noexcept;
    };

    struct PendingFrame {
        uint32_t fb_id = 0;
        FrameMeta meta{};
    };

    void receiver_thread();
    bool init_drm();
    bool find_active_crtc();
    bool pick_overlay_plane(uint32_t fourcc, uint64_t modifier);
    bool plane_supports_format(uint32_t plane_id, uint32_t fourcc, uint64_t modifier);
    bool cache_lookup_or_import(const FrameMeta& meta, const std::vector<int>& fds, uint32_t& out_fb_id);
    bool import_dmabuf_to_fb(const FrameMeta& meta, const std::vector<int>& fds, FbEntry& out_entry);
    void close_fds(const std::vector<int>& fds);
    void destroy_fb_entry(FbEntry& entry);
    void cleanup_cache();
    uint32_t get_prop_id(uint32_t obj_id, uint32_t obj_type, const char* name);

    std::atomic<bool> started{false};
    std::atomic<bool> shutdown_requested{false};
    std::thread recv_thread;

    int drm_fd = -1;
    uint32_t connector_id = 0;
    uint32_t crtc_id = 0;
    int crtc_index = -1;
    uint32_t plane_id = 0;
    uint32_t display_width = 0;
    uint32_t display_height = 0;

    uint32_t prop_fb_id = 0;
    uint32_t prop_crtc_id = 0;
    uint32_t prop_src_x = 0;
    uint32_t prop_src_y = 0;
    uint32_t prop_src_w = 0;
    uint32_t prop_src_h = 0;
    uint32_t prop_crtc_x = 0;
    uint32_t prop_crtc_y = 0;
    uint32_t prop_crtc_w = 0;
    uint32_t prop_crtc_h = 0;
    uint32_t prop_zpos = 0;

    std::mutex pending_mutex;
    PendingFrame pending{};
    bool has_pending = false;
    uint32_t current_fb_id = 0;

    std::mutex cache_mutex;
    std::unordered_map<CacheKey, FbEntry, CacheKeyHash, CacheKeyEq> fb_cache;

    std::atomic<uint64_t> received_frames{0};
    std::chrono::steady_clock::time_point fps_last_time{};
    uint64_t fps_last_count = 0;
};

#else
class Rk3588VideoLink {
public:
    static Rk3588VideoLink& instance() {
        static Rk3588VideoLink instance{};
        return instance;
    }
    void ensure_started() {}
    void present_if_pending() {}
private:
    Rk3588VideoLink() = default;
};
#endif

#endif
