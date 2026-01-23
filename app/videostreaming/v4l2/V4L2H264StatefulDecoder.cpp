// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD
#include "V4L2H264StatefulDecoder.h"

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


// Debug logging - define QOPENHD_V4L2_DEBUG to enable verbose traces
#ifdef QOPENHD_V4L2_DEBUG
#define V4L2_DEBUG(msg) qDebug() << "V4L2Decoder:" << msg
#else
#define V4L2_DEBUG(msg) do {} while(0)
#endif

// Configuration constants
static constexpr uint32_t INPUT_BUFFER_COUNT = 6;
static constexpr uint32_t OUTPUT_BUFFER_COUNT = 4;
static constexpr uint32_t DEFAULT_INPUT_BUFFER_SIZE = 2 * 1024 * 1024;  // 2MB for H.264/H.265


V4L2H264StatefulDecoder::V4L2H264StatefulDecoder(
    std::unique_ptr<V4L2Device> device,
    std::unique_ptr<DmaBuffersAllocator> dmaBuffersAllocator)
    : device_(std::move(device)), dmaBuffersAllocator_(std::move(dmaBuffersAllocator))
{
    qDebug() << "V4L2H264StatefulDecoder created";
}

V4L2H264StatefulDecoder::~V4L2H264StatefulDecoder()
{
    stop();
    // device_ will be automatically destroyed here
    qDebug() << "V4L2Decoder: destroyed";
}

void V4L2H264StatefulDecoder::set_frame_callback(FrameCallback callback)
{
    frame_callback_ = std::move(callback);
}

void V4L2H264StatefulDecoder::set_capabilities_callback(CapabilitiesCallback callback)
{
    capabilities_callback_ = std::move(callback);
}

std::unique_ptr<V4L2H264StatefulDecoder> V4L2H264StatefulDecoder::Create(
    std::unique_ptr<V4L2Device> device)
{
    if (!device) {
        return nullptr;
    }

    struct v4l2_capability cap = {};
    if (device->QueryCapabilities(&cap) < 0) {
        qWarning() << "V4L2Decoder::Create: failed to query caps";
        return nullptr;
    }

    // Check for M2M support
    if (!(cap.capabilities & V4L2_CAP_VIDEO_M2M_MPLANE)) {
        qWarning() << "Device does not support M2M MPLANE";
        return nullptr;
    }

    auto dmaBuffersAllocator = DmaBuffersAllocator::Create();
    auto decoder = std::unique_ptr<V4L2H264StatefulDecoder>(
        new V4L2H264StatefulDecoder(
            std::move(device),
            std::move(dmaBuffersAllocator)));

    return decoder;
}

void V4L2H264StatefulDecoder::Init()
{
    SubscribeToEvents();
    ConfigureFormats();
    SetupBuffers();
}

void V4L2H264StatefulDecoder::SubscribeToEvents()
{
    struct v4l2_event_subscription sourceChanged = {};
    sourceChanged.type = V4L2_EVENT_SOURCE_CHANGE;
    if (device_->SubscribeEvent(&sourceChanged) < 0) {
        qWarning() << "V4L2Decoder: failed to subscribe to SOURCE_CHANGE event";
    }

    struct v4l2_event_subscription eos = {};
    eos.type = V4L2_EVENT_EOS;
    if (device_->SubscribeEvent(&eos) < 0) {
        qWarning() << "V4L2Decoder: failed to subscribe to EOS event";
    }
}

void V4L2H264StatefulDecoder::ConfigureFormats()
{
    struct v4l2_format captureFormat = {};
    captureFormat.type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
    device_->GetFormat(&captureFormat);
    captureFormat.fmt.pix_mp.width = 1920;
    captureFormat.fmt.pix_mp.height = 1080;
    device_->SetFormat(&captureFormat);

    pixelFormat_ = captureFormat.fmt.pix_mp.pixelformat;

    struct v4l2_format outputFormat = {};
    outputFormat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    device_->GetFormat(&outputFormat);
    outputFormat.fmt.pix_mp.width = 1920;
    outputFormat.fmt.pix_mp.height = 1080;
    device_->SetFormat(&outputFormat);
}

void V4L2H264StatefulDecoder::SetupBuffers()
{

}

bool V4L2H264StatefulDecoder::start()
{
    if (running_.load()) {
        return true;
    }

    qInfo() << "V4L2Decoder: starting...";

    stop_requested_ = false;
    running_ = true;
    Init();

    // Start decode thread
    //decode_thread_ = std::thread(&V4L2H264StatefulDecoder::decodeLoop, this);

    qInfo() << "V4L2Decoder: started";
    return true;
}

void V4L2H264StatefulDecoder::stop()
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



    // Device will be automatically closed by V4L2Device destructor

    running_ = false;
    qInfo() << "V4L2Decoder: stopped. Decoded frames:" << frames_decoded_.load();
}

void V4L2H264StatefulDecoder::feed_nal_unit(const uint8_t* data, size_t size, int64_t timestamp_us)
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

void V4L2H264StatefulDecoder::recycle_buffer(uint32_t buffer_index)
{
    std::lock_guard<std::mutex> lock(recycle_mutex_);
    recycle_queue_.push(buffer_index);
}

V4L2H264StatefulDecoder::Stats V4L2H264StatefulDecoder::get_stats() const
{
    Stats stats;
    stats.frames_decoded = frames_decoded_.load();
    stats.frames_dropped = frames_dropped_.load();
    stats.nals_received = nals_received_.load();
    stats.decode_errors = decode_errors_.load();
    return stats;
}

void V4L2H264StatefulDecoder::reset_stats()
{
    frames_decoded_ = 0;
    frames_dropped_ = 0;
    nals_received_ = 0;
    decode_errors_ = 0;
}



