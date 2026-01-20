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

// V4L2 headers
#include <linux/videodev2.h>

// DRM format definitions
#ifndef DRM_FORMAT_NV12
#define DRM_FORMAT_NV12 0x3231564E
#endif


V4L2Decoder::V4L2Decoder()
{
    qDebug() << "V4L2Decoder: created";
}

V4L2Decoder::~V4L2Decoder()
{
    stop();
    close_device();
    qDebug() << "V4L2Decoder: destroyed";
}

void V4L2Decoder::set_frame_callback(FrameCallback callback)
{
    m_frame_callback = std::move(callback);
}

void V4L2Decoder::set_capabilities_callback(CapabilitiesCallback callback)
{
    m_caps_callback = std::move(callback);
}

bool V4L2Decoder::init(const std::string& device, Codec codec)
{
    if (m_running) {
        set_error("Decoder already running");
        return false;
    }

    m_device_path = device;
    m_codec = codec;

    qInfo() << "V4L2Decoder: initializing with device" << device.c_str()
            << "codec:" << (codec == Codec::H264 ? "H264" : "H265");

    if (!open_device()) {
        return false;
    }

    if (!setup_output_format()) {
        close_device();
        return false;
    }

    qInfo() << "V4L2Decoder: initialized successfully";
    return true;
}

bool V4L2Decoder::start()
{
    if (m_running) {
        qWarning() << "V4L2Decoder: already running";
        return true;
    }

    if (m_fd < 0) {
        set_error("Device not opened");
        return false;
    }

    m_stop_requested = false;
    m_running = true;

    // Start decode thread
    m_decode_thread = std::make_unique<std::thread>(&V4L2Decoder::decode_thread_func, this);

    qInfo() << "V4L2Decoder: started";
    return true;
}

void V4L2Decoder::stop()
{
    if (!m_running) return;

    qInfo() << "V4L2Decoder: stopping...";

    m_stop_requested = true;
    m_input_cv.notify_all();

    if (m_decode_thread && m_decode_thread->joinable()) {
        m_decode_thread->join();
    }
    m_decode_thread.reset();

    m_running = false;

    // Clear input queue
    {
        std::lock_guard<std::mutex> lock(m_input_mutex);
        while (!m_input_queue.empty()) {
            m_input_queue.pop();
        }
    }

    qInfo() << "V4L2Decoder: stopped";
}

void V4L2Decoder::feed_nal_unit(const uint8_t* data, size_t size, int64_t timestamp_us)
{
    if (!m_running || !data || size == 0) return;

    NalUnit nal;
    nal.data.assign(data, data + size);
    nal.timestamp_us = timestamp_us;

    {
        std::lock_guard<std::mutex> lock(m_input_mutex);
        m_input_queue.push(std::move(nal));
    }
    m_input_cv.notify_one();

    m_nal_units_received++;
}

V4L2Decoder::Stats V4L2Decoder::get_stats() const
{
    return Stats{
        m_nal_units_received.load(),
        m_frames_decoded.load(),
        m_decode_errors.load()
    };
}

void V4L2Decoder::reset_stats()
{
    m_nal_units_received = 0;
    m_frames_decoded = 0;
    m_decode_errors = 0;
}

std::string V4L2Decoder::get_last_error() const
{
    std::lock_guard<std::mutex> lock(m_error_mutex);
    return m_last_error;
}

void V4L2Decoder::recycle_buffer(uint32_t buffer_index)
{
    if (!m_running || m_fd < 0) {
        return;
    }

    // TODO: Implement actual V4L2 buffer requeue
    // This should call VIDIOC_QBUF to return the buffer to the CAPTURE queue
    //
    // struct v4l2_buffer buf = {};
    // buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    // buf.memory = V4L2_MEMORY_DMABUF;
    // buf.index = buffer_index;
    // ... set up planes ...
    // if (ioctl(m_fd, VIDIOC_QBUF, &buf) < 0) {
    //     qWarning() << "V4L2Decoder: failed to requeue buffer" << buffer_index;
    // }

    qDebug() << "V4L2Decoder::recycle_buffer" << buffer_index << "- TODO implement";
}

void V4L2Decoder::set_error(const std::string& error)
{
    std::lock_guard<std::mutex> lock(m_error_mutex);
    m_last_error = error;
    qWarning() << "V4L2Decoder error:" << error.c_str();
}

// ============================================================================
// V4L2 Device Operations - SKELETON IMPLEMENTATION
// TODO: Implement actual V4L2 M2M operations
// ============================================================================

