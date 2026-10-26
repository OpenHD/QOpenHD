#pragma once
#include "UdpVideo.hpp"
#include <QQuickItem>
#include <QTimer>
#include <mutex>

namespace nxp {
// Secondary video follows the QML scene graph. Primary video stays on its
// independent Wayland surface and never depends on this item's updates.
class NxpVideoItem : public QQuickItem {
    Q_OBJECT
public:
    explicit NxpVideoItem(QQuickItem* parent = nullptr);
    ~NxpVideoItem() override;
protected:
    QSGNode* updatePaintNode(QSGNode*, UpdatePaintNodeData*) override;
private:
    void refresh();
    QTimer timer_;
    std::unique_ptr<UdpVideo> input_;
    QString config_;
    std::mutex mutex_;
    std::shared_ptr<DecodedFrame> latest_;
    std::atomic<uint64_t> rendered_{0}, replaced_{0};
    std::atomic<bool> updatePending_{false};
};
}
