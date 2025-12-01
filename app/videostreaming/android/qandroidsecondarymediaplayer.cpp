#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QDebug>
#include <QtAndroid>

#include "qsurfacetexture.h"

#include "../vscommon/QOpenHDVideoHelper.hpp"

namespace {
QString buildStreamUrl(const QOpenHDVideoHelper::VideoStreamConfigXX &config)
{
    const QString ip = QString::fromStdString(config.udp_rtp_input_ip_address).trimmed();
    const int port = config.udp_rtp_input_port;

    if (ip.isEmpty())
        return {};

    if (ip == QLatin1String("127.0.0.1") || ip == QLatin1String("0.0.0.0"))
        return QStringLiteral("udp://@:%1").arg(port);

    return QStringLiteral("udp://%1:%2").arg(ip).arg(port);
}

constexpr auto kSecondaryTestClip =
    "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4";
} // namespace

QAndroidSecondaryMediaPlayer::QAndroidSecondaryMediaPlayer(QObject *parent)
    : QObject(parent)
{
}

QAndroidSecondaryMediaPlayer::~QAndroidSecondaryMediaPlayer()
{
    releaseMediaPlayer();
}

QSurfaceTexture *QAndroidSecondaryMediaPlayer::videoOut() const
{
    return m_videoOut;
}

void QAndroidSecondaryMediaPlayer::setVideoOut(QSurfaceTexture *videoOut)
{
    if (m_videoOut == videoOut)
        return;

    if (m_videoOut)
        m_videoOut->disconnect(this);

    m_videoOut = videoOut;

    if (!m_videoOut) {
        releaseMediaPlayer();
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, [this] {
            m_pendingPlayback = true;
            tryStartPlayback();
        });
        m_pendingPlayback = true;
        tryStartPlayback();
    }
    emit videoOutChanged();
}

void QAndroidSecondaryMediaPlayer::playDebugLoop()
{
    m_pendingPlayback = true;
    tryStartPlayback();
}

void QAndroidSecondaryMediaPlayer::tryStartPlayback()
{
    if (!m_pendingPlayback)
        return;

    if (!m_mediaPlayer.isValid()) {
        m_mediaPlayer = QAndroidJniObject("android/media/MediaPlayer");
        if (!m_mediaPlayer.isValid()) {
            qWarning("Failed to create Android MediaPlayer for secondary video");
            QAndroidJniEnvironment env;
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            return;
        }
    }

    if (!m_videoOut)
        return;

    const QAndroidJniObject surfaceTexture = m_videoOut->surfaceTexture();
    if (!surfaceTexture.isValid()) {
        qWarning() << "Secondary Android surface texture is invalid; delaying playback";
        return;
    }

    const QString streamUrl = resolveStreamUrl();
    if (streamUrl.isEmpty()) {
        qWarning() << "Secondary Android stream URL is empty; cannot start playback";
        return;
    }

    qInfo() << "Starting secondary Android playback from" << streamUrl;

    startPlaybackOnAndroidThread(streamUrl, surfaceTexture);
}

QString QAndroidSecondaryMediaPlayer::resolveStreamUrl() const
{
    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto streamConfig = settings.secondary_stream_config;
    switch (settings.generic.dev_secondary_video_input_mode) {
    case 1:
        streamConfig = settings.primary_stream_config;
        break;
    case 2:
        return QString::fromUtf8(kSecondaryTestClip);
    default:
        if (settings.generic.qopenhd_switch_primary_secondary)
            streamConfig = settings.primary_stream_config;
        break;
    }

    if (streamConfig.video_codec == QOpenHDVideoHelper::VideoCodecMJPEG) {
        qWarning() << "Secondary Android MediaPlayer does not support MJPEG codec";
        return {};
    }

    const QString url = buildStreamUrl(streamConfig);
    if (url.isEmpty())
        qWarning() << "Unable to resolve UDP URL for Android secondary stream";

    return url;
}

void QAndroidSecondaryMediaPlayer::startPlaybackOnAndroidThread(const QString &streamUrl,
                                                               const QAndroidJniObject &surfaceTexture)
{
    QPointer<QAndroidSecondaryMediaPlayer> that(this);
    QtAndroid::runOnAndroidThread([that, surfaceTexture, streamUrl] {
        if (!that)
            return;

        if (!that->m_mediaPlayer.isValid())
            return;

        QAndroidJniEnvironment env;

        that->m_mediaPlayer.callMethod<void>("reset");
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer reset failed";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        const QAndroidJniObject url = QAndroidJniObject::fromString(streamUrl);
        that->m_mediaPlayer.callMethod<void>("setDataSource",
                                             "(Ljava/lang/String;)V",
                                             url.object());
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer failed to set data source" << streamUrl;
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->m_surface = QAndroidJniObject("android/view/Surface",
                                            "(Landroid/graphics/SurfaceTexture;)V",
                                            surfaceTexture.object());
        if (!that->m_surface.isValid()) {
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            return;
        }

        that->m_mediaPlayer.callMethod<void>("setSurface",
                                             "(Landroid/view/Surface;)V",
                                             that->m_surface.object());
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer failed to set surface";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->m_mediaPlayer.callMethod<void>("setLooping", "(Z)V", true);
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer failed to enable looping";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->m_mediaPlayer.callMethod<void>("prepare");
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer prepare failed";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->m_mediaPlayer.callMethod<void>("start");
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android MediaPlayer failed to start playback";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->m_pendingPlayback = false;
    });
}

void QAndroidSecondaryMediaPlayer::releaseMediaPlayer()
{
    if (!m_mediaPlayer.isValid()) {
        m_pendingPlayback = false;
        m_surface = QAndroidJniObject();
        return;
    }

    QAndroidJniObject player = m_mediaPlayer;
    QtAndroid::runOnAndroidThread([player] {
        QAndroidJniEnvironment env;
        player.callMethod<void>("stop");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        player.callMethod<void>("reset");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        player.callMethod<void>("release");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
    });

    m_mediaPlayer = QAndroidJniObject();
    m_surface = QAndroidJniObject();
    m_pendingPlayback = false;
}
