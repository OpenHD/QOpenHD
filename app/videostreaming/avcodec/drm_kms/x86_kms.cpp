#include "x86_kms.h"
#ifdef QOPENHD_X86_KMS_AVAILABLE
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQuickWindow>
#include <QDebug>
#include <qpa/qplatformnativeinterface.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>
#include <fcntl.h>
#include <unistd.h>
#include <algorithm>
#include <atomic>
#include <mutex>
#include <vector>
#include "decodingstatistcs.h"
#include "common/TimeHelper.hpp"
extern "C" {
#include <libavutil/frame.h>
#include <libavutil/hwcontext.h>
#include <libavutil/hwcontext_drm.h>
}

namespace {
std::atomic<bool> enabled{false};
std::atomic<bool> disableRequested{false};
std::atomic<int> droppedFrames{0};
int renderedFrames = 0;
std::mutex frameMutex;
AVFrame* pending = nullptr;
uint32_t videoPlane = 0, crtcId = 0;
int screenWidth = 0, screenHeight = 0;
int drmFd = -1; // Borrowed from EGLFS; never opened independently for scanout.

struct Property { uint32_t id = 0; uint64_t value = 0; };
Property property(int fd, uint32_t object, const char* name) {
    Property result;
    auto* properties = drmModeObjectGetProperties(fd, object, DRM_MODE_OBJECT_PLANE);
    if (!properties) return result;
    for (uint32_t i = 0; i < properties->count_props; ++i) {
        auto* p = drmModeGetProperty(fd, properties->props[i]);
        if (p && QByteArray(p->name) == name) result = {p->prop_id, properties->prop_values[i]};
        if (p) drmModeFreeProperty(p);
    }
    drmModeFreeObjectProperties(properties);
    return result;
}
bool hasFormat(const drmModePlane* plane, uint32_t format) {
    return std::find(plane->formats, plane->formats + plane->count_formats, format)
            != plane->formats + plane->count_formats;
}
QJsonObject outputConfig(int fd, const drmModeRes* resources, uint32_t selected, const QByteArray& path, bool alpha = false) {
    QJsonArray outputs;
    for (int o = 0; o < resources->count_connectors; ++o) {
        auto* output = drmModeGetConnector(fd, resources->connectors[o]);
        if (!output) continue;
        QString type = QString::fromLatin1(drmModeGetConnectorTypeName(output->connector_type));
        if (type == "HDMI-A" || type == "HDMI-B") type = "HDMI";
        if (type == "DisplayPort") type = "DP";
        outputs.append(QJsonObject{{"name", type + QString::number(output->connector_type_id)},
            {"mode", output->connector_id == selected ? "preferred" : "off"},
            {"format", alpha ? "argb8888" : "xrgb8888"}});
        drmModeFreeConnector(output);
    }
    return {{"device", QString::fromLocal8Bit(path)}, {"hwcursor", false}, {"outputs", outputs}};
}
bool applyConfig(const QJsonObject& config, const QString& card) {
    QFile file("/run/qopenhd-x86-kms.json");
    if (!file.open(QIODevice::WriteOnly) || file.write(QJsonDocument(config).toJson()) <= 0) return false;
    file.close();
    qputenv("QT_QPA_EGLFS_KMS_CONFIG", file.fileName().toLocal8Bit());
    QDir device("/sys/class/drm/" + card + "/device/drm");
    const auto renders = device.entryList({"renderD*"}, QDir::Dirs);
    if (!renders.isEmpty()) qputenv("QOPENHD_VAAPI_DEVICE", ("/dev/dri/" + renders.first()).toLocal8Bit());
    return true;
}
struct Scanout {
    AVFrame* mapped = nullptr;
    uint32_t framebuffer = 0;
    std::vector<uint32_t> handles;
    void clear() {
        if (framebuffer) drmModeRmFB(drmFd, framebuffer);
        framebuffer = 0;
        for (auto handle : handles) {
            drm_gem_close request{};
            request.handle = handle;
            drmIoctl(drmFd, DRM_IOCTL_GEM_CLOSE, &request);
        }
        handles.clear();
        av_frame_free(&mapped);
    }
};
Scanout current;

bool add(drmModeAtomicReq* request, const char* name, uint64_t value) {
    const auto p = property(drmFd, videoPlane, name);
    return p.id && drmModeAtomicAddProperty(request, videoPlane, p.id, value) >= 0;
}
bool color(drmModeAtomicReq* request, const char* name, const char* match) {
    const auto value = property(drmFd, videoPlane, name);
    if (!value.id) return true;
    auto* p = drmModeGetProperty(drmFd, value.id);
    if (!p) return false;
    bool result = false;
    for (int i = 0; i < p->count_enums; ++i)
        if (QByteArray(p->enums[i].name).contains(match))
            result = drmModeAtomicAddProperty(request, videoPlane, value.id, p->enums[i].value) >= 0;
    drmModeFreeProperty(p);
    return result;
}
void detach() {
    if (drmFd < 0 || !current.framebuffer) return;
    auto* request = drmModeAtomicAlloc();
    if (request && add(request, "FB_ID", 0) && add(request, "CRTC_ID", 0) &&
            drmModeAtomicCommit(drmFd, request, 0, nullptr) == 0) current.clear();
    if (request) drmModeAtomicFree(request);
}
void render() {
    if (disableRequested.exchange(false)) detach();
    AVFrame* frame = nullptr;
    {
        std::lock_guard<std::mutex> lock(frameMutex);
        std::swap(frame, pending);
    }
    if (!frame) return;
    if (drmFd < 0) {
        auto* native = QGuiApplication::platformNativeInterface();
        if (native) {
            auto* fd = native->nativeResourceForIntegration("dri_fd");
            if (fd) drmFd = int(reinterpret_cast<qintptr>(fd));
        }
    }
    Scanout next;
    bool ok = drmFd >= 0 && enabled.load();
    if (ok) {
        next.mapped = av_frame_alloc();
        if (next.mapped) next.mapped->format = AV_PIX_FMT_DRM_PRIME;
        ok = next.mapped && av_hwframe_map(next.mapped, frame,
                AV_HWFRAME_MAP_READ | AV_HWFRAME_MAP_DIRECT) == 0;
    }
    const auto* descriptor = ok
            ? reinterpret_cast<const AVDRMFrameDescriptor*>(next.mapped->data[0]) : nullptr;
    ok = ok && descriptor && descriptor->nb_layers == 1 &&
            descriptor->layers[0].format == DRM_FORMAT_NV12 &&
            descriptor->nb_objects > 0 && descriptor->nb_objects <= 4;
    uint32_t handles[4]{}, strides[4]{}, offsets[4]{};
    uint64_t modifiers[4]{};
    bool linear = true;
    if (ok) {
        for (int i = 0; i < descriptor->nb_objects && ok; ++i) {
            uint32_t handle = 0;
            ok = drmPrimeFDToHandle(drmFd, descriptor->objects[i].fd, &handle) == 0;
            handles[i] = handle;
            if (ok && std::find(next.handles.begin(), next.handles.end(), handle) == next.handles.end())
                next.handles.push_back(handle);
        }
    }
    uint32_t planeHandles[4]{};
    if (ok) {
        const auto& layer = descriptor->layers[0];
        ok = layer.nb_planes == 2;
        for (int i = 0; i < layer.nb_planes && i < 4 && ok; ++i) {
            const auto& p = layer.planes[i];
            ok = p.object_index >= 0 && p.object_index < descriptor->nb_objects;
            if (!ok) break;
            planeHandles[i] = handles[p.object_index];
            strides[i] = p.pitch;
            offsets[i] = p.offset;
            modifiers[i] = descriptor->objects[p.object_index].format_modifier;
            linear = linear && (modifiers[i] == DRM_FORMAT_MOD_LINEAR ||
                                modifiers[i] == DRM_FORMAT_MOD_INVALID);
        }
        if (ok) {
            ok = drmModeAddFB2WithModifiers(drmFd, frame->width, frame->height, DRM_FORMAT_NV12,
                    planeHandles, strides, offsets, modifiers, &next.framebuffer,
                    DRM_MODE_FB_MODIFIERS) == 0;
            if (!ok && linear)
                ok = drmModeAddFB2(drmFd, frame->width, frame->height, DRM_FORMAT_NV12,
                        planeHandles, strides, offsets, &next.framebuffer, 0) == 0;
        }
    }
    if (ok) {
        auto* request = drmModeAtomicAlloc();
        const double scale = std::min(double(screenWidth) / frame->width,
                                      double(screenHeight) / frame->height);
        const int width = int(frame->width * scale) & ~1;
        const int height = int(frame->height * scale) & ~1;
        ok = request && add(request, "FB_ID", next.framebuffer) && add(request, "CRTC_ID", crtcId) &&
                add(request, "SRC_X", 0) && add(request, "SRC_Y", 0) &&
                add(request, "SRC_W", uint64_t(frame->width) << 16) &&
                add(request, "SRC_H", uint64_t(frame->height) << 16) &&
                add(request, "CRTC_X", (screenWidth - width) / 2) &&
                add(request, "CRTC_Y", (screenHeight - height) / 2) &&
                add(request, "CRTC_W", width) && add(request, "CRTC_H", height);
        const char* encoding = frame->colorspace == AVCOL_SPC_BT2020_NCL ? "BT.2020" :
            (frame->colorspace == AVCOL_SPC_BT709 ||
             (frame->colorspace == AVCOL_SPC_UNSPECIFIED && frame->width >= 1280)) ? "BT.709" : "BT.601";
        if (ok) ok = color(request, "COLOR_ENCODING", encoding) &&
                color(request, "COLOR_RANGE", frame->color_range == AVCOL_RANGE_JPEG ? "full" : "limited");
        if (ok) ok = drmModeAtomicCommit(drmFd, request, DRM_MODE_ATOMIC_TEST_ONLY, nullptr) == 0;
        // Blocking commit: current decoder surface must remain retained until the flip completes.
        if (ok) ok = drmModeAtomicCommit(drmFd, request, 0, nullptr) == 0;
        if (request) drmModeAtomicFree(request);
    }
    const auto presentationDelay = getTimeUs() - frame->pts;
    av_frame_free(&frame);
    if (ok) {
        current.clear();
        std::swap(current, next);
        DecodingStatistcs::instance().set_n_rendered_frames(++renderedFrames);
        DecodingStatistcs::instance().set_n_renderer_dropped_frames(droppedFrames.load());
        DecodingStatistcs::instance().set_decode_and_render_time(
                QString::number(presentationDelay / 1000.0, 'f', 1) + " ms");
    } else {
        enabled.store(false);
        qWarning() << "x86 KMS scanout unavailable; using QOpenHD's OpenGL renderer";
        // Remove the last video plane before GL fallback, without touching the HUD plane.
        detach();
    }
    next.clear();
}
}

