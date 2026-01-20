// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_pipeline.h"

#include <QDebug>
#include <QSettings>

#include "../vscommon/QOpenHDVideoHelper.hpp"


V4L2Pipeline& V4L2Pipeline::instance()
{
    static V4L2Pipeline pipeline;
    return pipeline;
}

V4L2Pipeline::V4L2Pipeline()
{
    qDebug() << "V4L2Pipeline: created";
}

V4L2Pipeline::~V4L2Pipeline()
{
    stop();
    qDebug() << "V4L2Pipeline: destroyed";
}

bool V4L2Pipeline::init(const Config& config)
{
    if (m_running) {
        qWarning() << "V4L2Pipeline: cannot init while running";
        return false;
    }

    m_config = config;

    qInfo() << "V4L2Pipeline: initializing...";
    qInfo() << "  RTP:" << config.rtp_listen_addr.c_str() << ":" << config.rtp_listen_port;
    qInfo() << "  Codec:" << (config.codec == Config::Codec::H264 ? "H264" : "H265");
    qInfo() << "  V4L2 device:" << config.v4l2_device.c_str();

    // Create components
#if defined(ENABLE_UVGRTP)
    m_rtp_receiver = std::make_unique<UvgRtpReceiver>();
#endif
    m_decoder = std::make_unique<V4L2Decoder>();

#if defined(ENABLE_UVGRTP)
    // Initialize RTP receiver
    UvgRtpReceiver::Codec rtp_codec = (config.codec == Config::Codec::H264)
        ? UvgRtpReceiver::Codec::H264
        : UvgRtpReceiver::Codec::H265;

    if (!m_rtp_receiver->init(config.rtp_listen_addr, config.rtp_listen_port, rtp_codec)) {
        qCritical() << "V4L2Pipeline: failed to init RTP receiver:"
                    << m_rtp_receiver->get_last_error().c_str();
        return false;
    }
#else
    qWarning() << "V4L2Pipeline: uvgRTP not enabled, no RTP reception";
#endif

    // Initialize V4L2 decoder
    V4L2Decoder::Codec dec_codec = (config.codec == Config::Codec::H264)
        ? V4L2Decoder::Codec::H264
        : V4L2Decoder::Codec::H265;

    if (!m_decoder->init(config.v4l2_device, dec_codec)) {
        qCritical() << "V4L2Pipeline: failed to init decoder:"
                    << m_decoder->get_last_error().c_str();
        return false;
    }

    // Wire up callbacks
#if defined(ENABLE_UVGRTP)
    m_rtp_receiver->set_nal_callback([this](const uint8_t* data, size_t size, int64_t ts) {
        on_nal_received(data, size, ts);
    });
#endif

    m_decoder->set_frame_callback([this](PlaceboFrame frame) {
        on_frame_decoded(std::move(frame));
    });

    m_decoder->set_capabilities_callback([this](const V4L2Decoder::Capabilities& caps) {
        on_decoder_capabilities(caps);
    });

    m_initialized = true;
    qInfo() << "V4L2Pipeline: initialized successfully";
    return true;
}

bool V4L2Pipeline::init_from_settings()
{
    Config config;

    // Read configuration from QSettings
    QSettings settings;

    // RTP settings (use same settings as existing video stream config)
    auto stream_config = QOpenHDVideoHelper::read_from_settingsXX(true);  // primary stream
    config.rtp_listen_addr = stream_config.udp_rtp_input_ip_address;
    config.rtp_listen_port = static_cast<uint16_t>(stream_config.udp_rtp_input_port);

    // Codec
    config.codec = (stream_config.video_codec == QOpenHDVideoHelper::VideoCodecH265)
        ? Config::Codec::H265
        : Config::Codec::H264;

    // V4L2 device - can be configured via setting
    config.v4l2_device = settings.value("v4l2_decoder_device", "/dev/video0").toString().toStdString();

    return init(config);
}

bool V4L2Pipeline::start()
{
    if (!m_initialized) {
        qWarning() << "V4L2Pipeline: not initialized";
        return false;
    }

    if (m_running) {
        qWarning() << "V4L2Pipeline: already running";
        return true;
    }

    qInfo() << "V4L2Pipeline: starting...";

    // Start decoder first (needs to be ready to receive NALs)
    if (!m_decoder->start()) {
        qCritical() << "V4L2Pipeline: failed to start decoder";
        return false;
    }

#if defined(ENABLE_UVGRTP)
    // Start RTP receiver
    if (!m_rtp_receiver->start()) {
        qCritical() << "V4L2Pipeline: failed to start RTP receiver";
        m_decoder->stop();
        return false;
    }
#endif

    m_running = true;
    qInfo() << "V4L2Pipeline: started";
    return true;
}

