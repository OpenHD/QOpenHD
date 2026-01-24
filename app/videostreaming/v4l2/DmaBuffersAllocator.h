#ifndef DMA_BUFFERS_ALLOCATOR_H
#define DMA_BUFFERS_ALLOCATOR_H

#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

#include "DmaBuffer.h"

class DmaBuffersAllocator {
private:
    int fd_ = 0;
public:
    DmaBuffersAllocator(const DmaBuffersAllocator&) = delete;
    DmaBuffersAllocator& operator=(const DmaBuffersAllocator&) = delete;
    DmaBuffersAllocator(DmaBuffersAllocator&&) = delete;
    DmaBuffersAllocator& operator=(DmaBuffersAllocator&&) = delete;

    static std::unique_ptr<DmaBuffersAllocator> Create();

    std::unique_ptr<DmaBuffer> Allocate(size_t size);

private:
    DmaBuffersAllocator(int fd);
};

#endif // DMA_BUFFERS_ALLOCATOR_H
