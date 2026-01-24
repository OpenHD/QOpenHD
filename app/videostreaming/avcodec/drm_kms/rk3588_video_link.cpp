#include "rk3588_video_link.h"

#if defined(__linux__)

#include <errno.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#include <cstring>
#include <iostream>

#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>
#include <drm/drm_mode.h>

#include <QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#include <QScreen>

#include "util/qrenderstats.h"

namespace {
constexpr const char* kSocketPath = "/tmp/fpvue_link";
constexpr uint32_t kMagic = 0x46505645; // "FPVE"
constexpr uint16_t kVersion = 1;

struct DmabufFrameInfo {
    uint32_t magic;
    uint16_t version;
    uint16_t header_size;
    uint32_t width;
    uint32_t height;
    uint32_t fourcc;
    uint32_t num_planes;
    uint32_t fd_count;
    uint32_t strides[4];
    uint32_t offsets[4];
    uint64_t modifiers[4];
    uint64_t pts_ms;
};

} // namespace

Rk3588VideoLink& Rk3588VideoLink::instance() {
    static Rk3588VideoLink instance{};
    return instance;
}

Rk3588VideoLink::~Rk3588VideoLink() {
    shutdown_requested = true;
    if (recv_thread.joinable()) {
        recv_thread.join();
    }
    cleanup_cache();
    if (drm_fd >= 0 && owns_fd) {
        close(drm_fd);
        drm_fd = -1;
    }
}

size_t Rk3588VideoLink::CacheKeyHash::operator()(const CacheKey& key) const noexcept {
    size_t h = std::hash<uint64_t>{}(key.inode);
    h ^= std::hash<uint32_t>{}(key.width) + 0x9e3779b9 + (h << 6) + (h >> 2);
    h ^= std::hash<uint32_t>{}(key.height) + 0x9e3779b9 + (h << 6) + (h >> 2);
    h ^= std::hash<uint32_t>{}(key.fourcc) + 0x9e3779b9 + (h << 6) + (h >> 2);
    h ^= std::hash<uint32_t>{}(key.num_planes) + 0x9e3779b9 + (h << 6) + (h >> 2);
    for (int i = 0; i < 4; ++i) {
        h ^= std::hash<uint32_t>{}(key.strides[i]) + 0x9e3779b9 + (h << 6) + (h >> 2);
        h ^= std::hash<uint32_t>{}(key.offsets[i]) + 0x9e3779b9 + (h << 6) + (h >> 2);
        h ^= std::hash<uint64_t>{}(key.modifiers[i]) + 0x9e3779b9 + (h << 6) + (h >> 2);
    }
    return h;
}

bool Rk3588VideoLink::CacheKeyEq::operator()(const CacheKey& a, const CacheKey& b) const noexcept {
    if (a.inode != b.inode || a.width != b.width || a.height != b.height || a.fourcc != b.fourcc ||
        a.num_planes != b.num_planes) {
        return false;
    }
    for (int i = 0; i < 4; ++i) {
        if (a.strides[i] != b.strides[i] || a.offsets[i] != b.offsets[i] || a.modifiers[i] != b.modifiers[i]) {
            return false;
        }
    }
    return true;
}

void Rk3588VideoLink::ensure_started() {
    bool expected = false;
    if (!started.compare_exchange_strong(expected, true)) {
        return;
    }
    if (!init_drm()) {
        return;
    }
    fps_last_time = std::chrono::steady_clock::now();
    fps_last_count = 0;
    recv_thread = std::thread(&Rk3588VideoLink::receiver_thread, this);
}

