// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "dma_buffers_manager.h"

#include <QDebug>

#include <sys/ioctl.h>
#include <cerrno>
#include <cstring>

#include <linux/videodev2.h>


DmaBuffersManager::DmaBuffersManager(std::shared_ptr<DmaHeap> heap, size_t count, v4l2_buf_type type)
    : heap_(std::move(heap))
    , count_(count)
    , type_(type)
{
    buffers_.reserve(count_);
    in_use_.resize(count_, false);
}

DmaBuffersManager::~DmaBuffersManager()
{
    deallocate();
}

bool DmaBuffersManager::allocate(size_t buffer_size)
{
    if (!heap_ || !heap_->isValid()) {
        qCritical() << "DmaBuffersManager::allocate: DmaHeap not initialized";
        return false;
    }

    // Free old buffers first
    deallocate();

    buffers_.resize(count_);
    in_use_.assign(count_, false);
    current_buffer_ = 0;

    const char* type_name = (type_ == V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE) ? "input" : "output";

    for (size_t i = 0; i < count_; ++i) {
        DmaBufInfo info = heap_->allocAndMap(buffer_size);
        if (info.fd < 0) {
            qCritical() << "DmaBuffersManager::allocate: failed to allocate" << type_name << "buffer" << i;
            deallocate();
            return false;
        }
        buffers_[i] = info;
    }

    qInfo() << "DmaBuffersManager::allocate: allocated" << count_ << type_name
            << "buffers, size" << buffer_size << "each";
    return true;
}

void DmaBuffersManager::deallocate()
{
    for (auto& buf : buffers_) {
        if (buf.mapped_addr) {
            DmaHeap::unmap(buf.mapped_addr, buf.size);
            buf.mapped_addr = nullptr;
        }
        if (buf.fd >= 0) {
            DmaHeap::closeFd(buf.fd);
            buf.fd = -1;
        }
        buf.size = 0;
    }
    buffers_.clear();
    in_use_.clear();
    current_buffer_ = 0;
}

bool DmaBuffersManager::requestOnDevice(int fd)
{
    if (fd < 0) {
        qWarning() << "DmaBuffersManager::requestOnDevice: invalid fd";
        return false;
    }

    struct v4l2_requestbuffers req = {};
    req.count = count_;
    req.type = type_;
    req.memory = V4L2_MEMORY_DMABUF;

    if (ioctl(fd, VIDIOC_REQBUFS, &req) < 0) {
        qCritical() << "DmaBuffersManager::requestOnDevice: VIDIOC_REQBUFS failed:"
                    << strerror(errno);
        return false;
    }

    if (req.count < count_) {
        qWarning() << "DmaBuffersManager::requestOnDevice: requested" << count_
                   << "buffers, got" << req.count;
    }

    const char* type_name = (type_ == V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE) ? "input" : "output";
    qInfo() << "DmaBuffersManager::requestOnDevice:" << req.count << type_name << "DMA-BUF buffers registered";
    return true;
}

bool DmaBuffersManager::releaseOnDevice(int fd)
{
    if (fd < 0) {
        return true;  // Nothing to do
    }

    struct v4l2_requestbuffers req = {};
    req.count = 0;
    req.type = type_;
    req.memory = V4L2_MEMORY_DMABUF;

    // Ignore errors during cleanup
    if (ioctl(fd, VIDIOC_REQBUFS, &req) < 0) {
        qDebug() << "DmaBuffersManager::releaseOnDevice: VIDIOC_REQBUFS(0) failed (may be expected)";
    }
    return true;
}

const DmaBufInfo& DmaBuffersManager::getInfo(size_t index) const
{
    return buffers_.at(index);
}

DmaBufInfo& DmaBuffersManager::getInfo(size_t index)
{
    return buffers_.at(index);
}

int DmaBuffersManager::getFreeBufferIndex()
{
    for (size_t i = 0; i < count_; ++i) {
        size_t idx = (current_buffer_ + i) % count_;
        if (!in_use_[idx]) {
            return static_cast<int>(idx);
        }
    }
    return -1;  // No free buffers
}

void DmaBuffersManager::markInUse(size_t index)
{
    if (index < count_) {
        in_use_[index] = true;
        // Advance round-robin pointer when current buffer is used
        if (index == (current_buffer_ % count_)) {
            current_buffer_ = (index + 1) % count_;
        }
    }
}

void DmaBuffersManager::markFree(size_t index)
{
    if (index < count_) {
        in_use_[index] = false;
    }
}

void DmaBuffersManager::resetUsage()
{
    in_use_.assign(count_, false);
    current_buffer_ = 0;
}

#endif // ENABLE_V4L2_GL_PLAYER
