// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_decoder.h"

#include <QDebug>

#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <poll.h>
#include <cerrno>

#include <linux/videodev2.h>
#include <linux/dma-buf.h>


// Configuration constants
static constexpr uint32_t INPUT_BUFFER_COUNT = 4;
static constexpr uint32_t OUTPUT_BUFFER_COUNT = 6;
static constexpr uint32_t DEFAULT_INPUT_BUFFER_SIZE = 512 * 1024;  // 512KB


V4L2Decoder::V4L2Decoder()
{
    qDebug() << "V4L2Decoder: created";
}

V4L2Decoder::~V4L2Decoder()
{
    stop();
    qDebug() << "V4L2Decoder: destroyed";
}

void V4L2Decoder::set_frame_callback(FrameCallback callback)
{
    frame_callback_ = std::move(callback);
}

void V4L2Decoder::set_capabilities_callback(CapabilitiesCallback callback)
{
    capabilities_callback_ = std::move(callback);
}

bool V4L2Decoder::init(const std::string& device_path, Codec codec)
{
    if (running_.load()) {
        setError("Cannot init while running");
        return false;
    }

    device_path_ = device_path;
    codec_ = codec;

    qInfo() << "V4L2Decoder: initializing with device" << device_path.c_str()
            << "codec:" << (codec == Codec::H264 ? "H264" : "H265");

    // Initialize DMA heap allocator
    dma_heap_ = std::make_shared<DmaHeap>();
    if (!dma_heap_->isValid()) {
        setError("Failed to initialize DMA heap");
        return false;
    }

    // Create buffer managers
    input_buffers_ = std::make_unique<DmaBuffersManager>(
        dma_heap_, INPUT_BUFFER_COUNT, V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE);
    output_buffers_ = std::make_unique<DmaBuffersManager>(
        dma_heap_, OUTPUT_BUFFER_COUNT, V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);

    // Open V4L2 device
    if (!openDevice()) {
        return false;
    }

    // Setup input format
    if (!setupInputFormat()) {
        closeDevice();
        return false;
    }

    // Setup input buffers
    if (!setupInputBuffers()) {
        closeDevice();
        return false;
    }

    qInfo() << "V4L2Decoder: initialized successfully";
    return true;
}

bool V4L2Decoder::start()
{
    if (running_.load()) {
        return true;
    }

    qInfo() << "V4L2Decoder: starting...";

    stop_requested_ = false;
    running_ = true;

    // Start decode thread
    decode_thread_ = std::thread(&V4L2Decoder::decodeLoop, this);

    qInfo() << "V4L2Decoder: started";
    return true;
}

void V4L2Decoder::stop()
{
    if (!running_.load()) {
        return;
    }

    qInfo() << "V4L2Decoder: stopping...";

    // Signal stop
    stop_requested_ = true;

    // Wake up decode thread
    {
        std::lock_guard<std::mutex> lock(nal_mutex_);
        nal_cv_.notify_all();
    }

    // Wait for decode thread
    if (decode_thread_.joinable()) {
        decode_thread_.join();
    }

    // Stop streaming
    stopStreaming();

    // Release buffers
    if (input_buffers_ && fd_ >= 0) {
        input_buffers_->releaseOnDevice(fd_);
        input_buffers_->deallocate();
    }
    if (output_buffers_ && fd_ >= 0) {
        output_buffers_->releaseOnDevice(fd_);
        output_buffers_->deallocate();
    }

    // Close device
    closeDevice();

    running_ = false;
    qInfo() << "V4L2Decoder: stopped. Decoded frames:" << frames_decoded_.load();
}

void V4L2Decoder::feed_nal_unit(const uint8_t* data, size_t size, int64_t timestamp_us)
{
    if (!running_.load() || !data || size == 0) {
        return;
    }

    nals_received_++;

    // Add to queue
    NalUnit nal;
    nal.data.assign(data, data + size);
    nal.timestamp_us = timestamp_us;

    {
        std::lock_guard<std::mutex> lock(nal_mutex_);
        nal_queue_.push(std::move(nal));
    }
    nal_cv_.notify_one();
}

