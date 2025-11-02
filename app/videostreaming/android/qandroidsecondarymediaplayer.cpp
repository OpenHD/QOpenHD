#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QDebug>
#include <QString>

#include <memory>
#include <vector>

#include "qsurfacetexture.h"

#include "../gstreamer/gstrtpreceiver.h"
#include "../vscommon/QOpenHDVideoHelper.hpp"
#include "lowlagdecoder.h"

#include <nalu/NALU.hpp>

QAndroidSecondaryMediaPlayer::QAndroidSecondaryMediaPlayer(QObject *parent)
    : QObject(parent)
{
}

QAndroidSecondaryMediaPlayer::~QAndroidSecondaryMediaPlayer()
{
    stopPlayback();
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
        stopPlayback();
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
    m_pendingPlayback = true;
    tryStartPlayback();
}

void QAndroidSecondaryMediaPlayer::tryStartPlayback()
{
    if (!m_videoOut)
        return;

    ensureDecoderAndReceiver();
    if (!m_lowLagDecoder || !m_receiver)
        return;

    attachSurface();
    if (!m_pendingPlayback || m_streamingActive)
        return;

    const QAndroidJniObject surfaceTexture = m_videoOut->surfaceTexture();
    if (!surfaceTexture.isValid())
        return;

    startReceiving();
}

void QAndroidSecondaryMediaPlayer::ensureDecoderAndReceiver()
{
    if (m_lowLagDecoder && m_receiver)
        return;

    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto streamConfig = settings.secondary_stream_config;
    if (settings.generic.qopenhd_switch_primary_secondary) {
        streamConfig = settings.primary_stream_config;
    }

    if (streamConfig.video_codec == QOpenHDVideoHelper::VideoCodecMJPEG) {
        qWarning() << "Secondary Android decoder does not support MJPEG codec";
        return;
    }

    m_lowLagDecoder = std::make_unique<LowLagDecoder>(nullptr);
    m_lowLagDecoder->registerOnDecoderRatioChangedCallback([this](const VideoRatio &ratio) {
        if (m_videoOut)
            m_videoOut->set_video_texture_size(ratio.width, ratio.height);
    });

    m_receiver = std::make_unique<GstRtpReceiver>(streamConfig.udp_rtp_input_port,
                                                  streamConfig.video_codec);
}

void QAndroidSecondaryMediaPlayer::attachSurface()
{
    if (!m_lowLagDecoder || !m_videoOut)
        return;

    const QAndroidJniObject surfaceTexture = m_videoOut->surfaceTexture();
    if (!surfaceTexture.isValid())
        return;

    QAndroidJniEnvironment env;
    QAndroidJniObject surface("android/view/Surface",
                              "(Landroid/graphics/SurfaceTexture;)V",
                              surfaceTexture.object());
    if (!surface.isValid()) {
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        return;
    }

    m_lowLagDecoder->setOutputSurface(env, surface.object());
}

void QAndroidSecondaryMediaPlayer::startReceiving()
{
    if (!m_receiver || !m_lowLagDecoder)
        return;

    auto cb = [this](std::shared_ptr<std::vector<uint8_t>> sample) {
        if (!m_lowLagDecoder || !m_receiver)
            return;

        const bool isH265 = m_receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
        NALU nalu(sample->data(), sample->size(), isH265);
        m_lowLagDecoder->interpretNALU(nalu);
    };

    m_receiver->start_receiving(cb);
    m_streamingActive = true;
    m_pendingPlayback = false;
}

void QAndroidSecondaryMediaPlayer::stopPlayback()
{
    if (m_receiver) {
        m_receiver->stop_receiving();
        m_receiver.reset();
    }

    if (m_lowLagDecoder) {
        m_lowLagDecoder->setOutputSurface(nullptr, nullptr);
        m_lowLagDecoder.reset();
    }

    m_streamingActive = false;
    m_pendingPlayback = false;
}
