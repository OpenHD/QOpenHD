// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef UVGRTP_RECEIVER_H
#define UVGRTP_RECEIVER_H

#if defined(ENABLE_V4L2_GL_PLAYER) && defined(ENABLE_UVGRTP)

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <thread>
#include <mutex>

#include <uvgrtp/lib.hh>
#include <uvgrtp/frame.hh>

/**
 * @brief RTP receiver using uvgRTP library for H.264/H.265 video streams.
 *
 * This class receives RTP packets over UDP and reassembles them into
 * complete NAL units, which are then passed to the decoder via callback.
 *
 * uvgRTP handles:
 * - RTP packet reception and parsing
 * - H.264/H.265 fragmentation unit (FU-A) reassembly
 * - Packet reordering within reasonable bounds
 *
 * Thread model:
 * - Reception runs in uvgRTP's internal thread
 * - NAL callback is invoked from uvgRTP thread
 */
class UvgRtpReceiver
{
public:
    UvgRtpReceiver();
    ~UvgRtpReceiver();

    // Non-copyable
    UvgRtpReceiver(const UvgRtpReceiver&) = delete;
    UvgRtpReceiver& operator=(const UvgRtpReceiver&) = delete;

    /**
     * @brief Video codec type
     */
    enum class Codec {
        H264,
        H265
    };

    /**
     * @brief Callback for received NAL units
     * Called from uvgRTP thread when a complete NAL unit is received.
     * @param data NAL unit data (without start code)
     * @param size Size in bytes
     * @param timestamp_us RTP timestamp converted to microseconds
     */
    using NalCallback = std::function<void(const uint8_t* data, size_t size, int64_t timestamp_us)>;

    /**
     * @brief Set NAL unit received callback
     */
    void set_nal_callback(NalCallback callback);

    /**
     * @brief Initialize receiver
     * @param local_addr Local IP address to bind to (e.g., "0.0.0.0")
     * @param local_port Local UDP port for RTP reception
     * @param codec Expected video codec
     * @return true on success
     */
    bool init(const std::string& local_addr, uint16_t local_port, Codec codec);

    /**
     * @brief Start receiving
     * @return true on success
     */
    bool start();

    /**
     * @brief Stop receiving
     */
    void stop();

    /**
     * @brief Check if receiver is running
     */
    bool is_running() const { return m_running.load(); }

    /**
     * @brief Get reception statistics
     */
    struct Stats {
        uint64_t rtp_packets_received = 0;
        uint64_t nal_units_received = 0;
        uint64_t bytes_received = 0;
        uint64_t packets_lost = 0;
    };
    Stats get_stats() const;

    /**
     * @brief Reset statistics
     */
    void reset_stats();

    /**
     * @brief Get last error message
     */
    std::string get_last_error() const;

private:
    // uvgRTP objects
    std::unique_ptr<uvgrtp::context> m_ctx;
    uvgrtp::session* m_session = nullptr;
    uvgrtp::media_stream* m_stream = nullptr;

    // Configuration
    std::string m_local_addr;
    uint16_t m_local_port = 0;
    Codec m_codec = Codec::H264;

    // Callback
    NalCallback m_nal_callback;

    // State
    std::atomic<bool> m_running{false};

    // Statistics
    std::atomic<uint64_t> m_rtp_packets{0};
    std::atomic<uint64_t> m_nal_units{0};
    std::atomic<uint64_t> m_bytes{0};
    std::atomic<uint64_t> m_lost{0};

    // Error
    mutable std::mutex m_error_mutex;
    std::string m_last_error;

    void set_error(const std::string& error);

    // uvgRTP frame receive callback (static for C callback interface)
    static void rtp_receive_hook(void* arg, uvgrtp::frame::rtp_frame* frame);
    void handle_rtp_frame(uvgrtp::frame::rtp_frame* frame);
};

#endif // ENABLE_V4L2_GL_PLAYER && ENABLE_UVGRTP

#endif // UVGRTP_RECEIVER_H