bool Rk3588VideoLink::init_drm() {
    owns_fd = true;
    if (QGuiApplication::platformName().contains("eglfs", Qt::CaseInsensitive)) {
        auto* pni = QGuiApplication::platformNativeInterface();
        if (pni) {
            void* fd_ptr = pni->nativeResourceForIntegration("dri_fd");
            if (fd_ptr) {
                drm_fd = static_cast<int>(reinterpret_cast<qintptr>(fd_ptr));
                owns_fd = false;
                QScreen* screen = QGuiApplication::primaryScreen();
                if (screen) {
                    void* crtc_ptr = pni->nativeResourceForScreen("dri_crtcid", screen);
                    void* conn_ptr = pni->nativeResourceForScreen("dri_connectorid", screen);
                    if (crtc_ptr) {
                        crtc_id = static_cast<uint32_t>(reinterpret_cast<qintptr>(crtc_ptr));
                    }
                    if (conn_ptr) {
                        connector_id = static_cast<uint32_t>(reinterpret_cast<qintptr>(conn_ptr));
                    }
                    if (screen) {
                        const auto size = screen->size();
                        display_width = size.width();
                        display_height = size.height();
                    }
                }
                std::cerr << "Rk3588VideoLink: using EGLFS drm fd=" << drm_fd
                          << " is_master=" << drmIsMaster(drm_fd)
                          << " crtc=" << crtc_id << " connector=" << connector_id << "\n";
            }
        }
    }
    if (drm_fd < 0) {
        drm_fd = open("/dev/dri/card0", O_RDWR | O_CLOEXEC);
        if (drm_fd < 0) {
            std::cerr << "Rk3588VideoLink: failed to open /dev/dri/card0: " << strerror(errno) << "\n";
            return false;
        }
    }
    if (drmSetClientCap(drm_fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1) != 0) {
        std::cerr << "Rk3588VideoLink: failed to enable universal planes: " << strerror(errno) << "\n";
    }
    if (drmSetClientCap(drm_fd, DRM_CLIENT_CAP_ATOMIC, 1) != 0) {
        std::cerr << "Rk3588VideoLink: failed to enable atomic: " << strerror(errno) << "\n";
        return false;
    }
    if (crtc_id == 0 || connector_id == 0) {
        if (!find_active_crtc()) {
            std::cerr << "Rk3588VideoLink: failed to find active CRTC\n";
            return false;
        }
    } else {
        drmModeRes* res = drmModeGetResources(drm_fd);
        if (res) {
            for (int c = 0; c < res->count_crtcs; ++c) {
                if (res->crtcs[c] == crtc_id) {
                    crtc_index = c;
                    break;
                }
            }
            drmModeFreeResources(res);
        }
        if (crtc_index < 0) {
            std::cerr << "Rk3588VideoLink: failed to map crtc index for crtc " << crtc_id << "\n";
            return false;
        }
    }
    if (!pick_overlay_plane(DRM_FORMAT_NV12, DRM_FORMAT_MOD_INVALID)) {
        std::cerr << "Rk3588VideoLink: failed to find overlay plane\n";
        return false;
    }
    prop_fb_id = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "FB_ID");
    prop_crtc_id = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_ID");
    prop_src_x = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "SRC_X");
    prop_src_y = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "SRC_Y");
    prop_src_w = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "SRC_W");
    prop_src_h = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "SRC_H");
    prop_crtc_x = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_X");
    prop_crtc_y = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_Y");
    prop_crtc_w = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_W");
    prop_crtc_h = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "CRTC_H");
    prop_zpos = get_prop_id(plane_id, DRM_MODE_OBJECT_PLANE, "zpos");
    if (!prop_fb_id || !prop_crtc_id || !prop_src_w || !prop_src_h || !prop_crtc_w || !prop_crtc_h) {
        std::cerr << "Rk3588VideoLink: missing required plane properties\n";
        return false;
    }
    std::cerr << "Rk3588VideoLink: using connector " << connector_id << " crtc " << crtc_id
              << " plane " << plane_id << " display " << display_width << "x" << display_height << "\n";
    return true;
}

