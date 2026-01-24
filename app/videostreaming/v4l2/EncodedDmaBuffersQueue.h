#ifndef QOPENHDPROJECT_ENCODEDDMABUFFERSQUEUE_H
#define QOPENHDPROJECT_ENCODEDDMABUFFERSQUEUE_H

#include <gsl/span>

#include "DmaBuffersQueueBase.h"

/**
 * @brief Manages a queue of DMA buffers for V4L2 VIDEO_OUTPUT_MPLANE operations.
 *
 * This class encapsulates the logic for working with encoded data buffers
 * that are sent to a V4L2 stateful decoder. It handles buffer registration,
 * state tracking (free/queued), and provides blocking writes with poll-based waiting.
 *
 * Thread safety: WaitWrite() is expected to be called sequentially from a single thread.
 */
class EncodedDmaBuffersQueue : public DmaBuffersQueueBase {
public:
    /**
     * @brief Constructs an EncodedDmaBuffersQueue.
     * @param fd File descriptor of the V4L2 device.
     * @param planesCountGetter Lambda that returns the number of planes for the buffer type.
     */
    EncodedDmaBuffersQueue(int fd, std::function<uint32_t()> planesCountGetter);

    ~EncodedDmaBuffersQueue() override = default;

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