#pragma once
#include "UdpVideo.hpp"
#include "WaylandVideo.hpp"
#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QTimer>

#ifdef QOPENHD_ENABLE_ROCKCHIP_VIDEO
class GroundOsdRecorder;
#endif

class NxpVideoController : public QObject {
public:
#ifdef QOPENHD_ENABLE_ROCKCHIP_VIDEO
    NxpVideoController(QQuickWindow* window, GroundOsdRecorder* recorder);
#else
    explicit NxpVideoController(QQuickWindow* window);
#endif
    ~NxpVideoController() override;
private:
    bool eventFilter(QObject* object, QEvent* event) override;
    void refresh();
    QPointer<QQuickWindow> window_;
    QTimer timer_;
#ifdef QOPENHD_ENABLE_ROCKCHIP_VIDEO
    GroundOsdRecorder* recorder_;
#endif
    std::unique_ptr<nxp::WaylandVideo> presenter_;
    std::unique_ptr<nxp::UdpVideo> input_;
    QString config_;
    bool parentUpdateRequested_ = false;
};