void V4L2Decoder::recycle_buffer(uint32_t buffer_index)
{
    std::lock_guard<std::mutex> lock(recycle_mutex_);
    recycle_queue_.push(buffer_index);
}

V4L2Decoder::Stats V4L2Decoder::get_stats() const
{
    Stats stats;
    stats.frames_decoded = frames_decoded_.load();
    stats.frames_dropped = frames_dropped_.load();
    stats.nals_received = nals_received_.load();
    stats.decode_errors = decode_errors_.load();
    return stats;
}

void V4L2Decoder::reset_stats()
{
    frames_decoded_ = 0;
    frames_dropped_ = 0;
    nals_received_ = 0;
    decode_errors_ = 0;
}

void V4L2Decoder::setError(const std::string& error)
{
    last_error_ = error;
    qCritical() << "V4L2Decoder:" << error.c_str();
}

bool V4L2Decoder::openDevice()
{
    fd_ = ::open(device_path_.c_str(), O_RDWR | O_NONBLOCK);
    if (fd_ < 0) {
        setError(std::string("Failed to open ") + device_path_ + ": " + strerror(errno));
        return false;
    }

    // Query capabilities
    struct v4l2_capability cap = {};
    if (ioctl(fd_, VIDIOC_QUERYCAP, &cap) < 0) {
        setError(std::string("VIDIOC_QUERYCAP failed: ") + strerror(errno));
        closeDevice();
        return false;
    }

    // Check for M2M support
    if (!(cap.capabilities & V4L2_CAP_VIDEO_M2M_MPLANE)) {
        setError("Device does not support M2M MPLANE");
        closeDevice();
        return false;
    }

    qInfo() << "V4L2Decoder: opened device" << (const char*)cap.card
            << "driver:" << (const char*)cap.driver;

    // Subscribe to events
    struct v4l2_event_subscription sub = {};
    sub.type = V4L2_EVENT_SOURCE_CHANGE;
    if (ioctl(fd_, VIDIOC_SUBSCRIBE_EVENT, &sub) < 0) {
        qWarning() << "V4L2Decoder: failed to subscribe to SOURCE_CHANGE event";
    }

    sub.type = V4L2_EVENT_EOS;
    if (ioctl(fd_, VIDIOC_SUBSCRIBE_EVENT, &sub) < 0) {
        qWarning() << "V4L2Decoder: failed to subscribe to EOS event";
    }

    return true;
}

void V4L2Decoder::closeDevice()
{
    if (fd_ >= 0) {
        ::close(fd_);
        fd_ = -1;
    }
}

bool V4L2Decoder::setupInputFormat()
{
    // Set OUTPUT (input) format - compressed data
    struct v4l2_format fmt_out = {};
    fmt_out.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    fmt_out.fmt.pix_mp.width = 1920;   // Hint, will be updated from stream
    fmt_out.fmt.pix_mp.height = 1080;
    fmt_out.fmt.pix_mp.pixelformat = (codec_ == Codec::H264) ? V4L2_PIX_FMT_H264 : V4L2_PIX_FMT_HEVC;
    fmt_out.fmt.pix_mp.num_planes = 1;
    fmt_out.fmt.pix_mp.plane_fmt[0].sizeimage = DEFAULT_INPUT_BUFFER_SIZE;

    if (ioctl(fd_, VIDIOC_S_FMT, &fmt_out) < 0) {
        setError(std::string("Failed to set OUTPUT format: ") + strerror(errno));
        return false;
    }

    qInfo() << "V4L2Decoder: OUTPUT format set to"
            << (codec_ == Codec::H264 ? "H.264" : "H.265");

    return true;
}

