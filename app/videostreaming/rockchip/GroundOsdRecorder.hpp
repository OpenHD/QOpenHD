#pragma once

#include <QElapsedTimer>
#include <QImage>
#include <QObject>
#include <QPointer>
#include <QQuickItemGrabResult>
#include <QTimer>
#include <atomic>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

class QQuickWindow;
class QSocketNotifier;
namespace nxp { struct DecodedFrame; }

class GroundOsdRecorder : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool active READ active NOTIFY stateChanged)
    Q_PROPERTY(bool stopping READ stopping NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)

public:
    GroundOsdRecorder();
    ~GroundOsdRecorder() override;

    bool available() const;
    bool active() const { return active_; }
    bool stopping() const { return stopping_; }
    QString status() const { return status_; }

    void setWindow(QQuickWindow* window);
    void submitVideo(std::shared_ptr<nxp::DecodedFrame> frame);
    void setVideoLayout(bool stretch, int rotation);
    void clearVideo();

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

signals:
    void stateChanged();

private:
    void capture();
    void run(int directoryFd);

    struct Job {
        std::shared_ptr<nxp::DecodedFrame> video;
        QImage hud;
        qint64 pts;
        bool stretch;
        int rotation;
    };

    QPointer<QQuickWindow> window_;
    QSocketNotifier* shutdownNotifier_ = nullptr;
    int shutdownReadFd_ = -1;
    QTimer timer_;
    QElapsedTimer elapsed_;
    QSharedPointer<QQuickItemGrabResult> grab_;
    QSize size_;
    QString status_;
    bool active_ = false, stopping_ = false;
    bool stretch_ = false, captureFailed_ = false;
    int rotation_ = 0;

    std::mutex mutex_;
    std::condition_variable ready_;
    std::shared_ptr<nxp::DecodedFrame> video_;
    std::unique_ptr<Job> job_;
    std::thread worker_;
    std::atomic<bool> collecting_{false};
    bool busy_ = false;
    qint64 videoTime_ = 0;
};
