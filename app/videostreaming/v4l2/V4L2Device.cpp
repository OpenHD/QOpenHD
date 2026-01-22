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
