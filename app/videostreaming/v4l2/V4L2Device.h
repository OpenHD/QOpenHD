//
// Created by buldo on 1/22/26.
//

#ifndef QOPENHDPROJECT_V4L2DEVICE_H
#define QOPENHDPROJECT_V4L2DEVICE_H

#include <memory>
#include <string>

#include "EncodedDmaBuffersQueue.h"
#include "DecodedDmaBuffersQueue.h"

class V4L2Device {
private:
    int fd_ = -1;
    std::unique_ptr<EncodedDmaBuffersQueue> encodedBuffersQueue_;
    std::unique_ptr<DecodedDmaBuffersQueue> decodedBuffersQueue_;

    // Private constructor - only factory method can create instances
    explicit V4L2Device(int fd);

public:
    // Delete all copy and move operations for strict lifetime control
    V4L2Device(const V4L2Device&) = delete;
    V4L2Device& operator=(const V4L2Device&) = delete;
    V4L2Device(V4L2Device&&) = delete;
    V4L2Device& operator=(V4L2Device&&) = delete;

    // Destructor closes the device
    ~V4L2Device();

    // Factory method to open a V4L2 device
    static std::unique_ptr<V4L2Device> Open(const std::string& devicePath);

    // Get file descriptor
    int GetFd() const { return fd_; }

    // Get the number of planes for encoded (OUTPUT) buffers
    uint32_t GetEncodedPlanesCount() const;

    // Get the number of planes for decoded (CAPTURE) buffers
    uint32_t GetDecodedPlanesCount() const;

    // Get the encoded buffers queue
    EncodedDmaBuffersQueue* GetEncodedBuffersQueue() { return encodedBuffersQueue_.get(); }

    // Get the decoded buffers queue
    DecodedDmaBuffersQueue* GetDecodedBuffersQueue() { return decodedBuffersQueue_.get(); }

    // ioctl wrappers - all return 0 on success, -1 on error (with errno set)

    /**
     * @brief Query device capabilities (VIDIOC_QUERYCAP)
     * @param cap Pointer to v4l2_capability structure
     * @return 0 on success, -1 on error
     */
    int QueryCapabilities(struct v4l2_capability* cap) const;

    /**
     * @brief Subscribe to events (VIDIOC_SUBSCRIBE_EVENT)
     * @param sub Pointer to v4l2_event_subscription structure
     * @return 0 on success, -1 on error
     */
    int SubscribeEvent(struct v4l2_event_subscription* sub) const;

    /**
     * @brief Request buffers (VIDIOC_REQBUFS)
     * @param req Pointer to v4l2_requestbuffers structure
     * @return 0 on success, -1 on error
     */
    int RequestBuffers(struct v4l2_requestbuffers* req) const;

    /**
     * @brief Set format (VIDIOC_S_FMT)
     * @param fmt Pointer to v4l2_format structure
     * @return 0 on success, -1 on error
     */
    int SetFormat(struct v4l2_format* fmt) const;

    /**
     * @brief Get format (VIDIOC_G_FMT)
     * @param fmt Pointer to v4l2_format structure
     * @return 0 on success, -1 on error
     */
    int GetFormat(struct v4l2_format* fmt) const;

    /**
     * @brief Set control value (VIDIOC_S_CTRL)
     * @param ctrl Pointer to v4l2_control structure
     * @return 0 on success, -1 on error
     */
    int SetControl(struct v4l2_control* ctrl) const;

    /**
     * @brief Start streaming (VIDIOC_STREAMON)
     * @param type Buffer type (V4L2_BUF_TYPE_*)
     * @return 0 on success, -1 on error
     */
    int StreamOn(int type) const;

    /**
     * @brief Stop streaming (VIDIOC_STREAMOFF)
     * @param type Buffer type (V4L2_BUF_TYPE_*)
     * @return 0 on success, -1 on error
     */
    int StreamOff(int type) const;

    /**
     * @brief Dequeue event (VIDIOC_DQEVENT)
     * @param ev Pointer to v4l2_event structure
     * @return 0 on success, -1 on error
     */
    int DequeueEvent(struct v4l2_event* ev) const;

    /**
     * @brief Dequeue buffer (VIDIOC_DQBUF)
     * @param buf Pointer to v4l2_buffer structure
     * @return 0 on success, -1 on error
     */
    int DequeueBuffer(struct v4l2_buffer* buf) const;

    /**
     * @brief Queue buffer (VIDIOC_QBUF)
     * @param buf Pointer to v4l2_buffer structure
     * @return 0 on success, -1 on error
     */
    int QueueBuffer(struct v4l2_buffer* buf) const;

};

#endif //QOPENHDPROJECT_V4L2DEVICE_H
