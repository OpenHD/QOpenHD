#ifndef QANDROIDSECONDARYMEDIAPLAYER_H
#define QANDROIDSECONDARYMEDIAPLAYER_H

#include <QAndroidJniObject>
#include <QObject>
#include <QPointer>

#include <memory>
#include <optional>

#include <QString>

#include "lowlagdecoder.h"
#include "../gstreamer/gstrtpreceiver.h"
#include "../vscommon/QOpenHDVideoHelper.hpp"

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
    void startPlaybackOnAndroidThread(const QAndroidJniObject &surfaceTexture);
    std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> resolveStreamConfig() const;
    void stopPlayback();

    QPointer<QSurfaceTexture> m_videoOut;
    bool m_pendingPlayback = false;
    std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> m_activeConfig;
    std::unique_ptr<LowLagDecoder> m_lowLagDecoder;
    std::unique_ptr<GstRtpReceiver> m_receiver;
};

#endif // QANDROIDSECONDARYMEDIAPLAYER_H
