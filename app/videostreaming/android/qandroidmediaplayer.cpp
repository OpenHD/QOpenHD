#include "qandroidmediaplayer.h"
#include "qsurfacetexture.h"

#include <QAndroidJniEnvironment>

#include <decodingstatistcs.h>

QAndroidMediaPlayer::QAndroidMediaPlayer(QObject *parent)
    : QObject(parent)
{
    setup_start_video_decoder_display();
}

void QAndroidMediaPlayer::setup_start_video_decoder_display()
{
    // Everything should be cleaned up
    assert(m_low_lag_decoder==nullptr);
    assert(m_receiver==nullptr);
    m_low_lag_decoder=std::make_unique<LowLagDecoder>(nullptr);
    auto stats_cb=[](const DecodingInfo di){
        std::stringstream ss;
        ss<<di.avgDecodingTime_ms<<"ms";
        DecodingStatistcs::instance().set_decode_time(ss.str().c_str());
    };
    m_low_lag_decoder->registerOnDecodingInfoChangedCallback(stats_cb);
    auto ratio_changed_cb=[this](const VideoRatio ratio){
        DecodingStatistcs::instance().util_set_primary_stream_frame_format("android",ratio.width,ratio.height);
        if(m_videoOut){
            m_videoOut->set_video_texture_size(ratio.width,ratio.height);
        }
    };
    m_low_lag_decoder->registerOnDecoderRatioChangedCallback(ratio_changed_cb);
    const auto settings=QOpenHDVideoHelper::read_config_from_settings();
    auto codec=settings.primary_stream_config.video_codec;
    const int port = settings.generic.qopenhd_switch_primary_secondary ? 5601 : 5600;
    m_receiver=std::make_unique<GstRtpReceiver>(port,codec);
}

void QAndroidMediaPlayer::stop_cleanup_decoder_display()
{
    // first, we stop the rtp receiver
    m_receiver->stop_receiving();
    m_receiver=nullptr;
    // Then we can safely clean up the decoder (and its surface)
    m_low_lag_decoder->setOutputSurface(nullptr,nullptr);
    m_low_lag_decoder=nullptr;
}

QAndroidMediaPlayer::~QAndroidMediaPlayer()
{
    /*QAndroidJniEnvironment env;
    m_mediaPlayer.callMethod<void>("stop");
    m_mediaPlayer.callMethod<void>("reset");
    m_mediaPlayer.callMethod<void>("release");*/
    //m_mediaPlayer.callMethod<void>("releaseAll");

    stop_cleanup_decoder_display();
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
    qDebug()<<"QAndroidMediaPlayer::setVideoOut";

    auto setSurfaceTexture = [=]{
        // Create a new Surface object from our SurfaceTexture
        /*QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                   m_videoOut->surfaceTexture().object());

        // Set the new surface to m_mediaPlayer object
        m_mediaPlayer.callMethod<void>("setSurface",
                                       "(Landroid/view/Surface;)V",
                                       surface.object());*/
        /*m_mediaPlayer.callMethod<void>("setSurfaceTexture",
                                       "(Landroid/graphics/SurfaceTexture;)V",
                                       m_videoOut->surfaceTexture().object());*/
        {
            QAndroidJniObject surface("android/view/Surface",
                                              "(Landroid/graphics/SurfaceTexture;)V",
                                               m_videoOut->surfaceTexture().object());
            QAndroidJniEnvironment env;
            m_low_lag_decoder->setOutputSurface(env,surface.object());
        }
        auto cb=[this](std::shared_ptr<std::vector<uint8_t>> sample){
            bool is_h265=m_receiver->get_codec()==QOpenHDVideoHelper::VideoCodecH265;
            NALU nalu(sample->data(),sample->size(),is_h265);
            //qDebug()<<"XGot frame:"<<nalu.get_nal_unit_type_as_string().c_str();
            m_low_lag_decoder->interpretNALU(nalu);
        };
        m_receiver->start_receiving(cb);
    };
    if (videoOut->surfaceTexture().isValid()){
        setSurfaceTexture();
    }else{
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, setSurfaceTexture);
    }
    emit videoOutChanged();
}

void QAndroidMediaPlayer::switch_primary_secondary()
{
    // first, we stop the rtp receiver
    m_receiver->stop_receiving();
    // Then we can safely clean up the decoder (and its surface)
    m_low_lag_decoder->setOutputSurface(nullptr,nullptr);
    // and re-create it with the right video port as input
}

/*void QAndroidMediaPlayer::playFile(const QString &file)
{
    qDebug()<<"QAndroidMediaPlayer::playFile"<<file;
    QAndroidJniEnvironment env;
    m_mediaPlayer.callMethod<void>("playUrl", "(Ljava/lang/String;)V", QAndroidJniObject::fromString(file).object());
    m_mediaPlayer.callMethod<void>("stop"); // try to stop the media player.
    m_mediaPlayer.callMethod<void>("reset"); // try to reset the media player.

    // http://developer.android.com/reference/android/media/MediaPlayer.html#setDataSource(java.lang.String) - the path of the file, or the http/rtsp URL of the stream you want to play.
    m_mediaPlayer.callMethod<void>("setDataSource", "(Ljava/lang/String;)V", QAndroidJniObject::fromString(file).object());

    // prepare media player
    m_mediaPlayer.callMethod<void>("prepare");

    // start playing
    m_mediaPlayer.callMethod<void>("start");
}*/
