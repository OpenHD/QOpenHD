// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef DMA_BUFFERS_MANAGER_H
#define DMA_BUFFERS_MANAGER_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include "dma_heap.h"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

#include <linux/videodev2.h>


/**
 * @brief Manages a pool of DMA-BUF buffers for V4L2 M2M decoder.
 *
 * Handles:
 * - Buffer allocation via DmaHeap
 * - Buffer mapping for CPU access
 * - V4L2 REQBUFS registration
 * - Buffer state tracking (in_use/free)
 * - Round-robin buffer selection
 *
 * Used for both INPUT (OUTPUT_MPLANE) and CAPTURE (CAPTURE_MPLANE) queues.
 */
class DmaBuffersManager {
public:
    /**
     * @brief Construct buffer manager.
     * @param heap DMA heap allocator (shared, must outlive this object)
     * @param count Number of buffers to manage
     * @param type V4L2 buffer type (OUTPUT_MPLANE or CAPTURE_MPLANE)
     */
    DmaBuffersManager(std::shared_ptr<DmaHeap> heap, size_t count, v4l2_buf_type type);
    ~DmaBuffersManager();

    // Non-copyable
    DmaBuffersManager(const DmaBuffersManager&) = delete;
    DmaBuffersManager& operator=(const DmaBuffersManager&) = delete;

    /**
     * @brief Allocate and map all buffers.
     * @param buffer_size Size of each buffer in bytes
     * @return true on success
     */
    bool allocate(size_t buffer_size);

    /**
     * @brief Deallocate all buffers.
     */
    void deallocate();

    /**
     * @brief Request buffers on V4L2 device (VIDIOC_REQBUFS).
     * @param fd V4L2 device file descriptor
     * @return true on success
     */
    bool requestOnDevice(int fd);

    /**
     * @brief Release buffers from V4L2 device (VIDIOC_REQBUFS with count=0).
     * @param fd V4L2 device file descriptor
     * @return true on success
     */
    bool releaseOnDevice(int fd);

    /**
     * @brief Get number of buffers.
     */
    size_t count() const { return count_; }

    /**
     * @brief Get buffer info by index.
     * @param index Buffer index (0 to count-1)
     * @return Buffer info (fd, mapped_addr, size)
     */
    const DmaBufInfo& getInfo(size_t index) const;
    DmaBufInfo& getInfo(size_t index);

    /**
     * @brief Get index of a free buffer (round-robin).
     * @return Buffer index, or -1 if no free buffers
     */
    int getFreeBufferIndex();

    /**
     * @brief Mark buffer as in-use (queued to V4L2).
     * @param index Buffer index
     */
    void markInUse(size_t index);

    /**
     * @brief Mark buffer as free (dequeued from V4L2).
     * @param index Buffer index
     */
    void markFree(size_t index);

    /**
     * @brief Reset all buffers to free state.
     */
    void resetUsage();

    /**
     * @brief Get V4L2 buffer type.
     */
    v4l2_buf_type bufferType() const { return type_; }

private:
    std::shared_ptr<DmaHeap> heap_;
    std::vector<DmaBufInfo> buffers_;
    const size_t count_;
    const v4l2_buf_type type_;
    std::vector<bool> in_use_;
    size_t current_buffer_ = 0;
    mutable std::mutex mutex_;  // Protects in_use_ and current_buffer_
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // DMA_BUFFERS_MANAGER_H
