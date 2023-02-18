#include "qandroidmediaplayer.h"
#include "qsurfacetexture.h"

#include <QAndroidJniEnvironment>

#include <gst/gst.h>

static void lol(){
    GstElement * m_pipeline=nullptr;
    GError *error = nullptr;
    m_pipeline = gst_parse_launch("", &error);
}

QAndroidMediaPlayer::QAndroidMediaPlayer(QObject *parent)
    : QObject(parent)
    ,m_mediaPlayer("org/openhd/LiveVideoPlayerWrapper")
    //, m_mediaPlayer("android/media/MediaPlayer")
{
}

QAndroidMediaPlayer::~QAndroidMediaPlayer()
{
    QAndroidJniEnvironment env;
    /*m_mediaPlayer.callMethod<void>("stop");
    m_mediaPlayer.callMethod<void>("reset");
    m_mediaPlayer.callMethod<void>("release");*/
    m_mediaPlayer.callMethod<void>("releaseAll");
    lol();
}

QSurfaceTexture *QAndroidMediaPlayer::videoOut() const
{
    return m_videoOut;
}

void QAndroidMediaPlayer::setVideoOut(QSurfaceTexture *videoOut)
{
    if (m_videoOut == videoOut)
        return;
    if (m_videoOut)
        m_videoOut->disconnect(this);
    m_videoOut = videoOut;

    auto setSurfaceTexture = [=]{
        // Create a new Surface object from our SurfaceTexture
        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                   m_videoOut->surfaceTexture().object());

        // Set the new surface to m_mediaPlayer object
        m_mediaPlayer.callMethod<void>("setSurface",
                                       "(Landroid/view/Surface;)V",
                                       surface.object());
    };

    if (videoOut->surfaceTexture().isValid())
        setSurfaceTexture();
    else
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, setSurfaceTexture);
    emit videoOutChanged();
}

void QAndroidMediaPlayer::playFile(const QString &file)
{
    qDebug()<<"QAndroidMediaPlayer::playFile"<<file;
    QAndroidJniEnvironment env;
    m_mediaPlayer.callMethod<void>("playUrl", "(Ljava/lang/String;)V", QAndroidJniObject::fromString(file).object());
    /*m_mediaPlayer.callMethod<void>("stop"); // try to stop the media player.
    m_mediaPlayer.callMethod<void>("reset"); // try to reset the media player.

    // http://developer.android.com/reference/android/media/MediaPlayer.html#setDataSource(java.lang.String) - the path of the file, or the http/rtsp URL of the stream you want to play.
    m_mediaPlayer.callMethod<void>("setDataSource", "(Ljava/lang/String;)V", QAndroidJniObject::fromString(file).object());

    // prepare media player
    m_mediaPlayer.callMethod<void>("prepare");

    // start playing
    m_mediaPlayer.callMethod<void>("start");*/
}