bool V4L2Decoder::open_device()
{
    qDebug() << "V4L2Decoder::open_device" << m_device_path.c_str();

    m_fd = ::open(m_device_path.c_str(), O_RDWR | O_NONBLOCK);
    if (m_fd < 0) {
        set_error("Failed to open device: " + std::string(strerror(errno)));
        return false;
    }

    // Query capabilities
    struct v4l2_capability cap;
    if (ioctl(m_fd, VIDIOC_QUERYCAP, &cap) < 0) {
        set_error("VIDIOC_QUERYCAP failed: " + std::string(strerror(errno)));
        close_device();
        return false;
    }

    // Check for M2M support
    if (!(cap.capabilities & V4L2_CAP_VIDEO_M2M_MPLANE) &&
        !(cap.capabilities & V4L2_CAP_VIDEO_M2M)) {
        set_error("Device does not support M2M");
        close_device();
        return false;
    }

    qInfo() << "V4L2Decoder: opened device" << (const char*)cap.card
            << "driver:" << (const char*)cap.driver;

    return true;
}

void V4L2Decoder::close_device()
{
    if (m_fd >= 0) {
        ::close(m_fd);
        m_fd = -1;
    }
}

bool V4L2Decoder::setup_output_format()
{
    // TODO: Set input (OUTPUT) format based on codec
    // V4L2_PIX_FMT_H264 or V4L2_PIX_FMT_HEVC

    qDebug() << "V4L2Decoder::setup_output_format - TODO implement";

    // Placeholder - actual implementation needed
    return true;
}

bool V4L2Decoder::setup_capture_format()
{
    // TODO: Negotiate output (CAPTURE) format
    // Query supported formats, select NV12 or similar

    qDebug() << "V4L2Decoder::setup_capture_format - TODO implement";

    // Placeholder - will be called after first frame when resolution is known
    return true;
}

bool V4L2Decoder::allocate_buffers()
{
    // TODO: VIDIOC_REQBUFS for OUTPUT and CAPTURE queues
    // Request DMABUF export for CAPTURE buffers

    qDebug() << "V4L2Decoder::allocate_buffers - TODO implement";
    return true;
}

void V4L2Decoder::free_buffers()
{
    // TODO: Unmap and free buffers
    qDebug() << "V4L2Decoder::free_buffers - TODO implement";
}

bool V4L2Decoder::stream_on()
{
    // TODO: VIDIOC_STREAMON for both queues
    qDebug() << "V4L2Decoder::stream_on - TODO implement";
    return true;
}

void V4L2Decoder::stream_off()
{
    // TODO: VIDIOC_STREAMOFF for both queues
    qDebug() << "V4L2Decoder::stream_off - TODO implement";
}

bool V4L2Decoder::queue_input_buffer(const NalUnit& nal)
{
    // TODO: Copy NAL to OUTPUT buffer and VIDIOC_QBUF
    Q_UNUSED(nal);
    qDebug() << "V4L2Decoder::queue_input_buffer - TODO implement";
    return true;
}

bool V4L2Decoder::dequeue_output_frame(PlaceboFrame& frame)
{
    // TODO: VIDIOC_DQBUF from CAPTURE queue
    // Export DMABUF fd and populate PlaceboFrame
    Q_UNUSED(frame);
    qDebug() << "V4L2Decoder::dequeue_output_frame - TODO implement";
    return false;
}

void V4L2Decoder::decode_thread_func()
{
    qDebug() << "V4L2Decoder: decode thread started";

    // TODO: Implement actual decode loop:
    // 1. Wait for NAL units in input queue
    // 2. Queue NAL to V4L2 OUTPUT
    // 3. Poll for completed CAPTURE buffers
    // 4. On first frame, setup CAPTURE format and notify capabilities
    // 5. Invoke frame callback with decoded frame

    while (!m_stop_requested) {
        NalUnit nal;

        // Wait for input
        {
            std::unique_lock<std::mutex> lock(m_input_mutex);
            m_input_cv.wait_for(lock, std::chrono::milliseconds(100), [this]() {
                return !m_input_queue.empty() || m_stop_requested;
            });

            if (m_stop_requested) break;

            if (m_input_queue.empty()) continue;

            nal = std::move(m_input_queue.front());
            m_input_queue.pop();
        }

        // TODO: Process NAL unit through V4L2
        // For now, just log that we received data
        // qDebug() << "V4L2Decoder: received NAL unit, size:" << nal.data.size();

        // Placeholder: simulate decode and notify capabilities on first frame
        if (!m_capabilities_valid) {
            // TODO: Get actual values from V4L2 after first frame decode
            m_capabilities.width = 1920;  // Placeholder
            m_capabilities.height = 1080;
            m_capabilities.output_fourcc = DRM_FORMAT_NV12;
            m_capabilities.plane_count = 2;
            m_capabilities.supports_dmabuf = true;
            m_capabilities_valid = true;

            if (m_caps_callback) {
                m_caps_callback(m_capabilities);
            }
        }

        // TODO: When frame is decoded, call:
        // PlaceboFrame frame;
        // if (dequeue_output_frame(frame)) {
        //     m_frames_decoded++;
        //     if (m_frame_callback) {
        //         m_frame_callback(std::move(frame));
        //     }
        // }
    }

    qDebug() << "V4L2Decoder: decode thread finished";
}

#endif // ENABLE_V4L2_GL_PLAYER
