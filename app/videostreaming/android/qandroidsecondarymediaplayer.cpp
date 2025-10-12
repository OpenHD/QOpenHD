#include "qandroidsecondarymediaplayer.h"

#include "QOpenHDVideoHelper.hpp"
#include "qsurfacetexture.h"

#include <QAndroidJniEnvironment>
#include <QDebug>

#include <memory>
#include <vector>

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

    if (m_videoOut)
        m_videoOut->disconnect(this);

    if (m_receiver)
        m_receiver->stop_receiving();

    if (m_receiver)
        m_receiver_running = false;

    if (m_low_lag_decoder)
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);

    m_videoOut = videoOut;

    if (!m_low_lag_decoder || !m_receiver) {
        emit videoOutChanged();
        return;
    }

    if (!m_videoOut) {
        emit videoOutChanged();
        return;
    }

    auto setSurfaceTexture = [this]() {
        if (!m_videoOut)
            return;

        const auto surfaceTexture = m_videoOut->surfaceTexture();
        if (!surfaceTexture.isValid())
            return;

        QAndroidJniEnvironment env;
        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                  surfaceTexture.object());
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        m_low_lag_decoder->setOutputSurface(env, surface.object());

        if (m_receiver_running)
            return;

        auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample) {
            if (!m_low_lag_decoder)
                return;

            const bool isH265 = m_receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
            NALU nalu(sample->data(), sample->size(), isH265);
            m_low_lag_decoder->interpretNALU(nalu);
        };

        if (m_receiver->start_receiving(cb)) {
            m_receiver_running = true;
        } else {
            qWarning() << "Failed to start secondary GstRtpReceiver";
        }
    };

    if (m_videoOut && m_videoOut->surfaceTexture().isValid()) {
        setSurfaceTexture();
    } else if (m_videoOut) {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, setSurfaceTexture);
    }

    emit videoOutChanged();
}

void QAndroidSecondaryMediaPlayer::setup_start_video_decoder_display()
{
    Q_ASSERT(!m_low_lag_decoder);
    Q_ASSERT(!m_receiver);

    m_low_lag_decoder = std::make_unique<LowLagDecoder>(nullptr);

    auto ratioChangedCb = [this](const VideoRatio ratio) {
        if (!m_videoOut)
            return;
        m_videoOut->set_video_texture_size(ratio.width, ratio.height);
    };
    m_low_lag_decoder->registerOnDecoderRatioChangedCallback(ratioChangedCb);

    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto stream_config = settings.secondary_stream_config;
    if (settings.generic.qopenhd_switch_primary_secondary) {
        stream_config = settings.primary_stream_config;
    }

    m_receiver = std::make_unique<GstRtpReceiver>(stream_config.udp_rtp_input_port,
                                                  stream_config.video_codec);
    m_receiver_running = false;
}

void QAndroidSecondaryMediaPlayer::stop_cleanup_decoder_display()
{
    if (m_receiver) {
        m_receiver->stop_receiving();
        m_receiver = nullptr;
        m_receiver_running = false;
    }

    if (m_low_lag_decoder) {
        m_low_lag_decoder->setOutputSurface(nullptr, nullptr);
        m_low_lag_decoder = nullptr;
    }
}
