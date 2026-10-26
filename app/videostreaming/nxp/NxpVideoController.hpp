#pragma once
#include "UdpVideo.hpp"
#include "WaylandVideo.hpp"
#include <QObject>
#include <QPointer>
#include <QQuickWindow>
#include <QTimer>

class NxpVideoController : public QObject {
public:
    explicit NxpVideoController(QQuickWindow* window);
    ~NxpVideoController() override;
private:
    bool eventFilter(QObject* object, QEvent* event) override;
    void refresh();
    QPointer<QQuickWindow> window_;
    QTimer timer_;
    std::unique_ptr<nxp::WaylandVideo> presenter_;
    std::unique_ptr<nxp::UdpVideo> input_;
    QString config_;
    bool parentUpdateRequested_ = false;
};
