// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef V4L2_DECODER_H
#define V4L2_DECODER_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include "dma_heap.h"
#include "dma_buffers_manager.h"
#include "../libplacebo/placebo_frame_queue.h"

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>


/**
 * @brief V4L2 Memory-to-Memory (M2M) hardware video decoder.
 *
 * This class implements V4L2 M2M video decoding using DMA-BUF buffers
 * for zero-copy operation. Decoded frames are output as PlaceboFrame
 * structures suitable for rendering with libplacebo.
 *
 * Buffer model:
 * - INPUT (OUTPUT_MPLANE): H.264 NAL units → decoder
 * - CAPTURE (CAPTURE_MPLANE): Decoded YUV frames ← decoder
 * - All buffers use V4L2_MEMORY_DMABUF with externally allocated DMA-BUF
 *
 * Thread model:
 * - feed_nal_unit() is called from RTP receiver thread
 * - Internal decode loop handles V4L2 buffer management
 * - Frame callback is invoked from decode thread
 *
 * Based on RtpDrmPlayer reference implementation.
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
     * @brief Supported codecs.
     */
    enum class Codec {
        H264,
        H265
    };

    /**
     * @brief Decoder capabilities (reported after first frame).
     */
    struct Capabilities {
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t pixel_format = 0;      // V4L2_PIX_FMT_*
        uint32_t plane_count = 1;       // Default to 1, updated after SOURCE_CHANGE

        // V4L2 colorspace metadata
        uint32_t colorspace = 0;        // V4L2_COLORSPACE_*
        uint32_t ycbcr_enc = 0;         // V4L2_YCBCR_ENC_*
        uint32_t quantization = 0;      // V4L2_QUANTIZATION_*
        uint32_t xfer_func = 0;         // V4L2_XFER_FUNC_*
    };

    /**
     * @brief Decoder statistics.
     */
    struct Stats {
        uint64_t frames_decoded = 0;
        uint64_t frames_dropped = 0;
        uint64_t nals_received = 0;
        uint64_t decode_errors = 0;
    };

    /**
     * @brief Callback for decoded frames.
     * Called from decode thread when a frame is ready.
     */
    using FrameCallback = std::function<void(PlaceboFrame frame)>;

    /**
     * @brief Callback for capabilities change (resolution change, first frame).
     */
    using CapabilitiesCallback = std::function<void(const Capabilities& caps)>;

    /**
     * @brief Initialize decoder with V4L2 device path and codec.
     * @param device_path Path to V4L2 M2M device (e.g., /dev/video10)
     * @param codec Codec to decode
     * @return true on success
     */
    bool init(const std::string& device_path, Codec codec);

    /**
     * @brief Start decoding.
     * @return true on success
     */
    bool start();

    /**
     * @brief Stop decoding.
     */
    void stop();

    /**
     * @brief Feed a NAL unit to the decoder.
     * Can be called from any thread.
     * @param data NAL unit data (with start code)
     * @param size Size in bytes
     * @param timestamp_us Presentation timestamp in microseconds
     */
    void feed_nal_unit(const uint8_t* data, size_t size, int64_t timestamp_us);

    /**
     * @brief Recycle a buffer back to the decoder.
     * Called when renderer is done with a frame.
     * @param buffer_index The buffer index from PlaceboFrame
     */
    void recycle_buffer(uint32_t buffer_index);

    /**
     * @brief Set frame callback.
     */
    void set_frame_callback(FrameCallback callback);

    /**
     * @brief Set capabilities callback.
     */
    void set_capabilities_callback(CapabilitiesCallback callback);

    /**
     * @brief Get current capabilities.
     */
    const Capabilities& get_capabilities() const { return capabilities_; }

    /**
     * @brief Get statistics.
     */
    Stats get_stats() const;

    /**
     * @brief Reset statistics.
     */
    void reset_stats();

    /**
     * @brief Get last error message.
     */
    std::string get_last_error() const { return last_error_; }

    /**
     * @brief Check if decoder is running.
     */
    bool is_running() const { return running_.load(); }

private:
    // Configuration
    std::string device_path_;
    Codec codec_ = Codec::H264;

    // V4L2 device
    int fd_ = -1;

    // DMA-BUF allocator and buffer managers
    std::shared_ptr<DmaHeap> dma_heap_;
    std::unique_ptr<DmaBuffersManager> input_buffers_;
    std::unique_ptr<DmaBuffersManager> output_buffers_;

    // Capabilities (filled after SOURCE_CHANGE event)
    Capabilities capabilities_;

    // Plane info for output buffers
    uint32_t output_plane_sizes_[4] = {0};
    uint32_t output_plane_strides_[4] = {0};

    // Callbacks
    FrameCallback frame_callback_;
    CapabilitiesCallback capabilities_callback_;

    // Error handling
    std::string last_error_;

    // Decode thread
    std::thread decode_thread_;
    std::atomic<bool> running_{false};
    std::atomic<bool> stop_requested_{false};

    // NAL unit queue (from RTP thread to decode thread)
    struct NalUnit {
        std::vector<uint8_t> data;
        int64_t timestamp_us;
    };
    std::queue<NalUnit> nal_queue_;
    std::mutex nal_mutex_;
    std::condition_variable nal_cv_;

    // Buffer recycling queue
    std::queue<uint32_t> recycle_queue_;
    std::mutex recycle_mutex_;

    // Statistics
    std::atomic<uint64_t> frames_decoded_{0};
    std::atomic<uint64_t> frames_dropped_{0};
    std::atomic<uint64_t> nals_received_{0};
    std::atomic<uint64_t> decode_errors_{0};

    // Frame sequence counter
    uint64_t frame_sequence_ = 0;

    // Internal methods
    bool openDevice();
    void closeDevice();
    bool checkDmaBufSupport();
    bool setupInputFormat();
    bool setupInputBuffers();
    bool handleSourceChange();
    bool setupCaptureFormat();
    bool setupCaptureBuffers();
    bool startStreaming();
    bool stopStreaming();

    void decodeLoop();
    bool processNal(const NalUnit& nal);
    bool queueInputBuffer(int buffer_idx, const uint8_t* data, size_t size, int64_t timestamp_us);
    bool processOutputBuffer(uint32_t index);
    bool requeueOutputBuffer(uint32_t index);

    void setError(const std::string& error);
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // V4L2_DECODER_H
