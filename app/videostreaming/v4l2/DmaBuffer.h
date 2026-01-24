#ifndef QOPENHDPROJECT_DMABUFFER_H
#define QOPENHDPROJECT_DMABUFFER_H
#include <cstddef>
#include <cstdint>
#include <gsl/span>


class DmaBuffer {
private:
    int fd_;
    std::size_t size_;
    bool wasMapped_ = false;
    uint8_t* mapPtr_;

public:
    DmaBuffer(const DmaBuffer&) = delete;
    DmaBuffer& operator=(const DmaBuffer&) = delete;
    DmaBuffer(DmaBuffer&&) = delete;
    DmaBuffer& operator=(DmaBuffer&&) = delete;

    DmaBuffer(int fd, std::size_t size);
    ~DmaBuffer();

    int GetFd() const { return fd_; }
    std::size_t GetSize() const { return size_; }

    void MapBuffer();
    void Write(gsl::span<const uint8_t> data);
};



#endif //QOPENHDPROJECT_DMABUFFER_H
