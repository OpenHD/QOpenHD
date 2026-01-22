#ifndef UVGRTP_RECEIVER_H
#define UVGRTP_RECEIVER_H

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <mutex>
#include <vector>
#include <chrono>

#include <uvgrtp/lib.hh>
#include <uvgrtp/frame.hh>


/**
 * @brief RTP receiver using uvgRTP library with automatic defragmentation.
 *
 * uvgRTP with RCE_FRAGMENT_GENERIC flag automatically handles:
 * - H.264/H.265 fragmentation unit reassembly
 * - RTP packet reordering
 * - Complete NAL unit delivery
 *
 * Thread model:
 * - Reception runs in uvgRTP's internal thread
 * - NAL callback is invoked from uvgRTP thread with complete NAL units
 *
 * Based on RtpDrmPlayer reference implementation.
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
     * @brief Supported codecs.
     */
    enum class Codec {
        H264,
        H265
    };

    /**
     * @brief Callback for received NAL units.
     * Called from uvgRTP thread when a complete NAL is received.
     * Parameters: data pointer, size, timestamp in microseconds
     */
    using NalCallback = std::function<void(const uint8_t* data, size_t size, int64_t timestamp_us)>;

    /**
     * @brief Reception statistics.
     */
    struct Stats {
        uint64_t packets_received = 0;
        uint64_t bytes_received = 0;
        uint64_t nals_delivered = 0;
        uint64_t packets_lost = 0;
    };

    /**
     * @brief Initialize the receiver.
     * @param local_addr Local IP address to bind (e.g., "0.0.0.0")
     * @param local_port Local UDP port for RTP reception
     * @param codec Codec type (H264 or H265)
     * @return true on success
     */
    bool init(const std::string& local_addr, uint16_t local_port, Codec codec);

    /**
     * @brief Set callback for received NAL units.
     */
    void set_nal_callback(NalCallback callback);

    /**
     * @brief Start receiving.
     * @return true on success
     */
    bool start();

    /**
     * @brief Stop receiving.
     */
    void stop();

    /**
     * @brief Check if receiver is running.
     */
    bool is_running() const { return running_.load(); }

    /**
     * @brief Get current statistics.
     */
    Stats get_stats() const;

    /**
     * @brief Reset statistics counters.
     */
    void reset_stats();

    /**
     * @brief Get last error message.
     */
    std::string get_last_error() const { return last_error_; }

private:
    // uvgRTP frame receive hook (static for C callback interface)
    static void frameReceiveHook(void* arg, uvgrtp::frame::rtp_frame* frame);
    void processFrame(uvgrtp::frame::rtp_frame* frame);

    // uvgRTP objects
    std::unique_ptr<uvgrtp::context> ctx_;
    std::unique_ptr<uvgrtp::session> session_;
    uvgrtp::media_stream* stream_ = nullptr;

    // Configuration
    std::string local_addr_;
    uint16_t local_port_ = 0;
    Codec codec_ = Codec::H264;

    // State
    std::atomic<bool> running_{false};
    std::atomic<bool> initialized_{false};
    std::string last_error_;

    // Callback for complete NAL units
    NalCallback nal_callback_;
    std::mutex callback_mutex_;

    // Statistics
    mutable std::mutex stats_mutex_;
    Stats stats_;

    // RTP timestamp tracking for converting to microseconds
    uint32_t first_rtp_ts_ = 0;
    bool first_rtp_ts_set_ = false;
    std::chrono::steady_clock::time_point first_recv_time_;
};

#endif // UVGRTP_RECEIVER_H
