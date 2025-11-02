#ifndef QANDROIDSECONDARYMEDIAPLAYER_H
#define QANDROIDSECONDARYMEDIAPLAYER_H

#include <QObject>
#include <QPointer>

#include <memory>

class QSurfaceTexture;
class GstRtpReceiver;
class LowLagDecoder;

class QAndroidSecondaryMediaPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSurfaceTexture *videoOut READ videoOut WRITE setVideoOut NOTIFY videoOutChanged)

public:
    explicit QAndroidSecondaryMediaPlayer(QObject *parent = nullptr);
    ~QAndroidSecondaryMediaPlayer() override;

    QSurfaceTexture *videoOut() const;
    void setVideoOut(QSurfaceTexture *videoOut);

    Q_INVOKABLE void playDebugLoop();

signals:
    void videoOutChanged();

private:
    void tryStartPlayback();
    void ensureDecoderAndReceiver();
    void attachSurface();
    void startReceiving();
    void stopPlayback();

    QPointer<QSurfaceTexture> m_videoOut;
    std::unique_ptr<LowLagDecoder> m_lowLagDecoder;
    std::unique_ptr<GstRtpReceiver> m_receiver;
    bool m_pendingPlayback = false;
    bool m_streamingActive = false;
};

#endif // QANDROIDSECONDARYMEDIAPLAYER_H