bool Rk3588VideoLink::find_active_crtc() {
    drmModeRes* res = drmModeGetResources(drm_fd);
    if (!res) {
        return false;
    }
    bool found = false;
    for (int i = 0; i < res->count_connectors && !found; ++i) {
        drmModeConnector* conn = drmModeGetConnector(drm_fd, res->connectors[i]);
        if (!conn) {
            continue;
        }
        if (conn->connection != DRM_MODE_CONNECTED || conn->encoder_id == 0) {
            drmModeFreeConnector(conn);
            continue;
        }
        drmModeEncoder* enc = drmModeGetEncoder(drm_fd, conn->encoder_id);
        if (!enc) {
            drmModeFreeConnector(conn);
            continue;
        }
        if (enc->crtc_id) {
            connector_id = conn->connector_id;
            crtc_id = enc->crtc_id;
            for (int c = 0; c < res->count_crtcs; ++c) {
                if (res->crtcs[c] == crtc_id) {
                    crtc_index = c;
                    break;
                }
            }
            drmModeCrtc* crtc = drmModeGetCrtc(drm_fd, crtc_id);
            if (crtc && crtc->mode_valid) {
                display_width = crtc->mode.hdisplay;
                display_height = crtc->mode.vdisplay;
            } else if (conn->count_modes > 0) {
                display_width = conn->modes[0].hdisplay;
                display_height = conn->modes[0].vdisplay;
            }
            if (crtc) {
                drmModeFreeCrtc(crtc);
            }
            found = (crtc_index >= 0);
        }
        drmModeFreeEncoder(enc);
        drmModeFreeConnector(conn);
    }
    drmModeFreeResources(res);
    return found;
}

bool Rk3588VideoLink::pick_overlay_plane(uint32_t fourcc, uint64_t modifier) {
    drmModePlaneRes* planes = drmModeGetPlaneResources(drm_fd);
    if (!planes) {
        return false;
    }
    uint32_t chosen = 0;
    for (uint32_t i = 0; i < planes->count_planes; ++i) {
        drmModePlane* plane = drmModeGetPlane(drm_fd, planes->planes[i]);
        if (!plane) {
            continue;
        }
        if (!(plane->possible_crtcs & (1u << crtc_index))) {
            drmModeFreePlane(plane);
            continue;
        }
        if (!plane_supports_format(plane->plane_id, fourcc, modifier)) {
            drmModeFreePlane(plane);
            continue;
        }
        if (plane->crtc_id == 0) {
            chosen = plane->plane_id;
            drmModeFreePlane(plane);
            break;
        }
        if (!chosen) {
            chosen = plane->plane_id;
        }
        drmModeFreePlane(plane);
    }
    drmModeFreePlaneResources(planes);
    if (!chosen) {
        return false;
    }
    plane_id = chosen;
    return true;
}

bool Rk3588VideoLink::plane_supports_format(uint32_t plane_id, uint32_t fourcc, uint64_t modifier) {
    drmModeObjectProperties* props = drmModeObjectGetProperties(drm_fd, plane_id, DRM_MODE_OBJECT_PLANE);
    if (!props) {
        return false;
    }
    bool supported = false;
    uint64_t blob_id = 0;
    for (uint32_t i = 0; i < props->count_props; ++i) {
        drmModePropertyRes* prop = drmModeGetProperty(drm_fd, props->props[i]);
        if (!prop) {
            continue;
        }
        if (strcmp(prop->name, "IN_FORMATS") == 0) {
            blob_id = props->prop_values[i];
        }
        drmModeFreeProperty(prop);
    }
    if (!blob_id) {
        drmModePlane* plane = drmModeGetPlane(drm_fd, plane_id);
        if (plane) {
            for (uint32_t i = 0; i < plane->count_formats; ++i) {
                if (plane->formats[i] == fourcc) {
                    supported = true;
                    break;
                }
            }
            drmModeFreePlane(plane);
        }
        drmModeFreeObjectProperties(props);
        return supported;
    }
    drmModePropertyBlobRes* blob = drmModeGetPropertyBlob(drm_fd, blob_id);
    if (!blob) {
        drmModeFreeObjectProperties(props);
        return false;
    }
    auto* header = reinterpret_cast<const drm_format_modifier_blob*>(blob->data);
    if (!header) {
        drmModeFreePropertyBlob(blob);
        drmModeFreeObjectProperties(props);
        return false;
    }
    const uint32_t* formats = reinterpret_cast<const uint32_t*>(
        reinterpret_cast<const uint8_t*>(blob->data) + header->formats_offset);
    const drm_format_modifier* mods = reinterpret_cast<const drm_format_modifier*>(
        reinterpret_cast<const uint8_t*>(blob->data) + header->modifiers_offset);
    int format_index = -1;
    for (uint32_t i = 0; i < header->count_formats; ++i) {
        if (formats[i] == fourcc) {
            format_index = static_cast<int>(i);
            break;
        }
    }
    if (format_index >= 0) {
        if (modifier == DRM_FORMAT_MOD_INVALID) {
            supported = true;
        } else {
            for (uint32_t i = 0; i < header->count_modifiers; ++i) {
                const auto& mod = mods[i];
                if (!(mod.formats & (1ull << format_index))) {
                    continue;
                }
                if (mod.modifier == modifier) {
                    supported = true;
                    break;
                }
            }
        }
    }
    drmModeFreePropertyBlob(blob);
    drmModeFreeObjectProperties(props);
    return supported;
}