bool X86Kms::prepare() {
    if (qEnvironmentVariableIsEmpty("QOPENHD_X86_KMS") ||
            qEnvironmentVariable("QT_QPA_PLATFORM") != "eglfs") return false;
    const bool requestVideoPlane = qEnvironmentVariableIntValue("QOPENHD_X86_KMS") == 1;
    // Restrict changes to this explicit appliance mode. Desktop and other boards are untouched.
    QJsonObject fallbackConfig;
    QString fallbackCard;
    int fallbackScore = -1;
    QDir dri("/dev/dri");
    for (const auto& card : dri.entryList({"card*"}, QDir::System | QDir::Files)) {
        const auto path = dri.filePath(card).toLocal8Bit();
        int fd = open(path.constData(), O_RDWR | O_CLOEXEC);
        if (fd < 0) continue;
        auto* driver = drmGetVersion(fd);
        const bool simpleFramebuffer = driver && QByteArray(driver->name, driver->name_len) == "simpledrm";
        if (driver) drmFreeVersion(driver);
        if (simpleFramebuffer) { close(fd); continue; }
        drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
        drmSetClientCap(fd, DRM_CLIENT_CAP_ATOMIC, 1);
        auto* resources = drmModeGetResources(fd);
        auto* planes = drmModeGetPlaneResources(fd);
        // Prefer a tablet/laptop panel, then external outputs.
        for (int pass = 0; resources && planes && pass < 2 && !enabled; ++pass) {
            for (int c = 0; c < resources->count_connectors && !enabled; ++c) {
                auto* connector = drmModeGetConnector(fd, resources->connectors[c]);
                if (!connector) continue;
                const bool internal = connector->connector_type == DRM_MODE_CONNECTOR_eDP ||
                                      connector->connector_type == DRM_MODE_CONNECTOR_LVDS;
                if (connector->connection != DRM_MODE_CONNECTED || !connector->count_modes ||
                        internal != (pass == 0)) {
                    drmModeFreeConnector(connector);
                    continue;
                }
                const int score = internal ? 100 : 1;
                if (score > fallbackScore) {
                    fallbackConfig = outputConfig(fd, resources, connector->connector_id, path);
                    fallbackCard = card;
                    fallbackScore = score;
                }
                uint32_t possibleCrtcs = 0;
                uint32_t activeCrtc = 0;
                for (int e = 0; e < connector->count_encoders; ++e) {
                    auto* encoder = drmModeGetEncoder(fd, connector->encoders[e]);
                    if (encoder) {
                        possibleCrtcs |= encoder->possible_crtcs;
                        if (encoder->encoder_id == connector->encoder_id) activeCrtc = encoder->crtc_id;
                        drmModeFreeEncoder(encoder);
                    }
                }
                // Match Qt's preference for the connector's existing encoder/CRTC route.
                for (int ci = 0; activeCrtc && ci < resources->count_crtcs; ++ci)
                    if (resources->crtcs[ci] == activeCrtc) { possibleCrtcs = 1u << ci; break; }
                for (int ci = 0; requestVideoPlane && ci < resources->count_crtcs && !enabled; ++ci) {
                    if (!(possibleCrtcs & (1u << ci))) continue;
                    for (uint32_t v = 0; v < planes->count_planes && !enabled; ++v) {
                        auto* video = drmModeGetPlane(fd, planes->planes[v]);
                        if (!video) continue;
                        const auto videoZ = property(fd, video->plane_id, "zpos");
                        const bool usable = (video->possible_crtcs & (1u << ci)) &&
                            (!video->crtc_id || video->crtc_id == resources->crtcs[ci]) &&
                            property(fd, video->plane_id, "type").value == DRM_PLANE_TYPE_PRIMARY &&
                            hasFormat(video, DRM_FORMAT_NV12);
                        for (uint32_t h = 0; usable && h < planes->count_planes && !enabled; ++h) {
                            auto* hud = drmModeGetPlane(fd, planes->planes[h]);
                            if (!hud) continue;
                            const auto hudZ = property(fd, hud->plane_id, "zpos");
                            if ((hud->possible_crtcs & (1u << ci)) && !hud->crtc_id &&
                                    hasFormat(hud, DRM_FORMAT_ARGB8888) &&
                                    property(fd, hud->plane_id, "type").value == DRM_PLANE_TYPE_OVERLAY &&
                                    videoZ.id && hudZ.id && hudZ.value > videoZ.value) {
                                crtcId = resources->crtcs[ci];
                                videoPlane = video->plane_id;
                                // Use the preferred mode, falling back to the first advertised mode.
                                int mode = 0;
                                for (int m = 0; m < connector->count_modes; ++m)
                                    if (connector->modes[m].type & DRM_MODE_TYPE_PREFERRED) { mode = m; break; }
                                screenWidth = connector->modes[mode].hdisplay;
                                screenHeight = connector->modes[mode].vdisplay;
                                if (applyConfig(outputConfig(fd, resources, connector->connector_id, path, true), card)) {
                                    qputenv("QT_QPA_EGLFS_KMS_PLANES_FOR_CRTCS",
                                            QByteArray::number(crtcId) + ',' + QByteArray::number(hud->plane_id));
                                    enabled.store(true);
                                    qInfo() << "x86 KMS: video plane" << videoPlane << "HUD plane" << hud->plane_id;
                                }
                            }
                            drmModeFreePlane(hud);
                        }
                        drmModeFreePlane(video);
                    }
                }
                drmModeFreeConnector(connector);
            }
        }
        if (planes) drmModeFreePlaneResources(planes);
        if (resources) drmModeFreeResources(resources);
        close(fd);
        if (enabled) return true;
    }
    // Even GL fallback must select the real GPU when simpledrm occupied card0.
    if (!fallbackConfig.isEmpty()) applyConfig(fallbackConfig, fallbackCard);
    if (requestVideoPlane) qWarning() << "x86 KMS: no suitable video/HUD plane pair; using OpenGL";
    return false;
}

void X86Kms::attach(QQuickWindow* window) {
    if (!enabled || !window) return;
    QObject::connect(window, &QQuickWindow::beforeRendering, window, render, Qt::DirectConnection);
    QObject::connect(window, &QQuickWindow::sceneGraphInvalidated, window, [] {
        enabled.store(false);
        std::lock_guard<std::mutex> lock(frameMutex);
        av_frame_free(&pending);
        // Qt is tearing down its DRM device; detach before releasing scanout surfaces.
        detach();
    }, Qt::DirectConnection);
}

bool X86Kms::enqueue(AVFrame* frame) {
    if (!enabled || frame->format != AV_PIX_FMT_VAAPI) return false;
    auto* retained = av_frame_clone(frame);
    if (!retained) return false;
    std::lock_guard<std::mutex> lock(frameMutex);
    if (pending) ++droppedFrames;
    av_frame_free(&pending);
    pending = retained;
    return true;
}
void X86Kms::disable() {
    enabled.store(false);
    disableRequested.store(true);
}
#endif