bool V4L2Decoder::setupInputBuffers()
{
    // Get input buffer size from format
    struct v4l2_format fmt_out = {};
    fmt_out.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    if (ioctl(fd_, VIDIOC_G_FMT, &fmt_out) < 0) {
        setError(std::string("Failed to get OUTPUT format: ") + strerror(errno));
        return false;
    }

    size_t input_buffer_size = fmt_out.fmt.pix_mp.plane_fmt[0].sizeimage;
    if (input_buffer_size == 0) {
        input_buffer_size = DEFAULT_INPUT_BUFFER_SIZE;
    }

    // Allocate INPUT buffers
    if (!input_buffers_->allocate(input_buffer_size)) {
        setError("Failed to allocate input buffers");
        return false;
    }
    if (!input_buffers_->requestOnDevice(fd_)) {
        setError("Failed to request input buffers on device");
        return false;
    }

    qInfo() << "V4L2Decoder: input buffers configured -"
            << INPUT_BUFFER_COUNT << "buffers of" << input_buffer_size << "bytes";

    return true;
}

bool V4L2Decoder::handleSourceChange()
{
    qInfo() << "V4L2Decoder: handling SOURCE_CHANGE event";

    // Get CAPTURE format - decoder will have updated it with actual resolution
    struct v4l2_format fmt_cap = {};
    fmt_cap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;

    if (ioctl(fd_, VIDIOC_G_FMT, &fmt_cap) < 0) {
        setError(std::string("Failed to get CAPTURE format: ") + strerror(errno));
        return false;
    }

    // Update capabilities
    capabilities_.width = fmt_cap.fmt.pix_mp.width;
    capabilities_.height = fmt_cap.fmt.pix_mp.height;
    capabilities_.pixel_format = fmt_cap.fmt.pix_mp.pixelformat;
    capabilities_.plane_count = fmt_cap.fmt.pix_mp.num_planes;
    capabilities_.colorspace = fmt_cap.fmt.pix_mp.colorspace;
    capabilities_.ycbcr_enc = fmt_cap.fmt.pix_mp.ycbcr_enc;
    capabilities_.quantization = fmt_cap.fmt.pix_mp.quantization;
    capabilities_.xfer_func = fmt_cap.fmt.pix_mp.xfer_func;

    // Store plane info
    for (uint32_t i = 0; i < capabilities_.plane_count && i < 4; ++i) {
        output_plane_sizes_[i] = fmt_cap.fmt.pix_mp.plane_fmt[i].sizeimage;
        output_plane_strides_[i] = fmt_cap.fmt.pix_mp.plane_fmt[i].bytesperline;
    }

    char fourcc[5] = {0};
    memcpy(fourcc, &capabilities_.pixel_format, 4);
    qInfo() << "V4L2Decoder: CAPTURE format:" << fourcc
            << capabilities_.width << "x" << capabilities_.height
            << "planes:" << capabilities_.plane_count
            << "colorspace:" << capabilities_.colorspace;

    // Setup CAPTURE buffers
    if (!setupCaptureBuffers()) {
        return false;
    }

    // Notify about capabilities
    if (capabilities_callback_) {
        capabilities_callback_(capabilities_);
    }

    return true;
}

bool V4L2Decoder::setupCaptureFormat()
{
    // Try to set preferred output format (NV12)
    struct v4l2_format fmt_cap = {};
    fmt_cap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;

    if (ioctl(fd_, VIDIOC_G_FMT, &fmt_cap) < 0) {
        qWarning() << "V4L2Decoder: failed to get CAPTURE format";
    }

    // Try NV12 first
    fmt_cap.fmt.pix_mp.pixelformat = V4L2_PIX_FMT_NV12;
    if (ioctl(fd_, VIDIOC_S_FMT, &fmt_cap) < 0) {
        // NV12 not supported, use whatever decoder provides
        qInfo() << "V4L2Decoder: NV12 not supported, using decoder default";
    }

    return true;
}

