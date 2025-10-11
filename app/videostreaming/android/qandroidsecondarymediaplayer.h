#ifndef QANDROIDSECONDARYMEDIAPLAYER_H
#define QANDROIDSECONDARYMEDIAPLAYER_H

#include <QAndroidJniObject>
#include <QObject>
#include <QPointer>

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

    Q_INVOKABLE void playDebugLoop();

signals:
    void videoOutChanged();

private:
    void tryStartPlayback();
    void startDebugPlaybackOnAndroidThread();
    void releaseMediaPlayer();

    QPointer<QSurfaceTexture> m_videoOut;
    QAndroidJniObject m_mediaPlayer;
    QAndroidJniObject m_surface;
    bool m_pendingDebugPlayback = false;
};

#endif // QANDROIDSECONDARYMEDIAPLAYER_H
