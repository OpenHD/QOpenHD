#include "qrenderstats.h"

QRenderStats::QRenderStats(QObject *parent)
    : QObject{parent}
{

}

QRenderStats &QRenderStats::instance()
{
    static QRenderStats instance{};
    return instance;
}

void QRenderStats::registerOnWindow(QQuickWindow *window)
{
    connect(window, &QQuickWindow::beforeRendering, this, &QRenderStats::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
    connect(window, &QQuickWindow::beforeRenderPassRecording, this, &QRenderStats::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRenderPassRecording, this, &QRenderStats::m_QQuickWindow_afterRenderPassRecording, Qt::DirectConnection);
}

void QRenderStats::m_QQuickWindow_beforeRendering()
{

}

void QRenderStats::m_QQuickWindow_beforeRenderPassRecording()
{
    renderPassBegin=std::chrono::steady_clock::now();
    const auto delta=std::chrono::steady_clock::now()-last_frame;
    last_frame=std::chrono::steady_clock::now();
    //const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
    //const float frame_time_ms=((float)frame_time_us)/1000.0f;
    //qDebug()<<"QRenderStats main frame time:"<<frame_time_ms<<"ms";
    avgMainRenderFrameDelta.add(delta);
    if(avgMainRenderFrameDelta.getNSamples()>120){
        const auto main_stats=QString(avgMainRenderFrameDelta.getAvgReadable().c_str());
        //qDebug()<<"QRenderStats main frame time:"<<main_stats;
        set_main_render_stats(main_stats);
        avgMainRenderFrameDelta.reset();
    }
}

void QRenderStats::m_QQuickWindow_afterRenderPassRecording()
{
    const auto render_pass_recording_time=std::chrono::steady_clock::now()-renderPassBegin;
    //qDebug()<<"Render pass recording time:"<<QString(MyTimeHelper::R(render_pass_recording_time).c_str());
}

void QRenderStats::set_main_render_stats(QString main_render_stats)
{
    if(main_render_stats==m_main_render_stats)return;
    m_main_render_stats=main_render_stats;
    emit main_render_stats_changed(m_main_render_stats);
}