bool V4L2Decoder::setupCaptureBuffers()
{
    // Get CAPTURE format
    struct v4l2_format fmt_cap = {};
    fmt_cap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    if (ioctl(fd_, VIDIOC_G_FMT, &fmt_cap) < 0) {
        setError(std::string("Failed to get CAPTURE format: ") + strerror(errno));
        return false;
    }

    // Calculate total buffer size (sum of all planes)
    size_t output_buffer_size = 0;
    for (uint32_t i = 0; i < fmt_cap.fmt.pix_mp.num_planes && i < 4; ++i) {
        output_buffer_size += fmt_cap.fmt.pix_mp.plane_fmt[i].sizeimage;
    }

    if (output_buffer_size == 0) {
        // Fallback: YUV420 = width * height * 1.5
        output_buffer_size = capabilities_.width * capabilities_.height * 3 / 2;
    }

    qInfo() << "V4L2Decoder: output buffer size:" << output_buffer_size;

    // Release existing buffers if any
    if (output_buffers_) {
        output_buffers_->releaseOnDevice(fd_);
        output_buffers_->deallocate();
    }

    // Allocate OUTPUT buffers
    if (!output_buffers_->allocate(output_buffer_size)) {
        setError("Failed to allocate output buffers");
        return false;
    }

    // Clear output buffers (fill with neutral YUV values)
    for (size_t i = 0; i < output_buffers_->count(); ++i) {
        auto& info = output_buffers_->getInfo(i);
        if (info.mapped_addr && info.size > 0) {
            uint8_t* buffer = static_cast<uint8_t*>(info.mapped_addr);
            size_t y_size = capabilities_.width * capabilities_.height;
            size_t uv_size = y_size / 2;
            if (y_size + uv_size <= info.size) {
                std::memset(buffer, 16, y_size);        // Y = 16 (black in limited range)
                std::memset(buffer + y_size, 128, uv_size);  // UV = 128 (neutral)
            }
        }
    }

    if (!output_buffers_->requestOnDevice(fd_)) {
        setError("Failed to request output buffers on device");
        return false;
    }

    // Queue all CAPTURE buffers
    for (uint32_t i = 0; i < output_buffers_->count(); ++i) {
        if (!requeueOutputBuffer(i)) {
            setError(std::string("Failed to queue output buffer ") + std::to_string(i));
            return false;
        }
    }

    qInfo() << "V4L2Decoder: output buffers configured -"
            << OUTPUT_BUFFER_COUNT << "buffers";

    return true;
}

bool V4L2Decoder::startStreaming()
{
    // Enable OUTPUT streaming (input data)
    int type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
        setError(std::string("STREAMON OUTPUT failed: ") + strerror(errno));
        return false;
    }

    // Enable CAPTURE streaming (decoded frames)
    type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
        setError(std::string("STREAMON CAPTURE failed: ") + strerror(errno));
        // Rollback
        type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
        ioctl(fd_, VIDIOC_STREAMOFF, &type);
        return false;
    }

    qInfo() << "V4L2Decoder: streaming started";
    return true;
}

bool V4L2Decoder::stopStreaming()
{
    if (fd_ < 0) {
        return true;
    }

    int type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    ioctl(fd_, VIDIOC_STREAMOFF, &type);

    type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    ioctl(fd_, VIDIOC_STREAMOFF, &type);

    qInfo() << "V4L2Decoder: streaming stopped";
    return true;
}

