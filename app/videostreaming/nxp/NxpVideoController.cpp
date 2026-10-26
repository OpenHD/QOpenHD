#include "NxpVideoController.hpp"
#include "videostreaming/vscommon/QOpenHDVideoHelper.hpp"
#include "videostreaming/vscommon/decodingstatistcs.h"
#include <QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#include <QDebug>
#include <QPlatformSurfaceEvent>
#include <QThread>
#include <wayland-client.h>

NxpVideoController::NxpVideoController(QQuickWindow* window) : window_(window) {
    window->installEventFilter(this);
    timer_.setInterval(1000);
    connect(&timer_, &QTimer::timeout, this, [this] { refresh(); });
    // Stop the native child before Qt destroys its parent surface.
    connect(window, &QObject::destroyed, this, [this] { timer_.stop(); input_.reset(); presenter_.reset(); });
    timer_.start(); refresh();
    // Opt-in hardware regression: prove video presentation survives a blocked
    // GUI thread. This is never enabled by a product setting or UI action.
    const int blockMs = qEnvironmentVariableIntValue("QOPENHD_NXP_TEST_BLOCK_GUI_MS");
    if (blockMs > 0 && blockMs <= 10000) QTimer::singleShot(4000, this, [this, blockMs] {
        if (!presenter_) return;
        const auto before = presenter_->presented.load();
        qWarning() << "NXP test: blocking GUI for" << blockMs << "ms";
        QThread::msleep(blockMs);
        qWarning() << "NXP test: video presentations while GUI blocked:" << (presenter_->presented.load() - before);
    });
}
NxpVideoController::~NxpVideoController() { input_.reset(); presenter_.reset(); }
bool NxpVideoController::eventFilter(QObject* object, QEvent* event) {
    if (object == window_ && event->type() == QEvent::PlatformSurface &&
        static_cast<QPlatformSurfaceEvent*>(event)->surfaceEventType() == QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed) {
        input_.reset(); presenter_.reset(); config_.clear(); parentUpdateRequested_ = false;
    }
    return QObject::eventFilter(object, event);
}
void NxpVideoController::refresh() {
    if (!window_) return;
    if (!presenter_) {
        if (!QGuiApplication::platformName().startsWith("wayland")) {
            qWarning() << "NXP video requires the Qt Wayland platform; no software decoder fallback";
            timer_.stop(); return;
        }
        auto native = QGuiApplication::platformNativeInterface();
        auto display = static_cast<wl_display*>(native->nativeResourceForIntegration("wl_display"));
        auto surface = static_cast<wl_surface*>(native->nativeResourceForWindow("surface", window_));
        if (!display || !surface) return; // Window has not been exposed yet.
        presenter_ = std::make_unique<nxp::WaylandVideo>(display, surface);
    }
    auto settings = QOpenHDVideoHelper::read_config_from_settings();
    if (presenter_->state < 0) {
        input_.reset();
        DecodingStatistcs::instance().set_decoding_type("NXP presentation unavailable: check compositor log");
        return;
    }
    if (presenter_->state == 0) return;
    if (!parentUpdateRequested_ && presenter_->committed.load() > 0) {
        // Subsurface stacking/position is applied by a parent wl_surface commit,
        // even for a desynchronized child. QQuickWindow::update() may be elided
        // when the static HUD has no scene-graph damage, leaving video unmapped.
        // This timer runs on Qt's GUI thread, alongside its Wayland surface use.
        auto native = QGuiApplication::platformNativeInterface();
        auto surface = static_cast<wl_surface*>(native->nativeResourceForWindow("surface", window_));
        if (!surface) return;
        wl_surface_commit(surface);
        wl_display_flush(static_cast<wl_display*>(native->nativeResourceForIntegration("wl_display")));
        window_->update(); parentUpdateRequested_ = true;
    }
    if (input_) {
        DecodingStatistcs::instance().set_n_decoder_dropped_frames(int(input_->dropped.load()));
        DecodingStatistcs::instance().set_n_rendered_frames(presenter_->hasPresentationFeedback ? int(presenter_->presented.load()) : -1);
        DecodingStatistcs::instance().set_n_renderer_dropped_frames(int(presenter_->replaced.load()));
        if (qEnvironmentVariableIntValue("QOPENHD_NXP_VIDEO_STATS")) {
            const auto shown = presenter_->presented.load();
            qWarning() << "NXP stats: decoded" << input_->decoded.load() << "input-dropped" << input_->dropped.load()
                       << "errors" << input_->errors.load() << "submitted" << presenter_->committed.load()
                       << "presented" << shown << "superseded" << presenter_->replaced.load()
                       << "compositor-discarded" << presenter_->discarded.load()
                       << "mean-complete-AU-to-feedback-us" << (shown ? presenter_->totalPresentUs.load()/shown : 0)
                       << "max-us" << presenter_->maxPresentUs.load();
        }
    }
    auto stream = settings.generic.qopenhd_switch_primary_secondary ? settings.secondary_stream_config : settings.primary_stream_config;
    QString config = QString("%1:%2:%3:%4").arg(QString::fromStdString(stream.udp_rtp_input_ip_address))
        .arg(stream.udp_rtp_input_port).arg(int(stream.video_codec)).arg(settings.generic.dev_disable_primary_video);
    presenter_->resize(window_->width(), window_->height(), QOpenHDVideoHelper::get_primary_video_scale_to_fit(),
                       settings.generic.extra_screen_rotation);
    if (config == config_) return;
    input_.reset();
    if (settings.generic.dev_disable_primary_video) { config_ = config; return; }
    if (stream.video_codec != QOpenHDVideoHelper::VideoCodecH264 && stream.video_codec != QOpenHDVideoHelper::VideoCodecH265) {
        qWarning() << "NXP native video supports H.264 and H.265"; config_ = config; return;
    }
    try {
        input_ = std::make_unique<nxp::UdpVideo>(stream.video_codec == QOpenHDVideoHelper::VideoCodecH265,
            stream.udp_rtp_input_ip_address, stream.udp_rtp_input_port,
            [this](std::shared_ptr<nxp::DecodedFrame> frame) { presenter_->submit(std::move(frame)); });
        DecodingStatistcs::instance().set_decoding_type("NXP Hantro / independent Wayland DMA-BUF");
        config_ = config;
        qWarning() << "NXP native video listening" << config;
    } catch (const std::exception& error) { qWarning() << "NXP video:" << error.what(); }
}
