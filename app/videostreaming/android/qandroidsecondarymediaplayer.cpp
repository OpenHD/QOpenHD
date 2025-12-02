#include "qandroidsecondarymediaplayer.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QDebug>
#include <QtAndroid>

#include "qsurfacetexture.h"

namespace {
QString codecName(QOpenHDVideoHelper::VideoCodec codec)
{
    return QString::fromStdString(QOpenHDVideoHelper::video_codec_to_string(codec));
}
} // namespace

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

    if (m_videoOut) {
        m_videoOut->disconnect(this);
        stopPlayback();
    }

    qInfo() << "Secondary Android surface texture updated" << videoOut;

    m_videoOut = videoOut;

    if (!m_videoOut) {
        stopPlayback();
        qInfo() << "Secondary Android video output cleared";
    } else {
        connect(m_videoOut.data(), &QSurfaceTexture::surfaceTextureChanged, this, [this] {
            qInfo() << "Secondary Android surface texture changed";
            stopPlayback();
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

std::optional<QOpenHDVideoHelper::VideoStreamConfigXX> QAndroidSecondaryMediaPlayer::resolveStreamConfig() const
{
    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    auto streamConfig = settings.secondary_stream_config;
    switch (settings.generic.dev_secondary_video_input_mode) {
    case 1:
        streamConfig = settings.primary_stream_config;
        break;
    case 2:
        qWarning() << "Secondary Android test clip mode is not supported with the low-latency decoder";
        return std::nullopt;
    default:
        if (settings.generic.qopenhd_switch_primary_secondary)
            streamConfig = settings.primary_stream_config;
        break;
    }

    if (streamConfig.video_codec == QOpenHDVideoHelper::VideoCodecMJPEG) {
        qWarning() << "Secondary Android low-latency decoder does not support MJPEG codec";
        return std::nullopt;
    }

    return streamConfig;
}

void QAndroidSecondaryMediaPlayer::tryStartPlayback()
{
    if (!m_pendingPlayback)
        return;

    if (!m_videoOut) {
        qDebug() << "Secondary Android playback pending but videoOut is null";
        return;
    }

    if (m_playbackRunning) {
        m_pendingPlayback = false;
        return;
    }

    const auto streamConfig = resolveStreamConfig();
    if (!streamConfig) {
        return;
    }

    const QAndroidJniObject surfaceTexture = m_videoOut->surfaceTexture();
    if (!surfaceTexture.isValid()) {
        qWarning() << "Secondary Android surface texture is invalid; delaying playback";
        return;
    }

    if (m_activeConfig != streamConfig) {
        qInfo() << "Secondary Android stream config updated. Port:" << streamConfig->udp_rtp_input_port
                << "Codec:" << codecName(streamConfig->video_codec);
        stopPlayback();
        m_activeConfig = streamConfig;
    }

    if (!m_lowLagDecoder) {
        qInfo() << "Creating secondary low-latency decoder";
        m_lowLagDecoder = std::make_unique<LowLagDecoder>(nullptr, true, "secondary");
        m_lowLagDecoder->registerOnDecoderRatioChangedCallback([this](const VideoRatio ratio) {
            if (m_videoOut) {
                m_videoOut->set_video_texture_size(ratio.width, ratio.height);
            }
        });
        m_lowLagDecoder->registerOnDecodingInfoChangedCallback([](const DecodingInfo &info) {
            qInfo() << "Secondary decoder stats fps:" << info.currentFPS << "parse_ms:" << info.avgParsingTime_ms
                    << "wait_ms:" << info.avgWaitForInputBTime_ms << "decode_ms:" << info.avgDecodingTime_ms;
        });
    }

    if (!m_receiver && m_activeConfig) {
        qInfo() << "Starting secondary RTP receiver on port" << m_activeConfig->udp_rtp_input_port
                << "for codec" << codecName(m_activeConfig->video_codec);
        m_receiver = std::make_unique<GstRtpReceiver>(m_activeConfig->udp_rtp_input_port,
                                                      m_activeConfig->video_codec);
    }

    if (!m_receiver || !m_lowLagDecoder)
        return;

    startPlaybackOnAndroidThread(surfaceTexture);
}

void QAndroidSecondaryMediaPlayer::startPlaybackOnAndroidThread(const QAndroidJniObject &surfaceTexture)
{
    if (!m_activeConfig || !m_lowLagDecoder || !m_receiver)
        return;

    QPointer<QAndroidSecondaryMediaPlayer> that(this);
    QtAndroid::runOnAndroidThread([this, that, surfaceTexture] {
        if (!that || !m_activeConfig || !m_lowLagDecoder || !m_receiver)
            return;

        QAndroidJniEnvironment env;
        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                  surfaceTexture.object());
        if (env->ExceptionCheck()) {
            qWarning() << "Secondary Android surface creation failed";
            env->ExceptionDescribe();
            env->ExceptionClear();
            return;
        }

        if (!surface.isValid()) {
            qWarning() << "Secondary Android surface is invalid";
            return;
        }

        m_lowLagDecoder->setOutputSurface(env, surface.object());

        auto *receiver = m_receiver.get();
        auto *decoder = m_lowLagDecoder.get();
        m_receiver->start_receiving([that, decoder, receiver](std::shared_ptr<std::vector<uint8_t>> sample) {
            if (!that || !decoder || !receiver)
                return;
            const bool is_h265 = receiver->get_codec() == QOpenHDVideoHelper::VideoCodecH265;
            NALU nalu(sample->data(), sample->size(), is_h265);
            decoder->interpretNALU(nalu);
        });

        m_pendingPlayback = false;
        m_playbackRunning = true;
    });
}

void QAndroidSecondaryMediaPlayer::stopPlayback()
{
    if (m_receiver) {
        qInfo() << "Stopping secondary RTP receiver";
        m_receiver->stop_receiving();
        m_receiver.reset();
    }

    if (m_lowLagDecoder) {
        QAndroidJniEnvironment env;
        m_lowLagDecoder->setOutputSurface(env, nullptr);
        m_lowLagDecoder.reset();
    }

    m_activeConfig.reset();
    m_pendingPlayback = false;
    m_playbackRunning = false;
}