void V4L2Decoder::decodeLoop()
{
    qInfo() << "V4L2Decoder: decode loop started";

    bool streaming_started = false;
    bool capture_started = false;

    while (!stop_requested_) {
        // Get NAL unit from queue
        NalUnit nal;
        {
            std::unique_lock<std::mutex> lock(nal_mutex_);
            if (nal_queue_.empty()) {
                nal_cv_.wait_for(lock, std::chrono::milliseconds(100));
                if (nal_queue_.empty()) {
                    continue;
                }
            }
            nal = std::move(nal_queue_.front());
            nal_queue_.pop();
        }

        // Process recycled buffers
        {
            std::lock_guard<std::mutex> lock(recycle_mutex_);
            while (!recycle_queue_.empty()) {
                uint32_t idx = recycle_queue_.front();
                recycle_queue_.pop();
                requeueOutputBuffer(idx);
            }
        }

        // Start streaming on first NAL
        if (!streaming_started) {
            int type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
            if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
                setError(std::string("STREAMON OUTPUT failed: ") + strerror(errno));
                decode_errors_++;
                continue;
            }
            streaming_started = true;
            qInfo() << "V4L2Decoder: OUTPUT streaming started";
        }

        // Process the NAL
        if (!processNal(nal)) {
            decode_errors_++;
            continue;
        }

        // Poll for events and decoded frames
        struct pollfd pfd = {};
        pfd.fd = fd_;
        pfd.events = POLLIN | POLLPRI | POLLERR;

        while (poll(&pfd, 1, 0) > 0) {
            // Handle events (SOURCE_CHANGE)
            if (pfd.revents & POLLPRI) {
                struct v4l2_event ev = {};
                while (ioctl(fd_, VIDIOC_DQEVENT, &ev) == 0) {
                    if (ev.type == V4L2_EVENT_SOURCE_CHANGE) {
                        qInfo() << "V4L2Decoder: SOURCE_CHANGE event";
                        if (ev.u.src_change.changes & V4L2_EVENT_SRC_CH_RESOLUTION) {
                            if (!handleSourceChange()) {
                                qCritical() << "V4L2Decoder: failed to handle SOURCE_CHANGE";
                                continue;
                            }

                            // Start CAPTURE streaming
                            if (!capture_started) {
                                int type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
                                if (ioctl(fd_, VIDIOC_STREAMON, &type) < 0) {
                                    setError(std::string("STREAMON CAPTURE failed: ") + strerror(errno));
                                } else {
                                    capture_started = true;
                                    qInfo() << "V4L2Decoder: CAPTURE streaming started";
                                }
                            }
                        }
                    } else if (ev.type == V4L2_EVENT_EOS) {
                        qInfo() << "V4L2Decoder: EOS event";
                    }
                }
            }

            // Handle errors
            if (pfd.revents & POLLERR) {
                qWarning() << "V4L2Decoder: POLLERR received";
                break;
            }

            // Dequeue decoded frame
            if ((pfd.revents & POLLIN) && capture_started) {
                struct v4l2_buffer out_buf = {};
                struct v4l2_plane out_planes[4] = {};

                out_buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
                out_buf.memory = V4L2_MEMORY_DMABUF;
                out_buf.m.planes = out_planes;
                out_buf.length = capabilities_.plane_count;

                if (ioctl(fd_, VIDIOC_DQBUF, &out_buf) == 0) {
                    processOutputBuffer(out_buf.index);
                }
            }

            // Refresh poll
            pfd.revents = 0;
        }
    }

    qInfo() << "V4L2Decoder: decode loop exited";
}

bool V4L2Decoder::processNal(const NalUnit& nal)
{
    // Dequeue completed input buffers
    struct v4l2_buffer dq_buf_in = {};
    struct v4l2_plane dq_plane_in = {};
    dq_buf_in.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    dq_buf_in.memory = V4L2_MEMORY_DMABUF;
    dq_buf_in.m.planes = &dq_plane_in;
    dq_buf_in.length = 1;

    while (ioctl(fd_, VIDIOC_DQBUF, &dq_buf_in) == 0) {
        input_buffers_->markFree(dq_buf_in.index);
    }

    // Get a free input buffer
    int buffer_idx = input_buffers_->getFreeBufferIndex();

    if (buffer_idx < 0) {
        // No free buffers, try to wait
        struct pollfd pfd = {};
        pfd.fd = fd_;
        pfd.events = POLLOUT | POLLERR;

        if (poll(&pfd, 1, 50) > 0 && (pfd.revents & POLLOUT)) {
            if (ioctl(fd_, VIDIOC_DQBUF, &dq_buf_in) == 0) {
                input_buffers_->markFree(dq_buf_in.index);
                buffer_idx = dq_buf_in.index;
            }
        }
    }

    if (buffer_idx < 0) {
        qWarning() << "V4L2Decoder: no free input buffers";
        frames_dropped_++;
        return false;
    }

    return queueInputBuffer(nal.data.data(), nal.data.size(), nal.timestamp_us);
}