uint32_t Rk3588VideoLink::get_prop_id(uint32_t obj_id, uint32_t obj_type, const char* name) {
    drmModeObjectProperties* props = drmModeObjectGetProperties(drm_fd, obj_id, obj_type);
    if (!props) {
        return 0;
    }
    uint32_t prop_id = 0;
    for (uint32_t i = 0; i < props->count_props; ++i) {
        drmModePropertyRes* prop = drmModeGetProperty(drm_fd, props->props[i]);
        if (!prop) {
            continue;
        }
        if (strcmp(prop->name, name) == 0) {
            prop_id = prop->prop_id;
            drmModeFreeProperty(prop);
            break;
        }
        drmModeFreeProperty(prop);
    }
    drmModeFreeObjectProperties(props);
    return prop_id;
}

void Rk3588VideoLink::receiver_thread() {
    int sock = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (sock < 0) {
        std::cerr << "Rk3588VideoLink: socket failed: " << strerror(errno) << "\n";
        return;
    }
    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, kSocketPath, sizeof(addr.sun_path) - 1);
    unlink(kSocketPath);
    if (bind(sock, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        std::cerr << "Rk3588VideoLink: bind failed: " << strerror(errno) << "\n";
        close(sock);
        return;
    }
    std::cerr << "Rk3588VideoLink: listening on " << kSocketPath << "\n";
    uint64_t recv_count = 0;
    uint64_t short_count = 0;
    uint64_t bad_magic_count = 0;
    while (!shutdown_requested) {
        DmabufFrameInfo info{};
        char cmsgbuf[CMSG_SPACE(sizeof(int) * 4)];
        iovec iov{};
        iov.iov_base = &info;
        iov.iov_len = sizeof(info);
        msghdr msg{};
        msg.msg_iov = &iov;
        msg.msg_iovlen = 1;
        msg.msg_control = cmsgbuf;
        msg.msg_controllen = sizeof(cmsgbuf);
        const ssize_t ret = recvmsg(sock, &msg, 0);
        if (ret <= 0) {
            continue;
        }
        std::vector<int> fds;
        for (cmsghdr* cmsg = CMSG_FIRSTHDR(&msg); cmsg != nullptr; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
            if (cmsg->cmsg_level == SOL_SOCKET && cmsg->cmsg_type == SCM_RIGHTS) {
                const size_t fd_count = (cmsg->cmsg_len - CMSG_LEN(0)) / sizeof(int);
                const int* fd_data = reinterpret_cast<int*>(CMSG_DATA(cmsg));
                for (size_t i = 0; i < fd_count; ++i) {
                    fds.push_back(fd_data[i]);
                }
            }
        }
        if (static_cast<size_t>(ret) < sizeof(DmabufFrameInfo)) {
            short_count++;
            if (short_count % 120 == 0) {
                std::cerr << "Rk3588VideoLink: short packet size=" << ret << "\n";
            }
            close_fds(fds);
            continue;
        }
        if (info.magic != kMagic || info.version != kVersion) {
            bad_magic_count++;
            if (bad_magic_count % 120 == 0) {
                std::cerr << "Rk3588VideoLink: bad magic/version " << info.magic
                          << " v" << info.version << "\n";
            }
            close_fds(fds);
            continue;
        }
        if (info.fourcc != DRM_FORMAT_NV12) {
            close_fds(fds);
            continue;
        }
        if (info.fd_count < 1 || info.fd_count > 4 || info.num_planes < 1 || info.num_planes > 4) {
            close_fds(fds);
            continue;
        }
        if (fds.empty() || fds.size() < info.fd_count) {
            close_fds(fds);
            continue;
        }
        FrameMeta meta{};
        meta.width = info.width;
        meta.height = info.height;
        meta.fourcc = info.fourcc;
        meta.num_planes = info.num_planes;
        meta.fd_count = info.fd_count;
        meta.pts_ms = info.pts_ms;
        for (int i = 0; i < 4; ++i) {
            meta.strides[i] = info.strides[i];
            meta.offsets[i] = info.offsets[i];
            meta.modifiers[i] = info.modifiers[i];
        }
        uint32_t fb_id = 0;
        if (cache_lookup_or_import(meta, fds, fb_id)) {
            received_frames.fetch_add(1, std::memory_order_relaxed);
            std::lock_guard<std::mutex> lock(pending_mutex);
            pending.fb_id = fb_id;
            pending.meta = meta;
            has_pending = true;
            recv_count++;
            if (recv_count % 120 == 0) {
                std::cerr << "Rk3588VideoLink: received " << recv_count << " frames ("
                          << meta.width << "x" << meta.height << ")\n";
            }
        } else {
            std::cerr << "Rk3588VideoLink: import failed for frame "
                      << meta.width << "x" << meta.height << "\n";
        }
        close_fds(fds);
    }
    close(sock);
    unlink(kSocketPath);
}

