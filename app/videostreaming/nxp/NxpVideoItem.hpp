#pragma once
#include "UdpVideo.hpp"
#include <QQuickItem>
#include <QTimer>
#include <mutex>
#include <condition_variable>

namespace nxp {
// Secondary video follows the QML scene graph. Primary video stays on its
// independent Wayland surface and never depends on this item's updates.
class NxpVideoItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(bool bootAnimation READ bootAnimation WRITE setBootAnimation)
    Q_PROPERTY(bool running READ running WRITE setRunning)
    Q_PROPERTY(bool finished READ finished NOTIFY finishedChanged)
public:
    explicit NxpVideoItem(QQuickItem* parent = nullptr);
    ~NxpVideoItem() override;
    bool bootAnimation() const { return bootAnimation_; }
    void setBootAnimation(bool enabled) { bootAnimation_ = enabled; }
    bool running() const { return !bootStop_.load(); }
    void setRunning(bool running);
    bool finished() const { return finished_; }
signals:
    void finishedChanged();
protected:
    QSGNode* updatePaintNode(QSGNode*, UpdatePaintNodeData*) override;
    void componentComplete() override;
private:
    void startBootAnimation();
    void submitFrame(std::shared_ptr<DecodedFrame> frame);
    void refresh();
    QTimer timer_;
    std::unique_ptr<UdpVideo> input_;
    QString config_;
    std::mutex mutex_;
    std::shared_ptr<DecodedFrame> latest_;
    std::atomic<uint64_t> rendered_{0}, replaced_{0};
    std::atomic<bool> updatePending_{false};
    bool bootAnimation_ = false, finished_ = false;
    std::atomic<bool> bootStop_{false};
    std::thread bootThread_;
    std::mutex bootMutex_;
    std::condition_variable bootWake_;
};
}