bool V4L2Decoder::queueInputBuffer(const uint8_t* data, size_t size, int64_t timestamp_us)
{
    int buffer_idx = input_buffers_->getFreeBufferIndex();
    if (buffer_idx < 0) {
        return false;
    }

    auto& buf_info = input_buffers_->getInfo(buffer_idx);

    // Validate buffer
    if (!buf_info.mapped_addr || buf_info.size == 0) {
        qCritical() << "V4L2Decoder: invalid input buffer" << buffer_idx;
        return false;
    }

    // DMA-BUF sync start (for CPU write)
    DmaHeap::syncStart(buf_info.fd, true);

    // Copy data to buffer
    size_t copy_size = std::min(size, buf_info.size);
    std::memcpy(buf_info.mapped_addr, data, copy_size);

    // DMA-BUF sync end
    DmaHeap::syncEnd(buf_info.fd, true);

    // Queue the buffer
    struct v4l2_buffer buf = {};
    struct v4l2_plane plane = {};

    buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    buf.memory = V4L2_MEMORY_DMABUF;
    buf.index = buffer_idx;
    buf.m.planes = &plane;
    buf.length = 1;
    buf.timestamp.tv_sec = timestamp_us / 1000000;
    buf.timestamp.tv_usec = timestamp_us % 1000000;

    plane.m.fd = buf_info.fd;
    plane.bytesused = copy_size;
    plane.length = buf_info.size;

    if (ioctl(fd_, VIDIOC_QBUF, &buf) < 0) {
        qCritical() << "V4L2Decoder: QBUF OUTPUT failed:" << strerror(errno);
        return false;
    }

    input_buffers_->markInUse(buffer_idx);
    return true;
}

bool V4L2Decoder::processOutputBuffer(uint32_t index)
{
    if (!frame_callback_ || index >= output_buffers_->count()) {
        // No callback or invalid index, just requeue
        requeueOutputBuffer(index);
        return true;
    }

    auto& buf_info = output_buffers_->getInfo(index);

    // Create PlaceboFrame
    PlaceboFrame frame;
    frame.buffer_index = index;
    frame.width = capabilities_.width;
    frame.height = capabilities_.height;
    frame.pixel_format = capabilities_.pixel_format;
    frame.colorspace = capabilities_.colorspace;
    frame.ycbcr_enc = capabilities_.ycbcr_enc;
    frame.quantization = capabilities_.quantization;
    frame.xfer_func = capabilities_.xfer_func;
    frame.plane_count = capabilities_.plane_count;
    frame.drm_modifier = 0;  // Linear
    frame.sequence = frame_sequence_++;

    // Set plane info
    // For single-buffer multi-plane formats (like NV12), all planes share the same fd
    frame.planes[0].fd = buf_info.fd;
    frame.planes[0].offset = 0;
    frame.planes[0].pitch = output_plane_strides_[0];
    frame.planes[0].size = output_plane_sizes_[0];

    if (capabilities_.plane_count >= 2) {
        frame.planes[1].fd = buf_info.fd;
        frame.planes[1].offset = capabilities_.width * capabilities_.height;  // UV plane after Y
        frame.planes[1].pitch = output_plane_strides_[0];  // Same stride for NV12
        frame.planes[1].size = output_plane_sizes_[0] / 2;
    }

    frames_decoded_++;

    // Invoke callback (buffer will be recycled when renderer calls recycle_buffer)
    frame_callback_(frame);

    return true;
}

bool V4L2Decoder::requeueOutputBuffer(uint32_t index)
{
    if (index >= output_buffers_->count()) {
        return false;
    }

    struct v4l2_buffer buf = {};
    struct v4l2_plane planes[4] = {};

    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    buf.memory = V4L2_MEMORY_DMABUF;
    buf.index = index;
    buf.m.planes = planes;
    buf.length = capabilities_.plane_count > 0 ? capabilities_.plane_count : 1;

    auto& buf_info = output_buffers_->getInfo(index);

    // For single-buffer formats, only first plane has fd
    planes[0].m.fd = buf_info.fd;
    planes[0].length = buf_info.size;

    if (ioctl(fd_, VIDIOC_QBUF, &buf) < 0) {
        qCritical() << "V4L2Decoder: QBUF CAPTURE failed for buffer" << index
                    << ":" << strerror(errno);
        return false;
    }

    return true;
}

#endif // ENABLE_V4L2_GL_PLAYER
