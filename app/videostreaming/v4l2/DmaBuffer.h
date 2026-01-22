#ifndef QOPENHDPROJECT_DMABUFFER_H
#define QOPENHDPROJECT_DMABUFFER_H
#include <cstddef>
#include <bits/stdint-uintn.h>


class DmaBuffer {
private:
    int fd_;
    std::size_t size_;
    bool wasMapped_ = false;
    uint8_t* mapPtr;

public:
    DmaBuffer(const DmaBuffer&) = delete;
    DmaBuffer& operator=(const DmaBuffer&) = delete;
    DmaBuffer(DmaBuffer&&) = delete;
    DmaBuffer& operator=(DmaBuffer&&) = delete;

    DmaBuffer(int fd, std::size_t size);
    ~DmaBuffer();

    void MapBuffer();
    void Sync();
};



#endif //QOPENHDPROJECT_DMABUFFER_H
