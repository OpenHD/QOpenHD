#ifndef QRENDERSTATS_H
#define QRENDERSTATS_H

#include <QObject>
#include <qqmlapplicationengine.h>
#include <qquickwindow.h>

#include "../common/TimeHelper.hpp"
#include "../lib/lqtutils_master/lqtutils_prop.h"

// Stats about the QT (QOpenHD) OpenGL rendering.
// E.g frame time of the QT OpenGL rendering thread.
class QRenderStats : public QObject
{
    Q_OBJECT
public:
    L_RO_PROP(QString, main_render_stats, set_main_render_stats, "NA")
    // It can be quite nice for debugging to see what resolution QOpenHD's main window is rendered at
    // Resolution of the screen / display itself
    L_RO_PROP(QString, display_width_height_str, set_display_width_height_str, "NA")
    L_RO_PROP(QString, screen_width_height_str, set_screen_width_height_str, "NA")
    // Resolution qopenhd is rendering at
    L_RO_PROP(int, window_width, set_window_width, -1)
    L_RO_PROP(int, window_height, set_window_height, -1)
    // Time QT spent "rendering", probably aka creating the GPU command buffer
    L_RO_PROP(QString, qt_rendering_time, set_qt_rendering_time, "NA")
    // Time QT spent "recording the render pass"
    L_RO_PROP(QString, qt_renderpass_time, set_qt_renderpass_time, "NA")
private:
    explicit QRenderStats(QObject *parent = nullptr);
public:
    // Singleton for the main QML window
    static QRenderStats& instance();
    // Util to register to the root QML window
    void register_to_root_window(QQmlApplicationEngine& engine);
    // Manually regster the QML window
    void registerOnWindow(QQuickWindow* window);
    void set_screen_width_height(int width,int height);
    void set_display_width_height(int width,int height);
public slots:
    void m_QQuickWindow_beforeRendering();
    void m_QQuickWindow_afterRendering();
    void m_QQuickWindow_beforeRenderPassRecording();
    void m_QQuickWindow_afterRenderPassRecording();
private:
    // for the main render thread (render pass recording)
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    AvgCalculator avgMainRenderFrameDelta{};
    // NOTE: For some reason there seems to be no difference between frame time and before / after rendering -
    // looks like there is a glFLush() or somethin in QT.
    //Chronometer m_avg_rendering_time{};
    Chronometer m_avg_renderpass_time{};

};

#endif // QRENDERSTATS_H
