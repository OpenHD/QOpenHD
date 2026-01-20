// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef DMA_HEAP_H
#define DMA_HEAP_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <cstddef>
#include <cstdint>

/**
 * @brief RAII wrapper for a file descriptor.
 */
class UniqueFd {
public:
    UniqueFd() : fd_(-1) {}
    explicit UniqueFd(int fd) : fd_(fd) {}
    ~UniqueFd();

    // Move only
    UniqueFd(UniqueFd&& other) noexcept;
    UniqueFd& operator=(UniqueFd&& other) noexcept;
    UniqueFd(const UniqueFd&) = delete;
    UniqueFd& operator=(const UniqueFd&) = delete;

    int get() const { return fd_; }
    int release();
    void reset(int fd = -1);
    bool isValid() const { return fd_ >= 0; }
    explicit operator bool() const { return isValid(); }

private:
    int fd_;
};


/**
 * @brief DMA-BUF buffer information.
 */
struct DmaBufInfo {
    int fd = -1;              // DMA-BUF file descriptor
    void* mapped_addr = nullptr;  // Memory address (if mapped)
    size_t size = 0;          // Buffer size in bytes
};


/**
 * @brief DMA heap allocator for V4L2 decoder buffers.
 *
 * Uses Linux DMA heap API to allocate buffers that can be shared
 * between V4L2 decoder and display without copying.
 *
 * Supports:
 * - /dev/dma_heap/vidbuf_cached (Pi 5)
 * - /dev/dma_heap/linux,cma (Pi 4 and below)
 *
 * Based on rpicam-apps DmaHeap implementation.
 */
class DmaHeap {
public:
    DmaHeap();
    ~DmaHeap();

    // Non-copyable
    DmaHeap(const DmaHeap&) = delete;
    DmaHeap& operator=(const DmaHeap&) = delete;

    /**
     * @brief Check if DMA heap is available.
     */
    bool isValid() const { return dma_heap_fd_.isValid(); }

    /**
     * @brief Allocate a DMA-BUF buffer.
     * @param name Debug name for the buffer (optional)
     * @param size Size in bytes
     * @return File descriptor for the buffer, or -1 on failure
     */
    int alloc(const char* name, size_t size) const;

    /**
     * @brief Allocate and map a DMA-BUF buffer.
     * @param size Size in bytes
     * @return Buffer info with fd and mapped address, or invalid on failure
     */
    DmaBufInfo allocAndMap(size_t size) const;

    /**
     * @brief Map an existing DMA-BUF for CPU access.
     * @param fd DMA-BUF file descriptor
     * @param size Size to map
     * @return Mapped address or nullptr on failure
     */
    static void* map(int fd, size_t size);

    /**
     * @brief Unmap a previously mapped DMA-BUF.
     * @param addr Mapped address
     * @param size Size that was mapped
     */
    static void unmap(void* addr, size_t size);

    /**
     * @brief Start DMA-BUF sync for CPU access.
     * Must be called before writing to a mapped buffer.
     * @param fd DMA-BUF file descriptor
     * @param write true if writing, false if only reading
     * @return true on success
     */
    static bool syncStart(int fd, bool write = true);

    /**
     * @brief End DMA-BUF sync after CPU access.
     * Must be called after writing to a mapped buffer.
     * @param fd DMA-BUF file descriptor
     * @param write true if was writing, false if only reading
     * @return true on success
     */
    static bool syncEnd(int fd, bool write = true);

    /**
     * @brief Close a DMA-BUF file descriptor.
     * @param fd File descriptor to close
     */
    static void closeFd(int fd);

private:
    UniqueFd dma_heap_fd_;
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // DMA_HEAP_H