void V4L2Pipeline::stop()
{
    if (!m_running) return;

    qInfo() << "V4L2Pipeline: stopping...";

    // Stop frame queue first (unblocks waiter thread)
    m_frame_queue.stop();

#if defined(ENABLE_UVGRTP)
    // Stop RTP receiver (stop incoming data)
    if (m_rtp_receiver) {
        m_rtp_receiver->stop();
    }
#endif

    // Stop decoder
    if (m_decoder) {
        m_decoder->stop();
    }

    // Reset frame queue (clears any remaining frames)
    m_frame_queue.reset();

    m_running = false;
    m_format_ready = false;

    qInfo() << "V4L2Pipeline: stopped";
}

const V4L2Decoder::Capabilities& V4L2Pipeline::get_decoder_capabilities() const
{
    static V4L2Decoder::Capabilities empty_caps;
    if (!m_decoder) return empty_caps;
    return m_decoder->get_capabilities();
}

V4L2Pipeline::Stats V4L2Pipeline::get_stats() const
{
    Stats stats;

#if defined(ENABLE_UVGRTP)
    if (m_rtp_receiver) {
        stats.rtp = m_rtp_receiver->get_stats();
    }
#endif
    if (m_decoder) {
        stats.decoder = m_decoder->get_stats();
    }
    stats.queue = m_frame_queue.get_stats();

    return stats;
}

void V4L2Pipeline::reset_stats()
{
#if defined(ENABLE_UVGRTP)
    if (m_rtp_receiver) {
        m_rtp_receiver->reset_stats();
    }
#endif
    if (m_decoder) {
        m_decoder->reset_stats();
    }
    m_frame_queue.reset_stats();
}

std::string V4L2Pipeline::get_last_error() const
{
#if defined(ENABLE_UVGRTP)
    // Return first non-empty error
    if (m_rtp_receiver) {
        std::string err = m_rtp_receiver->get_last_error();
        if (!err.empty()) return "RTP: " + err;
    }
#endif
    if (m_decoder) {
        std::string err = m_decoder->get_last_error();
        if (!err.empty()) return "Decoder: " + err;
    }
    return "";
}

void V4L2Pipeline::on_nal_received(const uint8_t* data, size_t size, int64_t timestamp_us)
{
    // Forward NAL unit to decoder
    if (m_decoder && m_running) {
        m_decoder->feed_nal_unit(data, size, timestamp_us);
    }
}

void V4L2Pipeline::on_frame_decoded(PlaceboFrame frame)
{
    // Push frame to queue (this will trigger render via waiter thread)
    if (m_running) {
        // First, check for any buffers returned by renderer and recycle them
        PlaceboFrame returned_frame;
        while (m_frame_queue.try_pop_returned(returned_frame)) {
            if (returned_frame.buffer_index != UINT32_MAX && m_decoder) {
                m_decoder->recycle_buffer(returned_frame.buffer_index);
            }
        }

        // Now push the new decoded frame
        m_frame_queue.push(frame);
    }
    // Note: if not running, V4L2 will handle buffer cleanup when stopping
}

void V4L2Pipeline::on_decoder_capabilities(const V4L2Decoder::Capabilities& caps)
{
    qInfo() << "V4L2Pipeline: decoder capabilities:"
            << caps.width << "x" << caps.height
            << "pixel_format:" << Qt::hex << caps.pixel_format
            << "planes:" << caps.plane_count;

    // Update frame format for renderer
    m_frame_format.width = caps.width;
    m_frame_format.height = caps.height;
    m_frame_format.pixel_format = caps.pixel_format;
    m_frame_format.plane_count = caps.plane_count;
    m_frame_format.colorspace = caps.colorspace;
    m_frame_format.ycbcr_enc = caps.ycbcr_enc;
    m_frame_format.quantization = caps.quantization;
    m_frame_format.xfer_func = caps.xfer_func;

    m_format_ready = true;
}

#endif // ENABLE_V4L2_GL_PLAYER
