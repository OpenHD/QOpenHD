#ifndef QOPENHDPROJECT_DMABUFFERSQUEUEBASE_H
#define QOPENHDPROJECT_DMABUFFERSQUEUEBASE_H

#include <cstdint>
#include <functional>
#include <memory>
#include <vector>

#include <linux/videodev2.h>

#include "DmaBuffer.h"

/**
 * @brief Base class for V4L2 DMA buffer queue management.
 *
 * Provides common functionality for managing DMA buffers with V4L2 devices,
 * including buffer registration, streaming control, and state tracking.
 *
 * Thread safety: All methods are expected to be called sequentially from a single thread.
 */
class DmaBuffersQueueBase {
protected:
    int fd_;
    v4l2_buf_type bufferType_;
    std::function<uint32_t()> planesCountGetter_;
    std::vector<std::unique_ptr<DmaBuffer>> buffers_;
    std::vector<bool> inUse_;
    uint32_t planesCount_ = 0;

    /**
     * @brief Constructs a DmaBuffersQueueBase.
     * @param fd File descriptor of the V4L2 device.
     * @param bufferType V4L2 buffer type (e.g., V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE).
     * @param planesCountGetter Lambda that returns the number of planes for this buffer type.
     */
    DmaBuffersQueueBase(int fd, v4l2_buf_type bufferType, std::function<uint32_t()> planesCountGetter);

public:
    DmaBuffersQueueBase(const DmaBuffersQueueBase&) = delete;
    DmaBuffersQueueBase& operator=(const DmaBuffersQueueBase&) = delete;
    DmaBuffersQueueBase(DmaBuffersQueueBase&&) = delete;
    DmaBuffersQueueBase& operator=(DmaBuffersQueueBase&&) = delete;

    virtual ~DmaBuffersQueueBase() = default;

    /**
     * @brief Registers DMA buffers for use with the V4L2 device queue.
     *
     * Calls VIDIOC_REQBUFS to register the buffers with the device
     * and initializes tracking state. Buffers should be pre-mapped if
     * CPU access is required.
     *
     * @param buffers Vector of DmaBuffer unique_ptrs to register.
     * @throws std::runtime_error if VIDIOC_REQBUFS fails or buffer count mismatch.
     */
    void RegisterBuffers(std::vector<std::unique_ptr<DmaBuffer>> buffers);

    /**
     * @brief Starts streaming on this buffer queue.
     * @throws std::runtime_error if VIDIOC_STREAMON fails.
     */
    void StreamOn();

    /**
     * @brief Stops streaming on this buffer queue.
     * @throws std::runtime_error if VIDIOC_STREAMOFF fails.
     */
    void StreamOff();

    /**
     * @brief Returns the number of registered buffers.
     */
    size_t GetBufferCount() const { return buffers_.size(); }

protected:
    /**
     * @brief Returns the cached planes count.
     */
    uint32_t GetPlanesCount() const { return planesCount_; }
};

#endif //QOPENHDPROJECT_DMABUFFERSQUEUEBASE_H
