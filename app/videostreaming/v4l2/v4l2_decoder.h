// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef V4L2_DECODER_H
#define V4L2_DECODER_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <thread>
#include <mutex>
#include <queue>
#include <condition_variable>

#include "../libplacebo/placebo_frame_queue.h"

/**
 * @brief V4L2 Memory-to-Memory (M2M) hardware video decoder.
 *
 * This class provides a skeleton for V4L2 M2M video decoding, outputting
 * decoded frames as DMA-BUF file descriptors suitable for zero-copy rendering.
 *
 * Supported codecs (platform dependent):
 * - H.264 (AVC)
 * - H.265 (HEVC)
 *
 * Thread model:
 * - feed_nal_unit() can be called from any thread
 * - Internal decode thread handles V4L2 buffer management
 * - on_frame_decoded callback is invoked from decode thread
 *
 * TODO: Implement V4L2 M2M API calls
 */
class V4L2Decoder
{
public:
    V4L2Decoder();
    ~V4L2Decoder();

    // Non-copyable
    V4L2Decoder(const V4L2Decoder&) = delete;
    V4L2Decoder& operator=(const V4L2Decoder&) = delete;

    /**
     * @brief Video codec type
     */
    enum class Codec {
        H264,
        H265
    };

    /**
     * @brief Decoder capabilities / output format information
     * Populated after successful initialization with first frame decoded.
     */
    struct Capabilities {
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t output_fourcc = 0;     // DRM format (e.g., DRM_FORMAT_NV12)
        uint32_t plane_count = 0;
        uint32_t min_buffers = 0;       // Minimum capture buffers required
        bool supports_dmabuf = false;

        bool is_valid() const { return width > 0 && height > 0 && output_fourcc != 0; }
    };

    /**
     * @brief Callback for decoded frames
     * Called from decode thread when a frame is ready.
     * @param frame The decoded frame (caller should NOT close fds - queue will handle it)
     */
    using FrameCallback = std::function<void(PlaceboFrame frame)>;

    /**
     * @brief Callback for format/capabilities change
     * Called when decoder determines output format (after first frame).
     */
    using CapabilitiesCallback = std::function<void(const Capabilities& caps)>;

    /**
     * @brief Set frame decoded callback
     */
    void set_frame_callback(FrameCallback callback);

    /**
     * @brief Set capabilities change callback
     */
    void set_capabilities_callback(CapabilitiesCallback callback);

    /**
     * @brief Initialize decoder
     * @param device V4L2 device path (e.g., "/dev/video0")
     * @param codec Video codec to decode
     * @return true on success
     */
    bool init(const std::string& device, Codec codec);

    /**
     * @brief Start decoding
     * @return true on success
     */
    bool start();

    /**
     * @brief Stop decoding
     */
    void stop();

    /**
     * @brief Check if decoder is running
     */
    bool is_running() const { return m_running.load(); }

    /**
     * @brief Feed a NAL unit to decoder
     * Can be called from any thread. Data is copied internally.
     * @param data NAL unit data (including start code if present)
     * @param size Size in bytes
     * @param timestamp_us Presentation timestamp in microseconds
     */
    void feed_nal_unit(const uint8_t* data, size_t size, int64_t timestamp_us);

    /**
     * @brief Get current capabilities
     * Only valid after capabilities callback has been invoked.
     */
    const Capabilities& get_capabilities() const { return m_capabilities; }

    /**
     * @brief Get decoder statistics
     */
    struct Stats {
        uint64_t nal_units_received = 0;
        uint64_t frames_decoded = 0;
        uint64_t decode_errors = 0;
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

    /**
     * @brief Return a buffer to the decoder for reuse
     * Called when rendering is done with a frame.
     * @param buffer_index The buffer index from PlaceboFrame::buffer_index
     */
    void recycle_buffer(uint32_t buffer_index);

private:
    // V4L2 device
    int m_fd = -1;
    std::string m_device_path;
    Codec m_codec = Codec::H264;

    // Capabilities
    Capabilities m_capabilities;
    bool m_capabilities_valid = false;

    // Callbacks
    FrameCallback m_frame_callback;
    CapabilitiesCallback m_caps_callback;

    // State
    std::atomic<bool> m_running{false};
    std::atomic<bool> m_stop_requested{false};

    // Input buffer queue (NAL units waiting to be sent to decoder)
    struct NalUnit {
        std::vector<uint8_t> data;
        int64_t timestamp_us;
    };
    std::queue<NalUnit> m_input_queue;
    std::mutex m_input_mutex;
    std::condition_variable m_input_cv;

    // Decode thread
    std::unique_ptr<std::thread> m_decode_thread;

    // Statistics
    std::atomic<uint64_t> m_nal_units_received{0};
    std::atomic<uint64_t> m_frames_decoded{0};
    std::atomic<uint64_t> m_decode_errors{0};

    // Error
    mutable std::mutex m_error_mutex;
    std::string m_last_error;

    // Internal methods
    void decode_thread_func();
    bool open_device();
    void close_device();
    bool setup_output_format();   // Set input format (compressed)
    bool setup_capture_format();  // Set output format (raw)
    bool allocate_buffers();
    void free_buffers();
    bool stream_on();
    void stream_off();
    bool queue_input_buffer(const NalUnit& nal);
    bool dequeue_output_frame(PlaceboFrame& frame);
    void set_error(const std::string& error);

    // V4L2 buffer management
    // TODO: Add buffer structures when implementing
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // V4L2_DECODER_H
