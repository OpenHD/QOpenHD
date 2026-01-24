#include "DmaBuffer.h"

#include <cstdint>
#include <cstring>
#include <stdexcept>
#include <gsl/span>
#include <unistd.h>
#include <sys/mman.h>

// Private constructor
DmaBuffer::DmaBuffer(int fd, std::size_t size) : fd_(fd), size_(size) {}

// Destructor
DmaBuffer::~DmaBuffer() {
    if (fd_ >= 0) {
        close(fd_);
        fd_ = -1;
    }
}

void DmaBuffer::MapBuffer()
{
    auto ptr = mmap(nullptr,size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
    if (ptr == MAP_FAILED) {
        throw std::runtime_error("Failed to map DMA buffer");
    }
    wasMapped_ = true;
    mapPtr_ = static_cast<uint8_t*>(ptr);
}

void DmaBuffer::Write(gsl::span<const uint8_t> data)
{
    if (!wasMapped_) {
        throw std::runtime_error("Buffer not mapped");
    }
    if (data.size() > size_) {
        throw std::runtime_error("Write size exceeds buffer size");
    }
    std::memcpy(mapPtr_, data.data(), data.size());
    msync(mapPtr_, data.size(), MS_SYNC);
}