bool Rk3588VideoLink::cache_lookup_or_import(const FrameMeta& meta, const std::vector<int>& fds, uint32_t& out_fb_id) {
    if (fds.empty()) {
        return false;
    }
    struct stat st{};
    if (fstat(fds[0], &st) != 0) {
        return false;
    }
    CacheKey key{};
    key.inode = static_cast<uint64_t>(st.st_ino);
    key.width = meta.width;
    key.height = meta.height;
    key.fourcc = meta.fourcc;
    key.num_planes = meta.num_planes;
    for (int i = 0; i < 4; ++i) {
        key.strides[i] = meta.strides[i];
        key.offsets[i] = meta.offsets[i];
        key.modifiers[i] = meta.modifiers[i];
    }
    {
        std::lock_guard<std::mutex> lock(cache_mutex);
        auto it = fb_cache.find(key);
        if (it != fb_cache.end()) {
            out_fb_id = it->second.fb_id;
            return true;
        }
    }
    FbEntry entry{};
    if (!import_dmabuf_to_fb(meta, fds, entry)) {
        return false;
    }
    {
        std::lock_guard<std::mutex> lock(cache_mutex);
        fb_cache.emplace(key, entry);
    }
    out_fb_id = entry.fb_id;
    return true;
}

bool Rk3588VideoLink::import_dmabuf_to_fb(const FrameMeta& meta, const std::vector<int>& fds, FbEntry& out_entry) {
    if (meta.fourcc != DRM_FORMAT_NV12 || meta.num_planes < 2 || fds.empty()) {
        return false;
    }
    uint32_t handles[4]{};
    for (uint32_t i = 0; i < meta.fd_count; ++i) {
        if (drmPrimeFDToHandle(drm_fd, fds[i], &handles[i]) != 0) {
            std::cerr << "Rk3588VideoLink: drmPrimeFDToHandle failed: " << strerror(errno) << "\n";
            return false;
        }
    }
    uint32_t bo_handles[4]{};
    for (uint32_t p = 0; p < meta.num_planes; ++p) {
        const uint32_t obj = (meta.fd_count == 1) ? 0 : p;
        bo_handles[p] = handles[obj];
    }
    uint32_t fb_id = 0;
    if (drmModeAddFB2WithModifiers(drm_fd, meta.width, meta.height, meta.fourcc, bo_handles,
                                   meta.strides, meta.offsets, meta.modifiers, &fb_id,
                                   DRM_MODE_FB_MODIFIERS) != 0) {
        std::cerr << "Rk3588VideoLink: drmModeAddFB2WithModifiers failed: " << strerror(errno) << "\n";
        for (uint32_t i = 0; i < meta.fd_count; ++i) {
            if (handles[i]) {
                drm_gem_close close_req{handles[i]};
                drmIoctl(drm_fd, DRM_IOCTL_GEM_CLOSE, &close_req);
            }
        }
        return false;
    }
    out_entry.fb_id = fb_id;
    out_entry.meta = meta;
    for (uint32_t i = 0; i < 4; ++i) {
        out_entry.bo_handles[i] = bo_handles[i];
    }
    return true;
}

