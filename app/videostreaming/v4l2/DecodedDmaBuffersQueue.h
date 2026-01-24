#ifndef QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H
#define QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H

#include <cstdint>
#include <functional>
#include <memory>
#include <vector>

#include "DmaBuffer.h"

/**
 * @brief Lightweight view of a decoded frame from V4L2 CAPTURE queue.
 *
 * Does NOT own the DMA-BUF file descriptors - they are owned by
 * DecodedDmaBuffersQueue. This struct is used to pass frame data
 * to the presenter/renderer.
 */
struct DecodedFrame {
    static constexpr uint32_t INVALID_INDEX = UINT32_MAX;
    static constexpr uint32_t MAX_PLANES = 4;

    /// V4L2 buffer index for recycling back to decoder
    uint32_t buffer_index = INVALID_INDEX;

    /// Number of planes in this frame
    uint32_t planes_count = 0;

    /// Per-plane information
    struct Plane {
        int fd = -1;              ///< DMA-BUF file descriptor (not owned)
        uint32_t offset = 0;      ///< Offset within the buffer
        uint32_t bytesused = 0;   ///< Actual bytes used in this plane
        uint32_t length = 0;      ///< Total plane buffer size
    };
    Plane planes[MAX_PLANES];

    /// Timestamp from V4L2 buffer (microseconds)
    int64_t timestamp_us = 0;

    /// Check if frame contains valid data
    bool is_valid() const {
        return buffer_index != INVALID_INDEX &&
               planes_count > 0 &&
               planes[0].fd >= 0;
    }
};

/**
 * @brief Manages a queue of DMA buffers for V4L2 VIDEO_CAPTURE_MPLANE operations.
 *
 * This class encapsulates the logic for working with decoded frame buffers
 * received from a V4L2 stateful decoder. It handles buffer registration,
 * state tracking, blocking waits for decoded frames, and buffer recycling.
 *
 * Thread safety: All methods are expected to be called sequentially from a single thread.
 */
class DecodedDmaBuffersQueue {
private:
    int fd_;
    std::function<uint32_t()> planesCountGetter_;
    std::vector<std::unique_ptr<DmaBuffer>> buffers_;
    std::vector<bool> inUse_;
    uint32_t planesCount_ = 0;

public:
    /**
     * @brief Constructs a DecodedDmaBuffersQueue.
     * @param fd File descriptor of the V4L2 device.
     * @param planesCountGetter Lambda that returns the number of planes for CAPTURE buffers.
     */
    DecodedDmaBuffersQueue(int fd, std::function<uint32_t()> planesCountGetter);

    DecodedDmaBuffersQueue(const DecodedDmaBuffersQueue&) = delete;
    DecodedDmaBuffersQueue& operator=(const DecodedDmaBuffersQueue&) = delete;
    DecodedDmaBuffersQueue(DecodedDmaBuffersQueue&&) = delete;
    DecodedDmaBuffersQueue& operator=(DecodedDmaBuffersQueue&&) = delete;

    ~DecodedDmaBuffersQueue() = default;

    /**
     * @brief Registers DMA buffers for use with the V4L2 device CAPTURE queue.
     *
     * Calls VIDIOC_REQBUFS to register the buffers with the device
     * and initializes tracking state. Buffers are NOT mapped since
     * the GPU will read them directly via DMA-BUF.
     *
     * @param buffers Vector of DmaBuffer unique_ptrs to register.
     * @throws std::runtime_error if VIDIOC_REQBUFS fails.
     */
    void RegisterBuffers(std::vector<std::unique_ptr<DmaBuffer>> buffers);

    /**
     * @brief Queues all registered buffers to the V4L2 device.
     *
     * Should be called after RegisterBuffers() and before starting
     * the decode loop to give the decoder buffers to write into.
     *
     * @throws std::runtime_error if VIDIOC_QBUF fails.
     */
    void QueueAllBuffers();

    /**
     * @brief Waits for and returns a decoded frame.
     *
     * Blocks indefinitely until a decoded frame is available using
     * poll() with POLLIN. Restarts on EINTR.
     *
     * @return DecodedFrame containing buffer information.
     * @throws std::runtime_error if poll() fails or VIDIOC_DQBUF fails.
     */
    DecodedFrame WaitForDecodedFrame();

    /**
     * @brief Returns a buffer to the V4L2 device for reuse.
     *
     * @param buffer_index Index of the buffer to recycle (from DecodedFrame::buffer_index).
     * @throws std::runtime_error if buffer_index is invalid or VIDIOC_QBUF fails.
     */
    void ReuseBuffer(uint32_t buffer_index);

    /**
     * @brief Returns the number of registered buffers.
     */
    size_t GetBufferCount() const { return buffers_.size(); }
};

#endif //QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H