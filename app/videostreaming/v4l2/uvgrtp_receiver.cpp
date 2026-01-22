#include "uvgrtp_receiver.h"

#include <QDebug>


UvgRtpReceiver::UvgRtpReceiver()
{
    qDebug() << "UvgRtpReceiver: created";
}

UvgRtpReceiver::~UvgRtpReceiver()
{
    stop();
    qDebug() << "UvgRtpReceiver: destroyed";
}

bool UvgRtpReceiver::init(const std::string& local_addr, uint16_t local_port, Codec codec)
{
    if (initialized_.load()) {
        last_error_ = "Already initialized";
        return false;
    }

    local_addr_ = local_addr;
    local_port_ = local_port;
    codec_ = codec;

    qInfo() << "UvgRtpReceiver: initializing on" << local_addr.c_str() << ":" << local_port
            << "codec:" << (codec == Codec::H264 ? "H264" : "H265");

    // Create uvgRTP context
    ctx_ = std::make_unique<uvgrtp::context>();

    // Create session (local address, local address for receive-only)
    session_ = std::unique_ptr<uvgrtp::session>(
        ctx_->create_session(local_addr_)
    );

    if (!session_) {
        last_error_ = "Failed to create uvgRTP session";
        qCritical() << "UvgRtpReceiver:" << last_error_.c_str();
        return false;
    }

    // Determine RTP format based on codec
    rtp_format_t format = (codec_ == Codec::H264) ? RTP_FORMAT_H264 : RTP_FORMAT_H265;

    // Create media stream with receive-only and generic fragmentation flags
    // RCE_RECEIVE_ONLY: Only receive, don't set up sender
    // RCE_FRAGMENT_GENERIC: Automatic defragmentation of FU-A/FU-B
    int flags = RCE_RECEIVE_ONLY | RCE_FRAGMENT_GENERIC;

    stream_ = session_->create_stream(
        local_port_,
        format,
        flags
    );

    if (!stream_) {
        last_error_ = "Failed to create uvgRTP media stream";
        qCritical() << "UvgRtpReceiver:" << last_error_.c_str();
        session_.reset();
        return false;
    }

    // Install frame receive hook
    if (stream_->install_receive_hook(this, frameReceiveHook) != RTP_OK) {
        last_error_ = "Failed to install receive hook";
        qCritical() << "UvgRtpReceiver:" << last_error_.c_str();
        session_->destroy_stream(stream_);
        stream_ = nullptr;
        session_.reset();
        return false;
    }

    initialized_ = true;
    qInfo() << "UvgRtpReceiver: initialized successfully";
    return true;
}

void UvgRtpReceiver::set_nal_callback(NalCallback callback)
{
    std::lock_guard<std::mutex> lock(callback_mutex_);
    nal_callback_ = std::move(callback);
}

bool UvgRtpReceiver::start()
{
    if (!initialized_.load()) {
        last_error_ = "Not initialized";
        return false;
    }

    if (running_.load()) {
        return true;  // Already running
    }

    qInfo() << "UvgRtpReceiver: starting...";

    // uvgRTP automatically starts receiving after stream creation
    // Just mark as running
    running_ = true;

    qInfo() << "UvgRtpReceiver: started, listening on port" << local_port_;
    return true;
}

void UvgRtpReceiver::stop()
{
    if (!running_.load() && !initialized_.load()) {
        return;
    }

    qInfo() << "UvgRtpReceiver: stopping...";

    running_ = false;

    // Destroy stream
    if (stream_ && session_) {
        session_->destroy_stream(stream_);
        stream_ = nullptr;
    }

    // Destroy session
    session_.reset();

    // Context cleanup
    ctx_.reset();

    initialized_ = false;

    qInfo() << "UvgRtpReceiver: stopped";
}

UvgRtpReceiver::Stats UvgRtpReceiver::get_stats() const
{
    std::lock_guard<std::mutex> lock(stats_mutex_);
    return stats_;
}

void UvgRtpReceiver::reset_stats()
{
    std::lock_guard<std::mutex> lock(stats_mutex_);
    stats_ = Stats();
    first_rtp_ts_set_ = false;
}

void UvgRtpReceiver::frameReceiveHook(void* arg, uvgrtp::frame::rtp_frame* frame)
{
    if (!arg || !frame) {
        if (frame) {
            uvgrtp::frame::dealloc_frame(frame);
        }
        return;
    }

    auto* receiver = static_cast<UvgRtpReceiver*>(arg);
    receiver->processFrame(frame);
}

void UvgRtpReceiver::processFrame(uvgrtp::frame::rtp_frame* frame)
{
    if (!running_.load() || !frame || !frame->payload || frame->payload_len == 0) {
        if (frame) {
            uvgrtp::frame::dealloc_frame(frame);
        }
        return;
    }

    // Update statistics
    {
        std::lock_guard<std::mutex> lock(stats_mutex_);
        stats_.packets_received++;
        stats_.bytes_received += frame->payload_len;
    }

    // Calculate timestamp in microseconds
    // RTP timestamp is in 90kHz clock units for video
    int64_t timestamp_us = 0;
    auto now = std::chrono::steady_clock::now();

    if (!first_rtp_ts_set_) {
        first_rtp_ts_ = frame->header.timestamp;
        first_recv_time_ = now;
        first_rtp_ts_set_ = true;
    }

    // Convert RTP timestamp delta to microseconds (90kHz -> us)
    uint32_t rtp_delta = frame->header.timestamp - first_rtp_ts_;
    timestamp_us = static_cast<int64_t>(rtp_delta) * 1000000 / 90000;

    // Deliver NAL unit via callback
    {
        std::lock_guard<std::mutex> lock(callback_mutex_);
        if (nal_callback_) {
            nal_callback_(frame->payload, frame->payload_len, timestamp_us);

            std::lock_guard<std::mutex> stats_lock(stats_mutex_);
            stats_.nals_delivered++;
        }
    }

    // Free frame
    uvgrtp::frame::dealloc_frame(frame);
}
