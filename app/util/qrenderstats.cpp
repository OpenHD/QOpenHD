#include "qrenderstats.h"

#if defined(__linux__) && !defined(__android__)
#include "videostreaming/avcodec/drm_kms/rk3588_video_link.h"
#endif

#include <qapplication.h>
#include "util/qopenhd.h"
#include <algorithm>
#include <QEvent>

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
    connect(window, &QQuickWindow::beforeRendering, this, &QRenderStats::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRendering, this, &QRenderStats::m_QQuickWindow_afterRendering, Qt::DirectConnection);
    connect(window, &QQuickWindow::beforeRenderPassRecording, this, &QRenderStats::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRenderPassRecording, this, &QRenderStats::m_QQuickWindow_afterRenderPassRecording, Qt::DirectConnection);
#if defined(__linux__) && !defined(__android__)
    Rk3588VideoLink::instance().ensure_started();
    set_external_video_fps_str("0 fps");
    if (!m_present_timer) {
        m_present_timer = new QTimer(this);
        m_present_timer->setTimerType(Qt::PreciseTimer);
        m_present_timer->setInterval(250);
        connect(m_present_timer, &QTimer::timeout, this, [this]() {
            const auto now = std::chrono::steady_clock::now();
            const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - m_last_external_ts);
            if (elapsed.count() <= 0) {
                return;
            }
            const uint64_t total = Rk3588VideoLink::instance().get_received_frames();
            const uint64_t delta = total - m_last_external_frames;
            const double fps = (static_cast<double>(delta) * 1000.0) / static_cast<double>(elapsed.count());
            m_last_external_frames = total;
            m_last_external_ts = now;
            set_external_video_fps_str(QString("%1 fps").arg(fps, 0, 'f', 0));
        });
        m_present_timer->start();
    }

    m_ui_fps_cap = QOpenHD::instance().get_ui_fps_cap();
    if (m_ui_fps_cap > 0) {
        window->installEventFilter(this);
        window->setPersistentSceneGraph(true);
        window->setClearBeforeRendering(false);
        window->setColor(Qt::transparent);
    }
#endif
}

bool QRenderStats::eventFilter(QObject* watched, QEvent* event)
{
    if (m_ui_fps_cap > 0 && event->type() == QEvent::UpdateRequest) {
        const auto now = std::chrono::steady_clock::now();
        const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - m_last_ui_update);
        const int min_interval_ms = std::max(1, 1000 / m_ui_fps_cap);
        if (elapsed.count() < min_interval_ms) {
            return true;
        }
        m_last_ui_update = now;
    }
    return QObject::eventFilter(watched, event);
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
    const auto delta = std::chrono::steady_clock::now() - last_frame_before;
    last_frame_before = std::chrono::steady_clock::now();
    avgMainRenderFrameDeltaBefore.add(delta);
    avgMainRenderFrameDeltaBefore.recalculate_in_fixed_time_intervals(std::chrono::seconds(1),[this](const AvgCalculator& self){
        const auto main_stats=QString(self.getAvgReadable().c_str());
        set_main_render_stats(main_stats);
        const auto avg_ns = self.getAvg().count();
        if (avg_ns > 0) {
            const double fps = 1000000000.0 / static_cast<double>(avg_ns);
            set_screen_fps_str(QString("%1 fps").arg(fps, 0, 'f', 0));
        }
    });
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
    m_seen_render_pass = true;
    m_avg_renderpass_time.start();
    // Calculate frame time by calculating the delta between calls to render pass recording
    const auto delta=std::chrono::steady_clock::now()-last_frame;
    last_frame=std::chrono::steady_clock::now();
    //const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
    //const float frame_time_ms=((float)frame_time_us)/1000.0f;
    //qDebug()<<"QRenderStats main frame time:"<<frame_time_ms<<"ms";
    avgMainRenderFrameDelta.add(delta);
    avgMainRenderFrameDelta.recalculate_in_fixed_time_intervals(std::chrono::seconds(1),[this](const AvgCalculator& self){
        const auto main_stats=QString(self.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_main_render_stats(main_stats);
        const auto avg_ns = self.getAvg().count();
        if (avg_ns > 0) {
            const double fps = 1000000000.0 / static_cast<double>(avg_ns);
            set_screen_fps_str(QString("%1 fps").arg(fps, 0, 'f', 0));
        }
    });
}

void QRenderStats::m_QQuickWindow_afterRenderPassRecording()
{
    m_avg_renderpass_time.stop();
    m_avg_renderpass_time.recalculate_in_fixed_time_intervals(std::chrono::seconds(1),[this](const AvgCalculator& self){
        const auto stats=QString(self.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_qt_renderpass_time(stats);
    });
}
