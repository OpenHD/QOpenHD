#include "DecodedDmaBuffersQueue.h"

#include <cerrno>
#include <cstring>
#include <stdexcept>
#include <poll.h>
#include <sys/ioctl.h>
#include <sys/eventfd.h>
#include <unistd.h>
#include <linux/videodev2.h>

DecodedDmaBuffersQueue::DecodedDmaBuffersQueue(int fd, std::function<uint32_t()> planesCountGetter)
    : DmaBuffersQueueBase(fd, V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE, std::move(planesCountGetter))
{
    eventfd_ = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (eventfd_ < 0) {
        throw std::runtime_error(std::string("eventfd() failed: ") + std::strerror(errno));
    }
}

DecodedDmaBuffersQueue::~DecodedDmaBuffersQueue()
{
    if (eventfd_ >= 0) {
        close(eventfd_);
    }
}

void DecodedDmaBuffersQueue::QueueAllBuffers()
{
    const uint32_t planesCount = GetPlanesCount();

    for (size_t i = 0; i < buffers_.size(); ++i) {
        std::vector<struct v4l2_plane> planes(planesCount);
        std::memset(planes.data(), 0, sizeof(v4l2_plane) * planesCount);

        // Set up first plane with our DMA buffer
        planes[0].m.fd = buffers_[i]->GetFd();
        planes[0].length = buffers_[i]->GetSize();

        struct v4l2_buffer buf = {};
        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
        buf.memory = V4L2_MEMORY_DMABUF;
        buf.index = static_cast<uint32_t>(i);
        buf.m.planes = planes.data();
        buf.length = planesCount;

        if (ioctl(fd_, VIDIOC_QBUF, &buf) < 0) {
            throw std::runtime_error(std::string("VIDIOC_QBUF failed for CAPTURE buffer ") +
                                     std::to_string(i) + ": " + std::strerror(errno));
        }
    }
}

DecodedFrame DecodedDmaBuffersQueue::WaitForDecodedFrame()
{
    // Wait for decoded frame using poll() with eventfd for cancellation
    while (true) {
        struct pollfd pfds[2] = {};
        pfds[0].fd = fd_;
        pfds[0].events = POLLIN;
        pfds[1].fd = eventfd_;
        pfds[1].events = POLLIN;

        int ret = poll(pfds, 2, -1);  // Infinite wait
        if (ret < 0) {
            if (errno == EINTR) {
                continue;  // Interrupted by signal, retry
            }
            throw std::runtime_error(std::string("poll() failed: ") + std::strerror(errno));
        }

        // Check for interrupt request via eventfd
        if (pfds[1].revents & POLLIN) {
            return DecodedFrame{};  // Return invalid frame on interrupt
        }

        if (pfds[0].revents & POLLERR) {
            throw std::runtime_error("poll() returned POLLERR");
        }

        if (pfds[0].revents & POLLHUP) {
            return DecodedFrame{};  // Return invalid frame on hangup
        }

        if (pfds[0].revents & POLLIN) {
            break;  // Data available, proceed to dequeue
        }
    }

    // Dequeue the decoded buffer
    const uint32_t planesCount = GetPlanesCount();
    std::vector<struct v4l2_plane> planes(planesCount);
    std::memset(planes.data(), 0, sizeof(v4l2_plane) * planesCount);

    struct v4l2_buffer buf = {};
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    buf.memory = V4L2_MEMORY_DMABUF;
    buf.m.planes = planes.data();
    buf.length = planesCount;

    if (ioctl(fd_, VIDIOC_DQBUF, &buf) < 0) {
        throw std::runtime_error(std::string("VIDIOC_DQBUF failed for CAPTURE: ") + std::strerror(errno));
    }

    // Mark buffer as in use
    if (buf.index < inUse_.size()) {
        inUse_[buf.index] = true;
    }

    // Build DecodedFrame
    DecodedFrame frame;
    frame.buffer_index = buf.index;
    frame.planes_count = planesCount;
    frame.timestamp_us = static_cast<int64_t>(buf.timestamp.tv_sec) * 1000000 +
                         static_cast<int64_t>(buf.timestamp.tv_usec);

    for (uint32_t i = 0; i < planesCount && i < DecodedFrame::MAX_PLANES; ++i) {
        frame.planes[i].fd = buffers_[buf.index]->GetFd();
        frame.planes[i].offset = planes[i].data_offset;
        frame.planes[i].bytesused = planes[i].bytesused;
        frame.planes[i].length = planes[i].length;
    }

    return frame;
}

void DecodedDmaBuffersQueue::ReuseBuffer(uint32_t buffer_index)
{
    if (buffer_index >= buffers_.size()) {
        throw std::runtime_error("Invalid buffer index: " + std::to_string(buffer_index));
    }

    const uint32_t planesCount = GetPlanesCount();
    std::vector<struct v4l2_plane> planes(planesCount);
    std::memset(planes.data(), 0, sizeof(v4l2_plane) * planesCount);

    // Set up first plane with our DMA buffer
    planes[0].m.fd = buffers_[buffer_index]->GetFd();
    planes[0].length = buffers_[buffer_index]->GetSize();

    struct v4l2_buffer buf = {};
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    buf.memory = V4L2_MEMORY_DMABUF;
    buf.index = buffer_index;
    buf.m.planes = planes.data();
    buf.length = planesCount;

    if (ioctl(fd_, VIDIOC_QBUF, &buf) < 0) {
        throw std::runtime_error(std::string("VIDIOC_QBUF failed for CAPTURE buffer ") +
                                 std::to_string(buffer_index) + ": " + std::strerror(errno));
    }

    // Mark buffer as free
    inUse_[buffer_index] = false;
}

void DecodedDmaBuffersQueue::InterruptWait()
{
    uint64_t val = 1;
    // Write to eventfd to wake up poll() - ignore errors (best effort)
    (void)write(eventfd_, &val, sizeof(val));
}
