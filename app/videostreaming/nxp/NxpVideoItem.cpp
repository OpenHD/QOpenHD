#include "NxpVideoItem.hpp"
#include "videostreaming/vscommon/QOpenHDVideoHelper.hpp"
#include "videostreaming/vscommon/decodingstatistcs.h"
#include <QCoreApplication>
#include <QDebug>
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QQuickWindow>
#include <QSGGeometryNode>
#include <QSGMaterial>
#include <QSGMaterialShader>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QSGSimpleTextureNode>
#include <QSGTexture>
#endif
#include <QSettings>
#include <QFile>
#include <QDataStream>
#include <QtQml>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <drm_fourcc.h>
#include <algorithm>
#include <deque>
#include <chrono>
#include <stdexcept>

namespace nxp {
namespace {
constexpr unsigned ExternalTexture = 0x8D65; // GL_TEXTURE_EXTERNAL_OES
struct ImageApi {
    PFNEGLCREATEIMAGEKHRPROC create = reinterpret_cast<PFNEGLCREATEIMAGEKHRPROC>(eglGetProcAddress("eglCreateImageKHR"));
    PFNEGLDESTROYIMAGEKHRPROC destroy = reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>(eglGetProcAddress("eglDestroyImageKHR"));
    using Target = void (*)(unsigned, void*);
    Target target = reinterpret_cast<Target>(eglGetProcAddress("glEGLImageTargetTexture2DOES"));
    PFNEGLCREATESYNCKHRPROC createSync = reinterpret_cast<PFNEGLCREATESYNCKHRPROC>(eglGetProcAddress("eglCreateSyncKHR"));
    PFNEGLDESTROYSYNCKHRPROC destroySync = reinterpret_cast<PFNEGLDESTROYSYNCKHRPROC>(eglGetProcAddress("eglDestroySyncKHR"));
    PFNEGLCLIENTWAITSYNCKHRPROC waitSync = reinterpret_cast<PFNEGLCLIENTWAITSYNCKHRPROC>(eglGetProcAddress("eglClientWaitSyncKHR"));
};
ImageApi& imageApi() { static ImageApi api; return api; }

struct VideoMaterial;
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
class VideoShader : public QSGMaterialShader {
public:
    const char* const* attributeNames() const override {
        static const char* names[] = {"position", "texcoord", nullptr};
        return names;
    }
    const char* vertexShader() const override {
        return "attribute highp vec4 position; attribute highp vec2 texcoord;"
               "uniform highp mat4 qt_Matrix; varying highp vec2 uv;"
               "void main(){ uv=texcoord; gl_Position=qt_Matrix*position; }";
    }
    const char* fragmentShader() const override {
        return "#extension GL_OES_EGL_image_external : require\n"
               "uniform samplerExternalOES video; uniform lowp float qt_Opacity;"
               "varying highp vec2 uv;"
               "void main(){ gl_FragColor=texture2D(video,uv)*qt_Opacity; }";
    }
    void initialize() override {
        matrix_ = program()->uniformLocation("qt_Matrix");
        opacity_ = program()->uniformLocation("qt_Opacity");
        program()->setUniformValue("video", 0);
    }
    void updateState(const RenderState&, QSGMaterial*, QSGMaterial*) override;
private:
    int matrix_ = -1, opacity_ = -1;
};
#endif

struct VideoMaterial : QSGMaterial {
    struct Texture {
        GLuint texture = 0;
        EGLImageKHR image = EGL_NO_IMAGE_KHR;
        EGLDisplay display = EGL_NO_DISPLAY;
        EGLSyncKHR fence = EGL_NO_SYNC_KHR;
        std::shared_ptr<DecodedFrame> frame;
        ~Texture() {
            auto& api = imageApi();
            if (fence != EGL_NO_SYNC_KHR) {
                // Node teardown waits only for this texture's last Qt draw.
                const auto result = api.waitSync(display, fence, EGL_SYNC_FLUSH_COMMANDS_BIT_KHR, EGL_FOREVER_KHR);
                if (result != EGL_CONDITION_SATISFIED_KHR && QOpenGLContext::currentContext())
                    QOpenGLContext::currentContext()->functions()->glFinish();
                api.destroySync(display, fence);
            } else if (frame && QOpenGLContext::currentContext()) {
                QOpenGLContext::currentContext()->functions()->glFinish();
            }
            if (texture && QOpenGLContext::currentContext())
                QOpenGLContext::currentContext()->functions()->glDeleteTextures(1, &texture);
            if (image != EGL_NO_IMAGE_KHR) api.destroy(display, image);
        }
        bool complete() const {
            if (fence == EGL_NO_SYNC_KHR) return false;
            return imageApi().waitSync(display, fence, 0, 0) == EGL_CONDITION_SATISFIED_KHR;
        }
    };
    std::unique_ptr<Texture> current;
    std::deque<std::unique_ptr<Texture>> retired;
    VideoMaterial() { setFlag(Blending); }
    QSGMaterialType* type() const override { static QSGMaterialType type; return &type; }
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QSGMaterialShader* createShader() const override { return new VideoShader; }
#else
    QSGMaterialShader* createShader(QSGRendererInterface::RenderMode) const override { return nullptr; }
#endif
    void afterRendering() {
        if (!current) return;
        auto& api = imageApi();
        if (!api.createSync || !api.destroySync || !api.waitSync) return;
        // Covers all sampling of this VPU frame in the completed Qt render.
        const EGLint attributes[] = { EGL_NONE };
        auto fence = api.createSync(current->display, EGL_SYNC_FENCE_KHR, attributes);
        if (fence == EGL_NO_SYNC_KHR) {
            // An older fence does not cover this render. Complete these reads
            // synchronously before allowing that older fence to retire memory.
            QOpenGLContext::currentContext()->functions()->glFinish();
            if (current->fence != EGL_NO_SYNC_KHR) api.destroySync(current->display, current->fence);
            current->fence = EGL_NO_SYNC_KHR;
            return;
        }
        if (current->fence != EGL_NO_SYNC_KHR) api.destroySync(current->display, current->fence);
        current->fence = fence;
        QOpenGLContext::currentContext()->functions()->glFlush();
    }
    bool import(std::shared_ptr<DecodedFrame> next, bool& updated) {
        updated = false;
        auto& api = imageApi();
        auto context = QOpenGLContext::currentContext();
        if (!context || !api.create || !api.destroy || !api.target) return false;
        while (!retired.empty() && retired.front()->complete()) retired.pop_front();
        // Retain GPU-owned framebuffer leases without growing a display queue.
        // When the GPU is late, keep the last picture and drop this update.
        if (retired.size() >= 2) return true;
        const auto& m = *next;
        const auto fd = next->dmaFd();
        const EGLint attrs[] = {
            EGL_WIDTH, EGLint(m.paddedWidth), EGL_HEIGHT, EGLint(m.paddedHeight),
            EGL_LINUX_DRM_FOURCC_EXT, DRM_FORMAT_NV12,
            EGL_DMA_BUF_PLANE0_FD_EXT, fd, EGL_DMA_BUF_PLANE0_OFFSET_EXT, EGLint(m.yOffset),
            EGL_DMA_BUF_PLANE0_PITCH_EXT, EGLint(m.yStride),
            EGL_DMA_BUF_PLANE1_FD_EXT, fd, EGL_DMA_BUF_PLANE1_OFFSET_EXT, EGLint(m.uvOffset),
            EGL_DMA_BUF_PLANE1_PITCH_EXT, EGLint(m.uvStride), EGL_NONE
        };
        auto dpy = eglGetCurrentDisplay();
        auto imported = api.create(dpy, EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT, nullptr, attrs);
        if (imported == EGL_NO_IMAGE_KHR) return false;
        auto candidate = std::make_unique<Texture>();
        candidate->display = dpy; candidate->image = imported; candidate->frame = std::move(next);
        auto f = context->functions();
        f->glGenTextures(1, &candidate->texture);
        f->glActiveTexture(GL_TEXTURE0);
        f->glBindTexture(ExternalTexture, candidate->texture);
        f->glTexParameteri(ExternalTexture, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        f->glTexParameteri(ExternalTexture, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        f->glTexParameteri(ExternalTexture, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        f->glTexParameteri(ExternalTexture, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        api.target(ExternalTexture, candidate->image);
        if (f->glGetError() != GL_NO_ERROR) return false;
        if (current) {
            if (current->fence != EGL_NO_SYNC_KHR) retired.push_back(std::move(current));
            else current.reset(); // Safe synchronous fallback when fences are unavailable.
        }
        current = std::move(candidate);
        updated = true;
        return true;
    }
};
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
void VideoShader::updateState(const RenderState& state, QSGMaterial* next, QSGMaterial*) {
    auto material = static_cast<VideoMaterial*>(next);
    program()->setUniformValue(matrix_, state.combinedMatrix());
    program()->setUniformValue(opacity_, state.opacity());
    auto f = QOpenGLContext::currentContext()->functions();
    f->glActiveTexture(GL_TEXTURE0);
    f->glBindTexture(ExternalTexture, material->current ? material->current->texture : 0);
}
struct VideoNode : QSGGeometryNode {
    QSGGeometry geometry{QSGGeometry::defaultAttributes_TexturedPoint2D(), 4};
    VideoMaterial material;
    QMetaObject::Connection connection;
    explicit VideoNode(QQuickWindow* window) {
        geometry.setDrawingMode(GL_TRIANGLE_STRIP);
        setGeometry(&geometry); setMaterial(&material);
        connection = QObject::connect(window, &QQuickWindow::afterRendering, window,
            [this] { material.afterRendering(); }, Qt::DirectConnection);
    }
    ~VideoNode() override { QObject::disconnect(connection); }
};
#else
struct VideoNode : QSGSimpleTextureNode {
    VideoMaterial material;
    QMetaObject::Connection connection;
    explicit VideoNode(QQuickWindow* window) {
        setFiltering(QSGTexture::Linear);
        connection = QObject::connect(window, &QQuickWindow::afterRendering, window,
            [this] { material.afterRendering(); }, Qt::DirectConnection);
    }
    ~VideoNode() override { QObject::disconnect(connection); delete texture(); }
    void updateTexture(QQuickWindow* window) {
        auto* previous = texture();
        const auto& current = *material.current;
        setTexture(QNativeInterface::QSGOpenGLTexture::fromNativeExternalOES(
            current.texture, window, QSize(int(current.frame->paddedWidth), int(current.frame->paddedHeight))));
        delete previous;
    }
};
#endif
}

NxpVideoItem::NxpVideoItem(QQuickItem* parent) : QQuickItem(parent) {
    setFlag(ItemHasContents);
    timer_.setInterval(1000);
    connect(&timer_, &QTimer::timeout, this, [this] { refresh(); });
    timer_.start();
}
NxpVideoItem::~NxpVideoItem() {
    setRunning(false);
    timer_.stop(); input_.reset();
    if (!bootAnimation_) DecodingStatistcs::instance().set_secondary_video_active(false);
}
void NxpVideoItem::componentComplete() {
    QQuickItem::componentComplete();
    if (bootAnimation_) { timer_.stop(); startBootAnimation(); }
}
void NxpVideoItem::setRunning(bool running) {
    if (running || !bootAnimation_) return;
    bootStop_ = true; bootWake_.notify_all();
    if (bootThread_.joinable()) bootThread_.join();
}
void NxpVideoItem::submitFrame(std::shared_ptr<DecodedFrame> frame) {
    { std::lock_guard<std::mutex> lock(mutex_);
      if (latest_) ++replaced_;
      latest_ = std::move(frame); }
    if (!updatePending_.exchange(true))
        QMetaObject::invokeMethod(this, [this] {
            updatePending_ = false;
            update();
        }, Qt::QueuedConnection);
}
void NxpVideoItem::startBootAnimation() {
    bootThread_ = std::thread([this] {
        try {
            QFile file(QStringLiteral(":/nxp/boot-video.bin"));
            if (!file.open(QIODevice::ReadOnly) || file.size() > 16 * 1024 * 1024 || file.read(8) != "NXPBOOT1")
                throw std::runtime_error("invalid bundled NXP boot movie");
            QDataStream stream(&file);
            quint32 count = 0; stream >> count;
            if (!count || count > 10000) throw std::runtime_error("invalid boot sample count");
            #if defined(QOPENHD_ENABLE_RPI_VIDEO)
            auto decoder = std::make_shared<PiDecoder>(false, true);
            #elif defined(QOPENHD_ENABLE_ROCKCHIP_VIDEO)
            auto decoder = std::make_shared<MppDecoder>(false, true);
#else
            auto decoder = std::make_shared<HantroDecoder>(false, true);
#endif
            std::chrono::steady_clock::time_point start;
            uint64_t endUs = 0;
            unsigned decoded = 0;
            auto wait = [this, &start](uint64_t timeUs) {
                std::unique_lock<std::mutex> lock(bootMutex_);
                return !bootWake_.wait_until(lock, start + std::chrono::microseconds(timeUs),
                    [this] { return bootStop_.load(); });
            };
            auto output = [&, this](std::shared_ptr<DecodedFrame> frame) {
                if (bootStop_) return;
                if (!decoded++) {
                    start = std::chrono::steady_clock::now();
                    qWarning() << "QOpenHD native boot video: playing (hardware decoder)";
                }
                if (frame->receivedUs > 30000000) throw std::runtime_error("invalid boot picture timestamp");
                if (wait(frame->receivedUs)) submitFrame(std::move(frame));
            };
            for (quint32 sample = 0; sample < count && !bootStop_; ++sample) {
                quint32 size = 0, duration = 0; quint64 pts = 0;
                stream >> size >> pts >> duration;
                if (stream.status() != QDataStream::Ok || !size || size > 4 * 1024 * 1024 ||
                    pts > 30000000 || duration > 1000000 || file.bytesAvailable() < size)
                    throw std::runtime_error("invalid boot sample");
                auto data = file.read(size);
                if (data.size() != int(size)) throw std::runtime_error("truncated boot sample");
                std::vector<uint8_t> bytes(data.begin(), data.end());
                endUs = std::max<uint64_t>(endUs, pts + duration);
                decoder->push(bytes, pts, output);
            }
            if (!bootStop_) decoder->drain(output);
            if (!bootStop_ && (!decoded || decoded != count))
                throw std::runtime_error("boot decoder did not output all pictures");
            if (!bootStop_) wait(endUs);
            qWarning() << "QOpenHD native boot video: decoded" << decoded << "pictures";
        } catch (const std::exception& error) {
            qWarning() << "QOpenHD native boot video unavailable:" << error.what();
        }
        if (!bootStop_) QMetaObject::invokeMethod(this, [this] {
            finished_ = true; emit finishedChanged();
            qWarning() << "QOpenHD native boot video: finished";
        }, Qt::QueuedConnection);
    });
}
void NxpVideoItem::refresh() {
    if (bootAnimation_) return;
    auto settings = QOpenHDVideoHelper::read_config_from_settings();
    const auto stream = settings.generic.qopenhd_switch_primary_secondary ? settings.primary_stream_config : settings.secondary_stream_config;
    const auto config = QString("%1:%2:%3").arg(QString::fromStdString(stream.udp_rtp_input_ip_address))
        .arg(stream.udp_rtp_input_port).arg(int(stream.video_codec));
    if (input_) {
        DecodingStatistcs::instance().set_secondary_video_active(input_->decoded.load() > 0);
        if (qEnvironmentVariableIntValue("QOPENHD_NXP_VIDEO_STATS"))
            qWarning() << "Native secondary stats: decoded" << input_->decoded.load()
                       << "rendered" << rendered_.load() << "superseded" << replaced_.load()
                       << "input-dropped" << input_->dropped.load() << "errors" << input_->errors.load();
    }
    if (config == config_) return;
    input_.reset();
    DecodingStatistcs::instance().set_secondary_video_active(false);
    if (stream.video_codec != QOpenHDVideoHelper::VideoCodecH264 && stream.video_codec != QOpenHDVideoHelper::VideoCodecH265) return;
    try {
        input_ = std::make_unique<UdpVideo>(stream.video_codec == QOpenHDVideoHelper::VideoCodecH265,
            stream.udp_rtp_input_ip_address, stream.udp_rtp_input_port,
            [this](auto frame) { submitFrame(std::move(frame)); });
        config_ = config;
        qWarning() << "Native secondary Hantro/QML listening" << config;
    } catch (const std::exception& error) { qWarning() << "Native secondary:" << error.what(); }
}
QSGNode* NxpVideoItem::updatePaintNode(QSGNode* old, UpdatePaintNodeData*) {
    auto node = static_cast<VideoNode*>(old);
    std::shared_ptr<DecodedFrame> next;
    { std::lock_guard<std::mutex> lock(mutex_); next.swap(latest_); }
    if (!node && !next) return nullptr;
    if (!node) node = new VideoNode(window());
    if (next) {
        bool updated = false;
        if (!node->material.import(std::move(next), updated)) {
            qWarning() << "Native secondary NV12 EGL import failed";
            delete node; return nullptr;
        }
        if (updated) {
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
            node->updateTexture(window());
#endif
            ++rendered_;
        }
        else ++replaced_;
    }
    if (!node->material.current) return node;
    const auto& info = *node->material.current->frame;
    const auto& m = info;
    const auto scale = std::min(width() / info.width, height() / info.height);
    const QRectF rect((width() - info.width * scale)/2, (height() - info.height * scale)/2,
                      info.width * scale, info.height * scale);
    const QRectF source(double(info.cropLeft)/m.paddedWidth, double(info.cropTop)/m.paddedHeight,
                        double(info.width)/m.paddedWidth, double(info.height)/m.paddedHeight);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QSGGeometry::updateTexturedRectGeometry(&node->geometry, rect, source);
#else
    node->setRect(rect);
    node->setSourceRect(QRectF(info.cropLeft, info.cropTop, info.width, info.height));
#endif
    node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    return node;
}
}
static void registerNxpVideoItem() { qmlRegisterType<nxp::NxpVideoItem>("OpenHD", 1, 0, "NxpVideoItem"); }
Q_COREAPP_STARTUP_FUNCTION(registerNxpVideoItem)
