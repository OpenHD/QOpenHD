#include "qrenderstats.h"

#include <qapplication.h>

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
