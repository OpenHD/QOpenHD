#ifndef V4L2_DECODER_H
#define V4L2_DECODER_H

#include "V4L2Device.h"
#include "DmaBuffersAllocator.h"
#include "DecodedDmaBuffersQueue.h"
#include "../libplacebo/placebo_frame_queue.h"

#include <gsl/span>
#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <atomic>
#include <thread>
#include <mutex>
#include <queue>

class V4L2H264StatefulDecoder
{
private:
    std::unique_ptr<V4L2Device> device_;
    std::unique_ptr<DmaBuffersAllocator> dmaBuffersAllocator_;
    uint32_t pixelFormat_ = 0;

public:
    ~V4L2H264StatefulDecoder();

    // Delete all copy and move operations for strict lifetime control
    V4L2H264StatefulDecoder(const V4L2H264StatefulDecoder&) = delete;
    V4L2H264StatefulDecoder& operator=(const V4L2H264StatefulDecoder&) = delete;
    V4L2H264StatefulDecoder(V4L2H264StatefulDecoder&&) = delete;
    V4L2H264StatefulDecoder& operator=(V4L2H264StatefulDecoder&&) = delete;

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
     * @brief Factory method to create decoder with V4L2 device and codec.
     * @param device V4L2 device (must be valid and open)
     * @return unique_ptr to decoder on success, nullptr on failure
     */
    static std::unique_ptr<V4L2H264StatefulDecoder> Create(std::unique_ptr<V4L2Device> device);

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
     * Blocks until data is written to V4L2 device.
     * @param data NAL unit data (with start code)
     */
    void feed_nal_unit(gsl::span<const uint8_t> data);

    /**
     * @brief Recycle a buffer back to the decoder.
     * Called when renderer is done with a frame.
     * @param buffer_index The buffer index from PlaceboFrame
     */
    void recycle_buffer(uint32_t buffer_index);

    /**
     * @brief Wait for next decoded frame (blocking).
     * @return DecodedFrame on success (check is_valid())
     */
    DecodedFrame wait_for_decoded_frame();

    /**
     * @brief Recycle a decoded buffer back to V4L2 device.
     * @param buffer_index The buffer index from DecodedFrame
     */
    void recycle_decoded_buffer(uint32_t buffer_index);

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
    V4L2H264StatefulDecoder(
        std::unique_ptr<V4L2Device> device,
        std::unique_ptr<DmaBuffersAllocator> dmaBuffersAllocator);

    void Init();
    void SubscribeToEvents();
    void ConfigureFormats();
    void SetupBuffers();

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

    // Buffer recycling queue
    std::queue<uint32_t> recycle_queue_;
    std::mutex recycle_mutex_;

    // Statistics
    std::atomic<uint64_t> frames_decoded_{0};
    std::atomic<uint64_t> frames_dropped_{0};
    std::atomic<uint64_t> decode_errors_{0};

    // Frame sequence counter
    uint64_t frame_sequence_ = 0;
};

#endif // V4L2_DECODER_H
