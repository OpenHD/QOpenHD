#include "qandroidmediaplayer.h"
#include "qsurfacetexture.h"

// --- Qt5/Qt6 JNI compatibility shim ---
#include <QtGlobal>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  #include <QJniObject>
  #include <QJniEnvironment>
  using QAndroidJniObject = QJniObject;
  using QAndroidJniEnvironment = QJniEnvironment;
#else
  #include <QAndroidJniObject>
  #include <QAndroidJniEnvironment>
  #include <QtAndroid>
#endif
// --------------------------------------

#include <QDebug>
#include <cassert>
#include <memory>
#include <sstream>

#include <decodingstatistcs.h>
#include "../vscommon/QOpenHDVideoHelper.hpp"

QAndroidMediaPlayer::QAndroidMediaPlayer(QObject *parent)
    : QObject(parent)
{
    setup_start_video_decoder_display();
}

void QAndroidMediaPlayer::setup_start_video_decoder_display()
{
    // Everything should be cleaned up
    assert(m_low_lag_decoder == nullptr);
    assert(m_receiver == nullptr);

    m_low_lag_decoder = std::make_unique<LowLagDecoder>(nullptr);

    auto stats_cb = [](const DecodingInfo di) {
        std::stringstream ss;
        ss << di.avgDecodingTime_ms << "ms";
        DecodingStatistcs::instance().set_decode_time(ss.str().c_str());
    };
    m_low_lag_decoder->registerOnDecodingInfoChangedCallback(stats_cb);

    auto ratio_changed_cb = [this](const VideoRatio ratio) {
        DecodingStatistcs::instance().util_set_primary_stream_frame_format("android", ratio.width, ratio.height);
        if (m_videoOut) {
            m_videoOut->set_video_texture_size(ratio.width, ratio.height);
        }
    };
    m_low_lag_decoder->registerOnDecoderRatioChangedCallback(ratio_changed_cb);

    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto codec = settings.primary_stream_config.video_codec;
    const int port = settings.generic.qopenhd_switch_primary_secondary ? 5601 : 5600;

    m_receiver = std::make_unique<GstRtpReceiver>(port, codec);
}

void QAndroidMediaPlayer::stop_cleanup_decoder_display()
{
    if (m_receiver) {
        // first, stop the RTP receiver
        m_receiver->stop_receiving();
        m_receiver = nullptr;
    }

    if (m_low_lag_decoder) {
        // Then we can safely clean up the decoder (and its surface)
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);
        m_low_lag_decoder = nullptr;
    }
}

QAndroidMediaPlayer::~QAndroidMediaPlayer()
{
    // If you had a Java media player, this is where you would release it.
    // QAndroidJniEnvironment env;
    // m_mediaPlayer.callMethod<void>("stop");
    // m_mediaPlayer.callMethod<void>("reset");
    // m_mediaPlayer.callMethod<void>("release");

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
    qDebug() << "QAndroidMediaPlayer::setVideoOut";

    auto setSurfaceTexture = [=] {
        // Create a new android.view.Surface from our SurfaceTexture
        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                   m_videoOut->surfaceTexture().object());

        // Hand the Surface to the low-lag decoder
        QAndroidJniEnvironment env;
        m_low_lag_decoder->setOutputSurface(env, surface.object());

        // Start receiving RTP and feed the decoder
        auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample) {
            bool is_h265 = m_receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
            NALU nalu(sample->data(), sample->size(), is_h265);
            m_low_lag_decoder->interpretNALU(nalu);
        };
        m_receiver->start_receiving(cb);
    };

    if (videoOut->surfaceTexture().isValid()) {
        setSurfaceTexture();
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, setSurfaceTexture);
    }

    emit videoOutChanged();
}

void QAndroidMediaPlayer::switch_primary_secondary()
{
    // Stop the RTP receiver first
    if (m_receiver) {
        m_receiver->stop_receiving();
    }
    // Then release the decoder surface
    if (m_low_lag_decoder) {
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);
    }
    // Re-create with the new port if needed (left to your caller to trigger setup again)
}

/* If you reintroduce file playback via Java MediaPlayer, the pattern is:
void QAndroidMediaPlayer::playFile(const QString &file)
{
    qDebug() << "QAndroidMediaPlayer::playFile" << file;
    QAndroidJniEnvironment env;
    m_mediaPlayer.callMethod<void>("playUrl", "(Ljava/lang/String;)V",
                                   QAndroidJniObject::fromString(file).object());

    m_mediaPlayer.callMethod<void>("stop");
    m_mediaPlayer.callMethod<void>("reset");

    m_mediaPlayer.callMethod<void>("setDataSource", "(Ljava/lang/String;)V",
                                   QAndroidJniObject::fromString(file).object());

    m_mediaPlayer.callMethod<void>("prepare");
    m_mediaPlayer.callMethod<void>("start");
}
*/
