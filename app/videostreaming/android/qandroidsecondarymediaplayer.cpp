#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QDebug>
#include <QtAndroid>
#include <QString>

#include "qsurfacetexture.h"

namespace {
static constexpr const char *kSecondaryStreamUrl = "udp://@:5600";
}

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

    if (m_videoOut) {
        m_videoOut->disconnect(this);
    }

    m_videoOut = videoOut;

    if (!m_videoOut) {
        m_surface = QAndroidJniObject();
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, [this] {
            tryStartPlayback();
        });
    }

    tryStartPlayback();
    emit videoOutChanged();
}

void QAndroidSecondaryMediaPlayer::playDebugLoop()
{
    m_pendingDebugPlayback = true;
    tryStartPlayback();
}

void QAndroidSecondaryMediaPlayer::tryStartPlayback()
{
    if (!m_pendingDebugPlayback)
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
    if (!surfaceTexture.isValid())
        return;

    QPointer<QAndroidSecondaryMediaPlayer> that(this);
    QtAndroid::runOnAndroidThread([that, surfaceTexture] {
        if (!that)
            return;

        if (!that->m_mediaPlayer.isValid())
            return;

        QAndroidJniEnvironment env;

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
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        that->startDebugPlaybackOnAndroidThread();
    });
}

void QAndroidSecondaryMediaPlayer::startDebugPlaybackOnAndroidThread()
{
    if (!m_pendingDebugPlayback)
        return;
    if (!m_mediaPlayer.isValid() || !m_surface.isValid())
        return;

    QAndroidJniEnvironment env;

    m_mediaPlayer.callMethod<void>("reset");
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    const QAndroidJniObject url = QAndroidJniObject::fromString(QString::fromUtf8(kSecondaryStreamUrl));
    m_mediaPlayer.callMethod<void>("setDataSource",
                                   "(Ljava/lang/String;)V",
                                   url.object());
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    m_mediaPlayer.callMethod<void>("setLooping", "(Z)V", true);
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    m_mediaPlayer.callMethod<void>("prepare");
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    m_mediaPlayer.callMethod<void>("start");
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    m_pendingDebugPlayback = false;
}

void QAndroidSecondaryMediaPlayer::releaseMediaPlayer()
{
    if (!m_mediaPlayer.isValid())
        return;

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
}
