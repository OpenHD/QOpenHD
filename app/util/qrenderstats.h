#ifndef QRENDERSTATS_H
#define QRENDERSTATS_H

#include <QObject>
#include <qqmlapplicationengine.h>
#include <qquickwindow.h>

#include "../common/TimeHelper.hpp"
#include "../lib/lqtutils_master/lqtutils_prop.h"

// Stats about the QT (QOpenHD) rendering.
// Dirty right now.
class QRenderStats : public QObject
{
    Q_OBJECT
    L_RO_PROP(QString, main_render_stats, set_main_render_stats, "NA")
private:
    explicit QRenderStats(QObject *parent = nullptr);
public:
    // Use singleton
    static QRenderStats& instance();
    void register_to_root_window(QQmlApplicationEngine& engine);
public:
    // We hoock to the window to get the main pass statistics
    void registerOnWindow(QQuickWindow* window);
public slots:
    void m_QQuickWindow_beforeRendering();
    void m_QQuickWindow_beforeRenderPassRecording();
    void m_QQuickWindow_afterRenderPassRecording();
public:
private:
    // for the main render thread (render pass recording)
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    AvgCalculator avgMainRenderFrameDelta{};
    //
    std::chrono::steady_clock::time_point renderPassBegin;
};

#endif // QRENDERSTATS_H
