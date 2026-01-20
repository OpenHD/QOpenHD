// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef PLACEBO_FRAME_QUEUE_H
#define PLACEBO_FRAME_QUEUE_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <cstdint>
#include <mutex>
#include <condition_variable>
#include <deque>
#include <atomic>

/**
 * @brief Represents a decoded video frame with DMA-BUF file descriptors.
 *
 * This is a simple POD-like wrapper for passing DMA-BUF references between
 * V4L2 decoder and libplacebo renderer. PlaceboFrame does NOT manage the
 * lifecycle of DMA-BUF file descriptors - that responsibility belongs to
 * V4L2Decoder which owns the actual buffers.
 *
 * For each V4L2 CAPTURE buffer there should be exactly one PlaceboFrame
 * instance circulating in the system at any time.
 */
struct PlaceboFrame {
    // V4L2 buffer index for recycling back to decoder
    uint32_t buffer_index = UINT32_MAX;

    // Frame dimensions
    uint32_t width = 0;
    uint32_t height = 0;

    // DRM format fourcc (e.g., DRM_FORMAT_NV12)
    uint32_t drm_fourcc = 0;

    // Number of planes (1-4 depending on format)
    uint32_t plane_count = 0;

    // Per-plane information
    struct Plane {
        int fd = -1;            // DMA-BUF file descriptor (not owned)
        uint32_t offset = 0;    // Offset within the buffer
        uint32_t pitch = 0;     // Stride in bytes
        uint32_t size = 0;      // Size in bytes
    };
    Plane planes[4];

    // DRM modifier (linear, tiled, etc.)
    uint64_t drm_modifier = 0;

    // Timestamp for statistics
    int64_t timestamp_us = 0;

    // Frame sequence number for debugging
    uint64_t sequence = 0;

    /**
     * @brief Check if frame contains valid data
     */
    bool is_valid() const {
        return buffer_index != UINT32_MAX &&
               width > 0 && height > 0 && drm_fourcc != 0 &&
               plane_count > 0 && planes[0].fd >= 0;
    }
};


/**
 * @brief Thread-safe bidirectional frame queue for V4L2 ↔ Renderer communication.
 *
 * Contains two FIFO queues:
 * - from_decoder: decoded frames waiting to be rendered
 * - to_decoder: rendered frames ready to be recycled back to V4L2
 *
 * Thread model:
 * - Decoder thread: push to from_decoder, pop from to_decoder
 * - Waiter thread: wait on from_decoder (blocking)
 * - Render thread: try_pop from from_decoder, push to to_decoder
 *
 * The waiter thread uses condition variable to block until frames are available,
 * then signals Qt to trigger rendering. This provides low-latency notification
 * without busy-polling.
 */
class PlaceboFrameQueue
{
public:
    PlaceboFrameQueue();
    ~PlaceboFrameQueue();

    // Non-copyable
    PlaceboFrameQueue(const PlaceboFrameQueue&) = delete;
    PlaceboFrameQueue& operator=(const PlaceboFrameQueue&) = delete;

    // ==================== from_decoder queue ====================

    /**
     * @brief Push decoded frame to renderer (called from decoder thread)
     * Wakes up any thread waiting in wait_frame().
     */
    void push(PlaceboFrame frame);

    /**
     * @brief Try to pop a frame for rendering (non-blocking)
     * @param[out] frame Filled with frame data if available
     * @return true if frame was retrieved, false if queue empty
     */
    bool try_pop(PlaceboFrame& frame);

    /**
     * @brief Pop all available frames (non-blocking)
     * @return Vector of all frames currently in from_decoder queue
     */
    std::vector<PlaceboFrame> pop_all();

    /**
     * @brief Block until a frame is available or stop() is called
     * @return true if frame available, false if stopped
     */
    bool wait_frame();

    /**
     * @brief Get number of frames waiting to be rendered
     */
    size_t from_decoder_size() const;

    // ==================== to_decoder queue ====================

    /**
     * @brief Return rendered frame for recycling (called from render thread)
     */
    void return_buffer(PlaceboFrame frame);

    /**
     * @brief Try to get a frame to recycle (called from decoder thread)
     * @param[out] frame Filled with frame data if available
     * @return true if frame was retrieved, false if queue empty
     */
    bool try_pop_returned(PlaceboFrame& frame);

    /**
     * @brief Get number of frames waiting to be recycled
     */
    size_t to_decoder_size() const;

    // ==================== Control ====================

    /**
     * @brief Stop the queue, unblocking any waiting threads
     */
    void stop();

    /**
     * @brief Check if queue is stopped
     */
    bool is_stopped() const;

    /**
     * @brief Reset queue to running state (clears stop flag)
     */
    void reset();

    // ==================== Statistics ====================

    struct Stats {
        uint64_t frames_decoded = 0;    // Pushed to from_decoder
        uint64_t frames_rendered = 0;   // Popped from from_decoder
        uint64_t frames_returned = 0;   // Pushed to to_decoder
        uint64_t frames_recycled = 0;   // Popped from to_decoder
    };
    Stats get_stats() const;
    void reset_stats();

private:
    // from_decoder queue (decoder → renderer)
    mutable std::mutex m_from_mutex;
    std::condition_variable m_from_cv;
    std::deque<PlaceboFrame> m_from_decoder;

    // to_decoder queue (renderer → decoder)
    mutable std::mutex m_to_mutex;
    std::deque<PlaceboFrame> m_to_decoder;

    // Control
    std::atomic<bool> m_stopped{false};

    // Statistics
    std::atomic<uint64_t> m_frames_decoded{0};
    std::atomic<uint64_t> m_frames_rendered{0};
    std::atomic<uint64_t> m_frames_returned{0};
    std::atomic<uint64_t> m_frames_recycled{0};
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // PLACEBO_FRAME_QUEUE_H
