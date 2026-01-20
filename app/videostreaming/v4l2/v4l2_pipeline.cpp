// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_pipeline.h"
#include "v4l2_decoder_detector.h"

#include <QDebug>


V4L2Pipeline::V4L2Pipeline(const Config& config, const V4L2DecoderDetector::DecoderInfo& decoder_info)
    : m_config(config)
{
    qDebug() << "V4L2Pipeline: creating with decoder" << decoder_info.device_path.c_str();

    qInfo() << "V4L2Pipeline: initializing...";
    qInfo() << "  RTP:" << config.rtp_listen_addr.c_str() << ":" << config.rtp_listen_port;
    qInfo() << "  Codec:" << (decoder_info.codec == V4L2Decoder::Codec::H264 ? "H264" : "H265");
    qInfo() << "  V4L2 device:" << decoder_info.device_path.c_str();
    qInfo() << "  Driver:" << decoder_info.driver_name.c_str();
    qInfo() << "  Type:" << (decoder_info.type == V4L2DecoderDetector::DecoderType::Stateless ? "Stateless" : "Stateful");
    if (!decoder_info.media_device_path.empty()) {
        qInfo() << "  Media device:" << decoder_info.media_device_path.c_str();
    }

    // Create components
    m_rtp_receiver = std::make_unique<UvgRtpReceiver>();
    m_decoder = std::make_unique<V4L2Decoder>();

    // Initialize RTP receiver
    UvgRtpReceiver::Codec rtp_codec = (decoder_info.codec == V4L2Decoder::Codec::H264)
        ? UvgRtpReceiver::Codec::H264
        : UvgRtpReceiver::Codec::H265;

    if (!m_rtp_receiver->init(config.rtp_listen_addr, config.rtp_listen_port, rtp_codec)) {
        qFatal("V4L2Pipeline: failed to init RTP receiver: %s",
               m_rtp_receiver->get_last_error().c_str());
    }

    // Initialize V4L2 decoder
    if (!m_decoder->init(decoder_info.device_path, decoder_info.codec)) {
        qFatal("V4L2Pipeline: failed to init decoder: %s",
               m_decoder->get_last_error().c_str());
    }

    // Wire up callbacks
    m_rtp_receiver->set_nal_callback([this](const uint8_t* data, size_t size, int64_t ts) {
        on_nal_received(data, size, ts);
    });

    m_decoder->set_frame_callback([this](PlaceboFrame frame) {
        on_frame_decoded(std::move(frame));
    });

    m_decoder->set_capabilities_callback([this](const V4L2Decoder::Capabilities& caps) {
        on_decoder_capabilities(caps);
    });

    m_initialized = true;
    qInfo() << "V4L2Pipeline: initialized successfully";
}

V4L2Pipeline::~V4L2Pipeline()
{
    stop();
    qDebug() << "V4L2Pipeline: destroyed";
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

    // Start RTP receiver
    if (!m_rtp_receiver->start()) {
        qCritical() << "V4L2Pipeline: failed to start RTP receiver";
        m_decoder->stop();
        return false;
   }

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

    // Stop RTP receiver (stop incoming data)
    if (m_rtp_receiver) {
        m_rtp_receiver->stop();
    }

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

    if (m_rtp_receiver) {
        stats.rtp = m_rtp_receiver->get_stats();
    }

    if (m_decoder) {
        stats.decoder = m_decoder->get_stats();
    }
    stats.queue = m_frame_queue.get_stats();

    return stats;
}

void V4L2Pipeline::reset_stats()
{
    if (m_rtp_receiver) {
        m_rtp_receiver->reset_stats();
    }
    if (m_decoder) {
        m_decoder->reset_stats();
    }
    m_frame_queue.reset_stats();
}

std::string V4L2Pipeline::get_last_error() const
{
    // Return first non-empty error
    if (m_rtp_receiver) {
        std::string err = m_rtp_receiver->get_last_error();
        if (!err.empty()) return "RTP: " + err;
    }

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
