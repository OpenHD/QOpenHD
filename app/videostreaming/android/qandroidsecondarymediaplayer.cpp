#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>

#include "qsurfacetexture.h"

QAndroidSecondaryMediaPlayer::QAndroidSecondaryMediaPlayer(QObject *parent)
    : QObject(parent)
{
    setup_start_video_decoder_display();
}

QAndroidSecondaryMediaPlayer::~QAndroidSecondaryMediaPlayer()
{
    stop_cleanup_decoder_display();
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

    stopReceiving();
    if (m_low_lag_decoder) {
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);
    }

    m_videoOut = videoOut;

    if (!m_videoOut) {
        emit videoOutChanged();
        return;
    }

    auto setSurfaceTexture = [this] {
        if (!m_videoOut)
            return;

        if (!m_low_lag_decoder || !m_receiver)
            setup_start_video_decoder_display();

        if (!m_low_lag_decoder || !m_receiver)
            return;

        QAndroidJniEnvironment env;
        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                  m_videoOut->surfaceTexture().object());
        m_low_lag_decoder->setOutputSurface(env, surface.object());
        maybeStartReceiving();
    };

    if (m_videoOut->surfaceTexture().isValid()) {
        setSurfaceTexture();
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, setSurfaceTexture);
    }

    emit videoOutChanged();
    maybeStartReceiving();
}

void QAndroidSecondaryMediaPlayer::playDebugLoop()
{
    m_should_start = true;
    maybeStartReceiving();
}

void QAndroidSecondaryMediaPlayer::setup_start_video_decoder_display()
{
    if (m_low_lag_decoder || m_receiver)
        return;

    m_low_lag_decoder = std::make_unique<LowLagDecoder>(nullptr);
    auto ratio_changed_cb = [this](const VideoRatio &ratio) {
        if (m_videoOut) {
            m_videoOut->set_video_texture_size(ratio.width, ratio.height);
        }
    };
    m_low_lag_decoder->registerOnDecoderRatioChangedCallback(ratio_changed_cb);

    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    const auto codec = settings.primary_stream_config.video_codec;
    const int port = settings.generic.qopenhd_switch_primary_secondary ? 5600 : 5601;
    m_receiver = std::make_unique<GstRtpReceiver>(port, codec);
}

void QAndroidSecondaryMediaPlayer::stop_cleanup_decoder_display()
{
    stopReceiving();
    if (m_receiver) {
        m_receiver = nullptr;
    }
    if (m_low_lag_decoder) {
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);
        m_low_lag_decoder = nullptr;
    }
    m_should_start = false;
}

void QAndroidSecondaryMediaPlayer::stopReceiving()
{
    if (!m_receiver)
        return;

    if (!m_receiving)
        return;

    m_receiver->stop_receiving();
    m_receiving = false;
}

void QAndroidSecondaryMediaPlayer::maybeStartReceiving()
{
    if (!m_should_start)
        return;
    if (!m_videoOut)
        return;
    if (!m_videoOut->surfaceTexture().isValid())
        return;

    if (!m_low_lag_decoder || !m_receiver)
        setup_start_video_decoder_display();

    if (!m_low_lag_decoder || !m_receiver)
        return;

    if (m_receiving)
        return;

    auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample) {
        const bool is_h265 = m_receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
        NALU nalu(sample->data(), sample->size(), is_h265);
        m_low_lag_decoder->interpretNALU(nalu);
    };

    m_receiver->start_receiving(cb);
    m_receiving = true;
}
