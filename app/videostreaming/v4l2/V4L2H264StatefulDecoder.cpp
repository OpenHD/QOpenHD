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
static constexpr uint32_t ENCODED_BUFFER_COUNT = 6;
static constexpr uint32_t DECODED_BUFFER_COUNT = 4;
static constexpr uint32_t DEFAULT_ENCODED_BUFFER_SIZE = 2 * 1024 * 1024;  // 2MB for H.264/H.265
static constexpr uint32_t DEFAULT_DECODED_BUFFER_SIZE = 10 * 1024 * 1024;  // 10MB for decoded frames


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
    device_->GetEncodedBuffersQueue()->StreamOn();
    device_->GetDecodedBuffersQueue()->StreamOn();
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
    // Allocate buffers for encoded frames
    // We use really safe size that have to be enough for any stream - 2MB
    std::vector<std::unique_ptr<DmaBuffer>> encodedBuffers;
    encodedBuffers.reserve(ENCODED_BUFFER_COUNT);
    for (uint32_t i = 0; i < ENCODED_BUFFER_COUNT; ++i)
    {
        auto buffer = dmaBuffersAllocator_->Allocate(DEFAULT_ENCODED_BUFFER_SIZE);
        buffer->MapBuffer();
        encodedBuffers.push_back(std::move(buffer));
    }

    // Register buffers with the device's encoded buffers queue
    device_->GetEncodedBuffersQueue()->RegisterBuffers(std::move(encodedBuffers));

    // Allocate buffers for decoded frames
    // We use really safe size that have to be enough for any stream - 10MB
    std::vector<std::unique_ptr<DmaBuffer>> decodedBuffers;
    decodedBuffers.reserve(DECODED_BUFFER_COUNT);
    for (uint32_t i = 0; i < DECODED_BUFFER_COUNT; ++i)
    {
        auto buffer = dmaBuffersAllocator_->Allocate(DEFAULT_DECODED_BUFFER_SIZE);
        decodedBuffers.push_back(std::move(buffer));
    }

    // Register buffers with the device's decoded buffers queue
    device_->GetDecodedBuffersQueue()->RegisterBuffers(std::move(decodedBuffers));
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

    // Wait for decode thread
    if (decode_thread_.joinable()) {
        decode_thread_.join();
    }



    // Device will be automatically closed by V4L2Device destructor

    running_ = false;
    qInfo() << "V4L2Decoder: stopped. Decoded frames:" << frames_decoded_.load();
}

void V4L2H264StatefulDecoder::feed_nal_unit(gsl::span<const uint8_t> data)
{
    if (!running_.load() || data.empty()) {
        return;
    }

    // Write NAL unit directly to V4L2 device (blocking)
    device_->GetEncodedBuffersQueue()->WaitWrite(data);
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
    stats.decode_errors = decode_errors_.load();
    return stats;
}

void V4L2H264StatefulDecoder::reset_stats()
{
    frames_decoded_ = 0;
    frames_dropped_ = 0;
    decode_errors_ = 0;
}



