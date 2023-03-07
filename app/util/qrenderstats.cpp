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
    connect(window, &QQuickWindow::beforeRenderPassRecording, this, &QRenderStats::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
    connect(window, &QQuickWindow::afterRenderPassRecording, this, &QRenderStats::m_QQuickWindow_afterRenderPassRecording, Qt::DirectConnection);
}

void QRenderStats::set_width_height(int width, int height)
{
    std::stringstream ss;
    ss<<width<<"x"<<height;
    set_window_width_height_str(ss.str().c_str());
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
