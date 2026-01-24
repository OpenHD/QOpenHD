#include "EncodedDmaBuffersQueue.h"

#include <cerrno>
#include <cstring>
#include <stdexcept>
#include <poll.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

EncodedDmaBuffersQueue::EncodedDmaBuffersQueue(int fd, std::function<uint32_t()> planesCountGetter)
    : DmaBuffersQueueBase(fd, V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE, std::move(planesCountGetter))
{
}

void EncodedDmaBuffersQueue::WaitWrite(gsl::span<const uint8_t> data)
{
    // Loop until we find a free buffer
    while (true) {
        // Try to free any completed buffers first
        TryDequeueCompletedBuffers();

        int freeIndex = FindFreeBufferIndex();
        if (freeIndex >= 0) {
            // Found a free buffer - write data to it
            buffers_[freeIndex]->Write(data);

            // Prepare v4l2_buffer for queuing
            const uint32_t planesCount = GetPlanesCount();
            std::vector<struct v4l2_plane> planes(planesCount);
            std::memset(planes.data(), 0, sizeof(v4l2_plane) * planesCount);

            // Set up first plane with our DMA buffer
            planes[0].m.fd = buffers_[freeIndex]->GetFd();
            planes[0].bytesused = data.size();
            planes[0].length = buffers_[freeIndex]->GetSize();

            struct v4l2_buffer buf = {};
            buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
            buf.memory = V4L2_MEMORY_DMABUF;
            buf.index = static_cast<uint32_t>(freeIndex);
            buf.m.planes = planes.data();
            buf.length = planesCount;

            if (ioctl(fd_, VIDIOC_QBUF, &buf) < 0) {
                throw std::runtime_error(std::string("VIDIOC_QBUF failed: ") + std::strerror(errno));
            }

            // Mark buffer as in use
            inUse_[freeIndex] = true;
            return;
        }

        // No free buffer available - wait for device to signal POLLOUT
        struct pollfd pfd = {};
        pfd.fd = fd_;
        pfd.events = POLLOUT;

        int ret = poll(&pfd, 1, -1); // Infinite wait
        if (ret < 0) {
            if (errno == EINTR) {
                continue; // Interrupted by signal, retry
            }
            throw std::runtime_error(std::string("poll() failed: ") + std::strerror(errno));
        }

        if (pfd.revents & POLLERR) {
            throw std::runtime_error("poll() returned POLLERR");
        }

        // POLLOUT received - loop back to try dequeuing and finding free buffer
    }
}

void EncodedDmaBuffersQueue::TryDequeueCompletedBuffers()
{
    const uint32_t planesCount = GetPlanesCount();
    std::vector<struct v4l2_plane> planes(planesCount);

    while (true) {
        std::memset(planes.data(), 0, sizeof(v4l2_plane) * planesCount);

        struct v4l2_buffer buf = {};
        buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
        buf.memory = V4L2_MEMORY_DMABUF;
        buf.m.planes = planes.data();
        buf.length = planesCount;

        if (ioctl(fd_, VIDIOC_DQBUF, &buf) < 0) {
            if (errno == EAGAIN) {
                // No more buffers to dequeue
                break;
            }
            // Other errors during dequeue are not fatal for this helper
            break;
        }

        // Mark the dequeued buffer as free
        if (buf.index < inUse_.size()) {
            inUse_[buf.index] = false;
        }
    }
}

int EncodedDmaBuffersQueue::FindFreeBufferIndex() const
{
    for (size_t i = 0; i < inUse_.size(); ++i) {
        if (!inUse_[i]) {
            return static_cast<int>(i);
        }
    }
    return -1;
}
