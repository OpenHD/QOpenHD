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
    L_RO_PROP(QString, main_render_stats, set_main_render_stats, "NA")
private:
    explicit QRenderStats(QObject *parent = nullptr);
public:
    // Singleton for the main QML window
    static QRenderStats& instance();
    // Util to register to the root QML window
    void register_to_root_window(QQmlApplicationEngine& engine);
    // Manually regster the QML window
    void registerOnWindow(QQuickWindow* window);
public slots:
    void m_QQuickWindow_beforeRendering();
    void m_QQuickWindow_beforeRenderPassRecording();
    void m_QQuickWindow_afterRenderPassRecording();
private:
    // for the main render thread (render pass recording)
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    AvgCalculator avgMainRenderFrameDelta{};
    //
    std::chrono::steady_clock::time_point renderPassBegin;
};

#endif // QRENDERSTATS_H
