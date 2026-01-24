#ifndef QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H
#define QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H

#include <cstdint>
#include <functional>
#include <memory>
#include <vector>
#include <gsl/span>

#include "DmaBuffer.h"

class DecodedDmaBuffersQueue {
private:
    int fd_;
    std::function<uint32_t()> planesCountGetter_;
    std::vector<std::unique_ptr<DmaBuffer>> buffers_;
    std::vector<bool> inUse_;
    uint32_t planesCount_ = 0;

public:

    DecodedDmaBuffersQueue(const DecodedDmaBuffersQueue&) = delete;
    DecodedDmaBuffersQueue& operator=(const DecodedDmaBuffersQueue&) = delete;
    DecodedDmaBuffersQueue(DecodedDmaBuffersQueue&&) = delete;
    DecodedDmaBuffersQueue& operator=(DecodedDmaBuffersQueue&&) = delete;

    ~DecodedDmaBuffersQueue() = default;
};

#endif //QOPENHDPROJECT_DECODEDDMABUFFERSQUEUE_H