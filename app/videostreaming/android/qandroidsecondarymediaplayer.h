#ifndef QANDROIDSECONDARYMEDIAPLAYER_H
#define QANDROIDSECONDARYMEDIAPLAYER_H

#include <QAndroidJniObject>
#include <QObject>
#include <QPointer>

#include "lowlagdecoder.h"
#include "../gstreamer/gstrtpreceiver.h"

class QSurfaceTexture;

class QAndroidSecondaryMediaPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSurfaceTexture *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    explicit QAndroidSecondaryMediaPlayer(QObject *parent = nullptr);
    ~QAndroidSecondaryMediaPlayer() override;

    QSurfaceTexture *videoOut() const;
    void setVideoOut(QSurfaceTexture *videoOut);

signals:
    void videoOutChanged();

private:
    void setup_start_video_decoder_display();
    void stop_cleanup_decoder_display();

    QPointer<QSurfaceTexture> m_videoOut;
    std::unique_ptr<LowLagDecoder> m_low_lag_decoder = nullptr;
    std::unique_ptr<GstRtpReceiver> m_receiver = nullptr;
    bool m_receiver_running = false;
};

#endif // QANDROIDSECONDARYMEDIAPLAYER_H
