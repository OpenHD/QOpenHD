#include "DmaBuffersQueueBase.h"

#include <cerrno>
#include <cstring>
#include <stdexcept>
#include <sys/ioctl.h>

DmaBuffersQueueBase::DmaBuffersQueueBase(int fd, v4l2_buf_type bufferType, std::function<uint32_t()> planesCountGetter)
    : fd_(fd)
    , bufferType_(bufferType)
    , planesCountGetter_(std::move(planesCountGetter))
{
}

void DmaBuffersQueueBase::RegisterBuffers(std::vector<std::unique_ptr<DmaBuffer>> buffers)
{
    if (buffers.empty()) {
        throw std::runtime_error("Cannot register empty buffer list");
    }

    planesCount_ = planesCountGetter_();

    // Request buffers from V4L2 device
    struct v4l2_requestbuffers reqbufs = {};
    reqbufs.count = buffers.size();
    reqbufs.type = bufferType_;
    reqbufs.memory = V4L2_MEMORY_DMABUF;

    if (ioctl(fd_, VIDIOC_REQBUFS, &reqbufs) < 0) {
        throw std::runtime_error(std::string("VIDIOC_REQBUFS failed: ") + std::strerror(errno));
    }

    if (reqbufs.count < buffers.size()) {
        throw std::runtime_error("Device allocated fewer buffers than requested");
    }

    // Store buffers and initialize tracking state
    buffers_ = std::move(buffers);
    inUse_.assign(buffers_.size(), false);
}

void DmaBuffersQueueBase::StreamOn()
{
    int type = static_cast<int>(bufferType_);
    if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
        throw std::runtime_error(std::string("VIDIOC_STREAMON failed: ") + std::strerror(errno));
    }
}

void DmaBuffersQueueBase::StreamOff()
{
    int type = static_cast<int>(bufferType_);
    if (ioctl(fd_, VIDIOC_STREAMOFF, &type) < 0) {
        throw std::runtime_error(std::string("VIDIOC_STREAMOFF failed: ") + std::strerror(errno));
    }
}