void Rk3588VideoLink::close_fds(const std::vector<int>& fds) {
    for (int fd : fds) {
        if (fd >= 0) {
            close(fd);
        }
    }
}

void Rk3588VideoLink::destroy_fb_entry(FbEntry& entry) {
    if (entry.fb_id) {
        drmModeRmFB(drm_fd, entry.fb_id);
        entry.fb_id = 0;
    }
    for (uint32_t& handle : entry.bo_handles) {
        if (handle) {
            drm_gem_close close_req{handle};
            drmIoctl(drm_fd, DRM_IOCTL_GEM_CLOSE, &close_req);
            handle = 0;
        }
    }
}

void Rk3588VideoLink::cleanup_cache() {
    std::lock_guard<std::mutex> lock(cache_mutex);
    for (auto& kv : fb_cache) {
        destroy_fb_entry(kv.second);
    }
    fb_cache.clear();
}

void Rk3588VideoLink::present_if_pending() {
    if (!started) {
        return;
    }
    auto now = std::chrono::steady_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - fps_last_time);
    if (elapsed.count() >= 1000) {
        const uint64_t total = received_frames.load(std::memory_order_relaxed);
        const uint64_t delta = total - fps_last_count;
        fps_last_count = total;
        fps_last_time = now;
        const QString fps = QString("%1 fps").arg(static_cast<double>(delta));
        QRenderStats::instance().set_external_video_fps_str(fps);
    }
    PendingFrame frame{};
    {
        std::lock_guard<std::mutex> lock(pending_mutex);
        if (!has_pending || pending.fb_id == 0 || pending.fb_id == current_fb_id) {
            return;
        }
        frame = pending;
        has_pending = false;
    }
    drmModeAtomicReq* req = drmModeAtomicAlloc();
    if (!req) {
        return;
    }
    drmModeAtomicAddProperty(req, plane_id, prop_fb_id, frame.fb_id);
    drmModeAtomicAddProperty(req, plane_id, prop_crtc_id, crtc_id);
    drmModeAtomicAddProperty(req, plane_id, prop_crtc_x, 0);
    drmModeAtomicAddProperty(req, plane_id, prop_crtc_y, 0);
    drmModeAtomicAddProperty(req, plane_id, prop_crtc_w, display_width);
    drmModeAtomicAddProperty(req, plane_id, prop_crtc_h, display_height);
    drmModeAtomicAddProperty(req, plane_id, prop_src_x, 0);
    drmModeAtomicAddProperty(req, plane_id, prop_src_y, 0);
    drmModeAtomicAddProperty(req, plane_id, prop_src_w, frame.meta.width << 16);
    drmModeAtomicAddProperty(req, plane_id, prop_src_h, frame.meta.height << 16);
    if (prop_zpos) {
        drmModeAtomicAddProperty(req, plane_id, prop_zpos, 0);
    }
    if (drmModeAtomicCommit(drm_fd, req, DRM_MODE_ATOMIC_NONBLOCK, nullptr) == 0) {
        current_fb_id = frame.fb_id;
    } else {
        std::cerr << "Rk3588VideoLink: atomic commit failed: " << strerror(errno)
                  << " is_master=" << drmIsMaster(drm_fd) << "\n";
    }
    drmModeAtomicFree(req);
}

#endif
