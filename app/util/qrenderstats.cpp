#include "qrenderstats.h"

#include <qapplication.h>
#include <QSettings>

#if defined(__linux__) && !defined(__android__)
#include "videostreaming/avcodec/drm_kms/kms_renderer.h"
#include <QSettings>
#endif

QRenderStats::QRenderStats(QObject *parent)
    : QObject{parent}
{

}

QRenderStats &QRenderStats::instance()
{
    static QRenderStats instance{};
    return instance;
}

void QRenderStats::register_to_root_window(QQmlApplicationEngine& engine)
{
    auto rootObjects = engine.rootObjects();
    if (rootObjects.length() < 1) {
        qWarning(" QRenderStats::register_to_root_window failed,no root objects");
        return;
    }
     QQuickWindow* window = static_cast<QQuickWindow *>(rootObjects.first());
     registerOnWindow(window);
}

void QRenderStats::registerOnWindow(QQuickWindow *window)
{
    QSettings settings;
#if defined(__linux__) && !defined(__android__)
    const bool enable_kms_renderer = settings.value("enable_kms_renderer", false).toBool();
    const bool use_rpi_external = settings.value("dev_rpi_use_external_omx_decode_service", true).toBool();
    const bool use_generic_external = settings.value("dev_always_use_generic_external_decode_service", false).toBool();
    if (enable_kms_renderer && !use_rpi_external && !use_generic_external) {
        KmsRenderer::instance().ensure_started();
    }
#endif
    m_stats_enabled = settings.value("qrenderstats_show", false).toBool();

    if (!m_stats_enabled) {
        return;
    }
    connect(window, &QQuickWindow::beforeRendering, this, &QRenderStats::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRendering, this, &QRenderStats::m_QQuickWindow_afterRendering, Qt::DirectConnection);
    connect(window, &QQuickWindow::beforeRenderPassRecording, this, &QRenderStats::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRenderPassRecording, this, &QRenderStats::m_QQuickWindow_afterRenderPassRecording, Qt::DirectConnection);
}

void QRenderStats::set_screen_width_height(int width, int height)
{
    std::stringstream ss;
    ss<<width<<"x"<<height;
    set_screen_width_height_str(ss.str().c_str());
}

void QRenderStats::set_display_width_height(int width, int height)
{
    std::stringstream ss;
    ss<<width<<"x"<<height;
    set_display_width_height_str(ss.str().c_str());
}

void QRenderStats::m_QQuickWindow_beforeRendering()
{
    //m_avg_rendering_time.start();
}

void QRenderStats::m_QQuickWindow_afterRendering()
{
    /*m_avg_rendering_time.stop();
    if(m_avg_rendering_time.getNSamples()>120){
        const auto stats=QString( m_avg_rendering_time.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_qt_rendering_time(stats);
        m_avg_rendering_time.reset();
    }*/
}

void QRenderStats::m_QQuickWindow_beforeRenderPassRecording()
{
    if (!m_stats_enabled) {
        return;
    }
    const auto now = std::chrono::steady_clock::now();
    if (now - last_stats_update < std::chrono::seconds(1)) {
        return;
    }
    last_stats_update = now;
    m_renderpass_time_active = true;
    m_avg_renderpass_time.start();
    // Calculate frame time by calculating the delta between calls to render pass recording
    const auto delta = now - last_frame;
    last_frame = now;
    //const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
    //const float frame_time_ms=((float)frame_time_us)/1000.0f;
    //qDebug()<<"QRenderStats main frame time:"<<frame_time_ms<<"ms";
    avgMainRenderFrameDelta.add(delta);
    avgMainRenderFrameDelta.recalculate_in_fixed_time_intervals(std::chrono::seconds(1),[this](const AvgCalculator& self){
        const auto main_stats=QString(self.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_main_render_stats(main_stats);
    });
}

void QRenderStats::m_QQuickWindow_afterRenderPassRecording()
{
    if (!m_stats_enabled || !m_renderpass_time_active) {
        return;
    }
    m_renderpass_time_active = false;
    m_avg_renderpass_time.stop();
    m_avg_renderpass_time.recalculate_in_fixed_time_intervals(std::chrono::seconds(1),[this](const AvgCalculator& self){
        const auto stats=QString(self.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_qt_renderpass_time(stats);
    });
}
