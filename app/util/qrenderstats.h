#ifndef QRENDERSTATS_H
#define QRENDERSTATS_H

#include <QObject>
#include <qquickwindow.h>

#include "../common_consti/TimeHelper.hpp"

// Stats about the QT (QOpenHD) rendering.
// Dirty right now.
class QRenderStats : public QObject
{
    Q_OBJECT
private:
    explicit QRenderStats(QObject *parent = nullptr);
public:
    // Use singleton
    static QRenderStats& instance();
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
public:
    Q_PROPERTY(QString main_render_stats MEMBER m_main_render_stats WRITE set_main_render_stats NOTIFY main_render_stats_changed)
    void set_main_render_stats(QString main_render_stats);
    //
    //Q_PROPERTY(QString decode_time MEMBER m_decode_time WRITE set_decode_time NOTIFY decode_time_changed)
    //void set_main_render_stats(QString main_render_stats);
signals:
    void main_render_stats_changed(QString main_render_stats);
private:
    QString m_main_render_stats="Unknown";
};

#endif // QRENDERSTATS_H
