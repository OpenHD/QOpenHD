#ifndef QANDROIDSECONDARYMEDIAPLAYER_H
#define QANDROIDSECONDARYMEDIAPLAYER_H

#include <QObject>
#include <QPointer>

#include <memory>
#include <optional>

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
    void attachSurfaceAndStart();
    void stopAndCleanup();
    std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> resolveStreamConfig() const;

    QPointer<QSurfaceTexture> m_videoOut;
    bool m_secondaryVideoEnabled = true;
    bool m_playbackActive = false;
    std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> m_streamConfig;
    std::unique_ptr<LowLagDecoder> m_lowLagDecoder;
    std::unique_ptr<GstRtpReceiver> m_receiver;
};

#endif // QANDROIDSECONDARYMEDIAPLAYER_H
