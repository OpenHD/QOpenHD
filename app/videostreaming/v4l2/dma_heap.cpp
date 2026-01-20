// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "dma_heap.h"

#include <QDebug>

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <cerrno>
#include <cstring>
#include <vector>

#include <linux/dma-buf.h>
#include <linux/dma-heap.h>


// ============================================================================
// UniqueFd implementation
// ============================================================================

UniqueFd::~UniqueFd()
{
    reset();
}

UniqueFd::UniqueFd(UniqueFd&& other) noexcept
    : fd_(other.fd_)
{
    other.fd_ = -1;
}

UniqueFd& UniqueFd::operator=(UniqueFd&& other) noexcept
{
    if (this != &other) {
        reset(other.fd_);
        other.fd_ = -1;
    }
    return *this;
}

int UniqueFd::release()
{
    int fd = fd_;
    fd_ = -1;
    return fd;
}

void UniqueFd::reset(int fd)
{
    if (fd_ >= 0) {
        ::close(fd_);
    }
    fd_ = fd;
}


// ============================================================================
// DmaHeap implementation
// ============================================================================

DmaHeap::DmaHeap()
{
    // List of DMA heap devices by priority (based on rpicam-apps)
    // vidbuf_cached symlinks to either system heap (Pi 5) or CMA (Pi 4)
    static const std::vector<const char*> heapNames = {
        "/dev/dma_heap/vidbuf_cached",
        "/dev/dma_heap/linux,cma",
    };

    for (const char* name : heapNames) {
        int fd = ::open(name, O_RDWR | O_CLOEXEC);
        if (fd < 0) {
            qDebug() << "DmaHeap: failed to open" << name << ":" << strerror(errno);
            continue;
        }

        dma_heap_fd_.reset(fd);
        qInfo() << "DmaHeap: opened" << name;
        return;
    }

    qCritical() << "DmaHeap: could not open any DMA heap device";
}

DmaHeap::~DmaHeap()
{
    // UniqueFd handles cleanup
}

int DmaHeap::alloc(const char* name, size_t size) const
{
    if (!dma_heap_fd_.isValid()) {
        qWarning() << "DmaHeap::alloc: heap not initialized";
        return -1;
    }

    if (!name || size == 0) {
        qWarning() << "DmaHeap::alloc: invalid parameters";
        return -1;
    }

    struct dma_heap_allocation_data alloc = {};
    alloc.len = size;
    alloc.fd_flags = O_CLOEXEC | O_RDWR;

    int ret = ::ioctl(dma_heap_fd_.get(), DMA_HEAP_IOCTL_ALLOC, &alloc);
    if (ret < 0) {
        qWarning() << "DmaHeap::alloc: DMA_HEAP_IOCTL_ALLOC failed for" << name
                   << "size" << size << ":" << strerror(errno);
        return -1;
    }

    // Set buffer name for debugging (optional, ignore errors)
    ret = ::ioctl(alloc.fd, DMA_BUF_SET_NAME, name);
    if (ret < 0) {
        // Not critical, some kernels don't support this
        qDebug() << "DmaHeap::alloc: DMA_BUF_SET_NAME failed (not critical)";
    }

    qDebug() << "DmaHeap::alloc: allocated" << name << "fd=" << alloc.fd << "size=" << size;
    return alloc.fd;
}

DmaBufInfo DmaHeap::allocAndMap(size_t size) const
{
    DmaBufInfo info;

    int fd = alloc("v4l2_buffer", size);
    if (fd < 0) {
        return info;
    }

    void* addr = map(fd, size);
    if (!addr) {
        ::close(fd);
        return info;
    }

    info.fd = fd;
    info.mapped_addr = addr;
    info.size = size;
    return info;
}

void* DmaHeap::map(int fd, size_t size)
{
    if (fd < 0 || size == 0) {
        return nullptr;
    }

    void* addr = ::mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (addr == MAP_FAILED) {
        qWarning() << "DmaHeap::map: mmap failed for fd" << fd << ":" << strerror(errno);
        return nullptr;
    }

    return addr;
}

void DmaHeap::unmap(void* addr, size_t size)
{
    if (addr && size > 0) {
        ::munmap(addr, size);
    }
}

bool DmaHeap::syncStart(int fd, bool write)
{
    if (fd < 0) return false;

    struct dma_buf_sync sync = {};
    sync.flags = DMA_BUF_SYNC_START;
    sync.flags |= write ? DMA_BUF_SYNC_RW : DMA_BUF_SYNC_READ;

    if (::ioctl(fd, DMA_BUF_IOCTL_SYNC, &sync) < 0) {
        qWarning() << "DmaHeap::syncStart: failed for fd" << fd << ":" << strerror(errno);
        return false;
    }
    return true;
}

bool DmaHeap::syncEnd(int fd, bool write)
{
    if (fd < 0) return false;

    struct dma_buf_sync sync = {};
    sync.flags = DMA_BUF_SYNC_END;
    sync.flags |= write ? DMA_BUF_SYNC_RW : DMA_BUF_SYNC_READ;

    if (::ioctl(fd, DMA_BUF_IOCTL_SYNC, &sync) < 0) {
        qWarning() << "DmaHeap::syncEnd: failed for fd" << fd << ":" << strerror(errno);
        return false;
    }
    return true;
}

void DmaHeap::closeFd(int fd)
{
    if (fd >= 0) {
        ::close(fd);
    }
}

#endif // ENABLE_V4L2_GL_PLAYER
