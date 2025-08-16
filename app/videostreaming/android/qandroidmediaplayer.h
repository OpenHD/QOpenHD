#ifndef QANDROIDMEDIAPLAYER_H
#define QANDROIDMEDIAPLAYER_H

#include <QObject>
#include <QPointer>
#include <memory>

#include "lowlagdecoder.h"
#include "../gstreamer/gstrtpreceiver.h"

class QSurfaceTexture;

class QAndroidMediaPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSurfaceTexture *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    explicit QAndroidMediaPlayer(QObject *parent = nullptr);
    ~QAndroidMediaPlayer();

    QSurfaceTexture *videoOut() const;
    void setVideoOut(QSurfaceTexture *videoOut);

    void switch_primary_secondary();

signals:
    void videoOutChanged();

private:
    void setup_start_video_decoder_display();
    void stop_cleanup_decoder_display();

private:
    QPointer<QSurfaceTexture> m_videoOut;
    std::unique_ptr<LowLagDecoder> m_low_lag_decoder = nullptr;
    std::unique_ptr<GstRtpReceiver> m_receiver = nullptr;
};

#endif // QANDROIDMEDIAPLAYER_H
