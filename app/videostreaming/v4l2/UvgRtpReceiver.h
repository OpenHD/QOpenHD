#ifndef UVGRTP_RECEIVER_H
#define UVGRTP_RECEIVER_H

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <mutex>

#include <uvgrtp/lib.hh>
#include <uvgrtp/frame.hh>
#include "../vscommon/VideoCodec.h"

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
 * - Frame callback is invoked from uvgRTP thread with complete frames
 * - Caller is responsible for frame deallocation via deallocate_frame()
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
     * @brief Callback for received RTP frames.
     * Called from uvgRTP thread when a complete frame is received.
     * Caller must deallocate frame via deallocate_frame() after processing.
     */
    using FrameCallback = std::function<void(uvgrtp::frame::rtp_frame* frame)>;

    /**
     * @brief Initialize the receiver.
     * @param local_addr Local IP address to bind (e.g., "0.0.0.0")
     * @param local_port Local UDP port for RTP reception
     * @param codec Codec type (H264 or H265)
     * @return true on success
     */
    bool init(const std::string& local_addr, uint16_t local_port, VideoCodec codec);

    /**
     * @brief Set callback for received frames.
     * Callback receives ownership of the frame and must call deallocate_frame().
     */
    void set_frame_callback(FrameCallback callback);

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
     * @brief Deallocate an RTP frame received via callback.
     * Must be called after processing each frame.
     */
    static void deallocate_frame(uvgrtp::frame::rtp_frame* frame);

    /**
     * @brief Get last error message.
     */
    std::string get_last_error() const { return last_error_; }

private:
    // uvgRTP frame receive hook (static for C callback interface)
    static void frameReceiveHook(void* arg, uvgrtp::frame::rtp_frame* frame);

    // uvgRTP objects
    std::unique_ptr<uvgrtp::context> ctx_;
    std::unique_ptr<uvgrtp::session> session_;
    uvgrtp::media_stream* stream_ = nullptr;

    // Configuration
    std::string local_addr_;
    uint16_t local_port_ = 0;
    VideoCodec codec_ = VideoCodec::H264;

    // State
    std::atomic<bool> running_{false};
    std::atomic<bool> initialized_{false};
    std::string last_error_;

    // Callback for received frames
    FrameCallback frame_callback_;
    std::mutex callback_mutex_;
};

#endif // UVGRTP_RECEIVER_H
