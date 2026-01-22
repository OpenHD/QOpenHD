
#include "DmaBuffersAllocator.h"

#include <QDebug>
#include <fcntl.h>
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
