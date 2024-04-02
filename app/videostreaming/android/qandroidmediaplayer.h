#ifndef QANDROIDMEDIAPLAYER_H
#define QANDROIDMEDIAPLAYER_H

#include <QAndroidJniObject>
#include <QObject>
#include <QPointer>

#include "lowlagdecoder.h"
#include "gstreamer/gstrtpreceiver.h"

class QSurfaceTexture;
class QAndroidMediaPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSurfaceTexture *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    QAndroidMediaPlayer(QObject *parent = nullptr);
    ~QAndroidMediaPlayer();

    QSurfaceTexture *videoOut() const;
    void setVideoOut(QSurfaceTexture *videoOut);

    //Q_INVOKABLE void playFile(const QString &file);
    void switch_primary_secondary();
private:
    void setup_start_video_decoder_display();
    void stop_cleanup_decoder_display();
signals:
    void videoOutChanged();

private:
    QPointer<QSurfaceTexture> m_videoOut;
private:
    std::unique_ptr<LowLagDecoder> m_low_lag_decoder=nullptr;
    std::unique_ptr<GstRtpReceiver> m_receiver=nullptr;
};

#endif // QANDROIDMEDIAPLAYER_H
