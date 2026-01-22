//
// Created by buldo on 1/22/26.
//

#include "V4L2Device.h"

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

// Private constructor
V4L2Device::V4L2Device(int fd) : fd_(fd) {}

// Destructor
V4L2Device::~V4L2Device() {
    if (fd_ >= 0) {
        close(fd_);
        fd_ = -1;
    }
}

// Factory method
std::unique_ptr<V4L2Device> V4L2Device::Open(const std::string& devicePath) {
    int fd = open(devicePath.c_str(), O_RDWR | O_NONBLOCK);
    if (fd < 0) {
        return nullptr;
    }

    // Verify it's a V4L2 device
    struct v4l2_capability cap;
    if (ioctl(fd, VIDIOC_QUERYCAP, &cap) < 0) {
        close(fd);
        return nullptr;
    }

    return std::unique_ptr<V4L2Device>(new V4L2Device(fd));
}

// ioctl wrappers

int V4L2Device::QueryCapabilities(struct v4l2_capability* cap) const {
    return ioctl(fd_, VIDIOC_QUERYCAP, cap);
}

int V4L2Device::SubscribeEvent(struct v4l2_event_subscription* sub) const {
    return ioctl(fd_, VIDIOC_SUBSCRIBE_EVENT, sub);
}

int V4L2Device::RequestBuffers(struct v4l2_requestbuffers* req) const {
    return ioctl(fd_, VIDIOC_REQBUFS, req);
}

int V4L2Device::SetFormat(struct v4l2_format* fmt) const {
    return ioctl(fd_, VIDIOC_S_FMT, fmt);
}

int V4L2Device::GetFormat(struct v4l2_format* fmt) const {
    return ioctl(fd_, VIDIOC_G_FMT, fmt);
}

int V4L2Device::SetControl(struct v4l2_control* ctrl) const {
    return ioctl(fd_, VIDIOC_S_CTRL, ctrl);
}

int V4L2Device::StreamOn(int type) const {
    return ioctl(fd_, VIDIOC_STREAMON, &type);
}

int V4L2Device::StreamOff(int type) const {
    return ioctl(fd_, VIDIOC_STREAMOFF, &type);
}

int V4L2Device::DequeueEvent(struct v4l2_event* ev) const {
    return ioctl(fd_, VIDIOC_DQEVENT, ev);
}

int V4L2Device::DequeueBuffer(struct v4l2_buffer* buf) const {
    return ioctl(fd_, VIDIOC_DQBUF, buf);
}

int V4L2Device::QueueBuffer(struct v4l2_buffer* buf) const {
    return ioctl(fd_, VIDIOC_QBUF, buf);
}
