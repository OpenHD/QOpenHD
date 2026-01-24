#ifndef QOPENHDPROJECT_ENCODEDDMABUFFERSQUEUE_H
#define QOPENHDPROJECT_ENCODEDDMABUFFERSQUEUE_H

#include <cstdint>
#include <functional>
#include <memory>
#include <vector>
#include <gsl/span>

#include "DmaBuffer.h"

/**
 * @brief Manages a queue of DMA buffers for V4L2 VIDEO_OUTPUT_MPLANE operations.
 *
 * This class encapsulates the logic for working with encoded data buffers
 * that are sent to a V4L2 stateful decoder. It handles buffer registration,
 * state tracking (free/queued), and provides blocking writes with poll-based waiting.
 *
 * Thread safety: WaitWrite() is expected to be called sequentially from a single thread.
 */
class EncodedDmaBuffersQueue {
private:
    int fd_;
    std::function<uint32_t()> planesCountGetter_;
    std::vector<std::unique_ptr<DmaBuffer>> buffers_;
    std::vector<bool> inUse_;
    uint32_t planesCount_ = 0;

public:
    /**
     * @brief Constructs an EncodedDmaBuffersQueue.
     * @param fd File descriptor of the V4L2 device.
     * @param planesCountGetter Lambda that returns the number of planes for the buffer type.
     */
    EncodedDmaBuffersQueue(int fd, std::function<uint32_t()> planesCountGetter);

    EncodedDmaBuffersQueue(const EncodedDmaBuffersQueue&) = delete;
    EncodedDmaBuffersQueue& operator=(const EncodedDmaBuffersQueue&) = delete;
    EncodedDmaBuffersQueue(EncodedDmaBuffersQueue&&) = delete;
    EncodedDmaBuffersQueue& operator=(EncodedDmaBuffersQueue&&) = delete;

    ~EncodedDmaBuffersQueue() = default;

    /**
     * @brief Registers DMA buffers for use with the V4L2 device queue.
     *
     * Calls VIDIOC_REQBUFS to register the buffers with the device,
     * maps each buffer for CPU access, and initializes tracking state.
     *
     * @param buffers Vector of DmaBuffer unique_ptrs to register.
     * @throws std::runtime_error if VIDIOC_REQBUFS fails or buffer mapping fails.
     */
    void RegisterBuffers(std::vector<std::unique_ptr<DmaBuffer>> buffers);

    /**
     * @brief Writes data to a free buffer and queues it for decoding.
     *
     * This is a blocking method that waits indefinitely until a buffer
     * becomes available. It uses poll() with POLLOUT to wait for the device.
     *
     * @param data Span containing the encoded data to write.
     * @throws std::runtime_error if poll() fails, write fails, or VIDIOC_QBUF fails.
     */
    void WaitWrite(gsl::span<const uint8_t> data);

    /**
     * @brief Returns the number of registered buffers.
     */
    size_t GetBufferCount() const { return buffers_.size(); }
private:
    /**
     * @brief Attempts to dequeue completed buffers from the device.
     *
     * Non-blocking operation that dequeues all available buffers
     * and marks them as free in inUse_.
     */
    void TryDequeueCompletedBuffers();

    /**
     * @brief Finds the index of a free buffer.
     * @return Index of free buffer, or -1 if none available.
     */
    int FindFreeBufferIndex() const;
};

#endif //QOPENHDPROJECT_ENCODEDDMABUFFERSQUEUE_H