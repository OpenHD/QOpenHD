
#include "DmaBuffersAllocator.h"

#include <QDebug>
#include <fcntl.h>
#include <linux/dma-heap.h>
#include <sys/ioctl.h>
#include <vector>

std::unique_ptr<DmaBuffersAllocator> DmaBuffersAllocator::Create() {
    static const std::vector<const char *> heapNames {
        "/dev/dma_heap/vidbuf_cached",
        "/dev/dma_heap/linux,cma",
        "/dev/dma_heap/reserved",
        "/dev/dma_heap/system"
    };

    for (const char *name : heapNames)
    {
        int ret = ::open(name, O_RDWR | O_CLOEXEC, 0);
        if (ret < 0)
        {
            continue;
        }
        return std::unique_ptr<DmaBuffersAllocator>(new DmaBuffersAllocator(ret));
    }

    throw std::runtime_error("Failed to open DMA heap");
}


DmaBuffersAllocator::DmaBuffersAllocator(int fd)
    : fd_(fd)
{

}

std::unique_ptr<DmaBuffer> DmaBuffersAllocator::Allocate(size_t size)
{
    dma_heap_allocation_data allocData =
    {
        .len = size,
        .fd = 0,
        .fd_flags = O_RDWR | O_CLOEXEC,
        .heap_flags = 0
    };

    int ret = ::ioctl(fd_, DMA_HEAP_IOCTL_ALLOC, &allocData);
    if (ret < 0)
    {
        qWarning() << "Failed to allocate DMA buffer of size" << size;
        throw std::runtime_error("Failed to allocate DMA buffer");
    }

    return std::make_unique<DmaBuffer>(allocData.fd, size);
}
