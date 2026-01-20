// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#if defined(ENABLE_V4L2_GL_PLAYER) && defined(ENABLE_UVGRTP)

#include "uvgrtp_receiver.h"

#include <QDebug>
#include <chrono>

#include <uvgrtp/lib.hh>
#include <uvgrtp/frame.hh>


UvgRtpReceiver::UvgRtpReceiver()
{
    qDebug() << "UvgRtpReceiver: created";
}

UvgRtpReceiver::~UvgRtpReceiver()
{
    stop();
    qDebug() << "UvgRtpReceiver: destroyed";
}

void UvgRtpReceiver::set_nal_callback(NalCallback callback)
{
    m_nal_callback = std::move(callback);
}

bool UvgRtpReceiver::init(const std::string& local_addr, uint16_t local_port, Codec codec)
{
    if (m_running) {
        set_error("Receiver already running");
        return false;
    }

    m_local_addr = local_addr;
    m_local_port = local_port;
    m_codec = codec;

    qInfo() << "UvgRtpReceiver: initializing on" << local_addr.c_str() << ":" << local_port
            << "codec:" << (codec == Codec::H264 ? "H264" : "H265");

    // Create uvgRTP context
    m_ctx = std::make_unique<uvgrtp::context>();

    // Create session (receiver only, so remote addr/port are not meaningful)
    // Using localhost as remote since we're only receiving
    m_session = m_ctx->create_session(local_addr);
    if (!m_session) {
        set_error("Failed to create uvgRTP session");
        return false;
    }

    qInfo() << "UvgRtpReceiver: initialized successfully";
    return true;
}

bool UvgRtpReceiver::start()
{
    if (m_running) {
        qWarning() << "UvgRtpReceiver: already running";
        return true;
    }

    if (!m_session) {
        set_error("Session not initialized");
        return false;
    }

    // Determine RTP format based on codec
    rtp_format_t rtp_format = (m_codec == Codec::H264) ? RTP_FORMAT_H264 : RTP_FORMAT_H265;

    // Create media stream for receiving
    // Flags: RCE_RECEIVE_ONLY - we're only receiving, not sending
    int flags = RCE_RECEIVE_ONLY;

    m_stream = m_session->create_stream(m_local_port, rtp_format, flags);
    if (!m_stream) {
        set_error("Failed to create media stream");
        return false;
    }

    // Install receive hook
    if (m_stream->install_receive_hook(this, rtp_receive_hook) != RTP_OK) {
        set_error("Failed to install receive hook");
        m_session->destroy_stream(m_stream);
        m_stream = nullptr;
        return false;
    }

    m_running = true;
    qInfo() << "UvgRtpReceiver: started";
    return true;
}

void UvgRtpReceiver::stop()
{
    if (!m_running) return;

    qInfo() << "UvgRtpReceiver: stopping...";

    if (m_stream && m_session) {
        m_session->destroy_stream(m_stream);
        m_stream = nullptr;
    }

    if (m_session && m_ctx) {
        m_ctx->destroy_session(m_session);
        m_session = nullptr;
    }

    m_running = false;
    qInfo() << "UvgRtpReceiver: stopped";
}

UvgRtpReceiver::Stats UvgRtpReceiver::get_stats() const
{
    return Stats{
        m_rtp_packets.load(),
        m_nal_units.load(),
        m_bytes.load(),
        m_lost.load()
    };
}

void UvgRtpReceiver::reset_stats()
{
    m_rtp_packets = 0;
    m_nal_units = 0;
    m_bytes = 0;
    m_lost = 0;
}

std::string UvgRtpReceiver::get_last_error() const
{
    std::lock_guard<std::mutex> lock(m_error_mutex);
    return m_last_error;
}

void UvgRtpReceiver::set_error(const std::string& error)
{
    std::lock_guard<std::mutex> lock(m_error_mutex);
    m_last_error = error;
    qWarning() << "UvgRtpReceiver error:" << error.c_str();
}

void UvgRtpReceiver::rtp_receive_hook(void* arg, uvgrtp::frame::rtp_frame* frame)
{
    if (!arg || !frame) return;

    auto* self = static_cast<UvgRtpReceiver*>(arg);
    self->handle_rtp_frame(frame);
}

void UvgRtpReceiver::handle_rtp_frame(uvgrtp::frame::rtp_frame* frame)
{
    if (!frame || !frame->payload || frame->payload_len == 0) {
        return;
    }

    m_rtp_packets++;
    m_bytes += frame->payload_len;
    m_nal_units++;

    // Convert RTP timestamp to microseconds
    // RTP timestamp is typically 90kHz for video
    // Note: This is a simplified conversion, proper implementation should
    // handle timestamp wraparound and initial offset
    int64_t timestamp_us = (int64_t)frame->header.timestamp * 1000000 / 90000;

    // Use current time if timestamp conversion seems off
    // (for low-latency streaming, current time might be more accurate)
    auto now = std::chrono::steady_clock::now();
    auto now_us = std::chrono::duration_cast<std::chrono::microseconds>(
        now.time_since_epoch()).count();

    // Invoke callback with NAL unit data
    if (m_nal_callback) {
        m_nal_callback(frame->payload, frame->payload_len, now_us);
    }

    // Free the frame (uvgRTP requires this)
    uvgrtp::frame::dealloc_frame(frame);
}

#endif // ENABLE_V4L2_GL_PLAYER && ENABLE_UVGRTP
