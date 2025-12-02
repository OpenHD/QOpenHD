#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QDebug>

#include "qsurfacetexture.h"

#include "../vscommon/QOpenHDVideoHelper.hpp"

QAndroidSecondaryMediaPlayer::QAndroidSecondaryMediaPlayer(QObject *parent)
    : QObject(parent)
{
    m_streamConfig = resolveStreamConfig();
    if (!m_streamConfig) {
        m_secondaryVideoEnabled = false;
        return;
    }
    m_lowLagDecoder = std::make_unique<LowLagDecoder>(nullptr);
    auto ratioChanged = [this](const VideoRatio ratio) {
        if (m_videoOut)
            m_videoOut->set_video_texture_size(ratio.width, ratio.height);
    };
    m_lowLagDecoder->registerOnDecoderRatioChangedCallback(ratioChanged);

    m_receiver = std::make_unique<GstRtpReceiver>(m_streamConfig->udp_rtp_input_port,
                                                  m_streamConfig->video_codec);
}

QAndroidSecondaryMediaPlayer::~QAndroidSecondaryMediaPlayer()
{
    stopAndCleanup();
    m_receiver.reset();
    m_lowLagDecoder.reset();
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
        stopAndCleanup();
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, [this] {
            tryStartPlayback();
        });
        tryStartPlayback();
    }
    emit videoOutChanged();
}

void QAndroidSecondaryMediaPlayer::playDebugLoop()
{
    tryStartPlayback();
}

void QAndroidSecondaryMediaPlayer::tryStartPlayback()
{
    if (!m_secondaryVideoEnabled)
        return;

    if (!m_streamConfig)
        return;

    if (!m_videoOut)
        return;

    const auto surfaceTexture = m_videoOut->surfaceTexture();
    if (!surfaceTexture.isValid()) {
        qWarning() << "Secondary Android surface texture is invalid; delaying playback";
        return;
    }

    attachSurfaceAndStart();
}

std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> QAndroidSecondaryMediaPlayer::resolveStreamConfig() const
{
    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto streamConfig = settings.secondary_stream_config;
    switch (settings.generic.dev_secondary_video_input_mode) {
    case 1:
        streamConfig = settings.primary_stream_config;
        break;
    case 2:
        qWarning() << "Test-clip secondary playback is not supported on Android";
        return std::nullopt;
    default:
        if (settings.generic.qopenhd_switch_primary_secondary)
            streamConfig = settings.primary_stream_config;
        break;
    }

    if (streamConfig.video_codec == QOpenHDVideoHelper::VideoCodecMJPEG) {
        qWarning() << "Secondary Android decoder does not support MJPEG codec";
        return std::nullopt;
    }

    return streamConfig;
}

void QAndroidSecondaryMediaPlayer::attachSurfaceAndStart()
{
    if (!m_streamConfig) {
        qWarning() << "Secondary Android decoder not initialized";
        return;
    }

    if (!m_lowLagDecoder) {
        m_lowLagDecoder = std::make_unique<LowLagDecoder>(nullptr);
        auto ratioChanged = [this](const VideoRatio ratio) {
            if (m_videoOut)
                m_videoOut->set_video_texture_size(ratio.width, ratio.height);
        };
        m_lowLagDecoder->registerOnDecoderRatioChangedCallback(ratioChanged);
    }

    if (!m_receiver) {
        m_receiver = std::make_unique<GstRtpReceiver>(m_streamConfig->udp_rtp_input_port,
                                                      m_streamConfig->video_codec);
    }

    if (m_playbackActive)
        return;

    QAndroidJniEnvironment env;
    QAndroidJniObject surface("android/view/Surface",
                              "(Landroid/graphics/SurfaceTexture;)V",
                              m_videoOut->surfaceTexture().object());
    if (!surface.isValid()) {
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        return;
    }

    m_lowLagDecoder->setOutputSurface(env, surface.object());

    auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample) {
        const bool isH265 = m_receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
        NALU nalu(sample->data(), sample->size(), isH265);
        m_lowLagDecoder->interpretNALU(nalu);
    };
    m_receiver->start_receiving(cb);
    m_playbackActive = true;
}

void QAndroidSecondaryMediaPlayer::stopAndCleanup()
{
    if (m_receiver) {
        m_receiver->stop_receiving();
    }

    if (m_lowLagDecoder) {
        m_lowLagDecoder->setOutputSurface(nullptr, nullptr);
    }

    m_playbackActive = false;
}
