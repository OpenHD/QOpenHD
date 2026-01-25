#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_pipeline.h"
#include "v4l2_decoder_detector.h"

#include <gsl/span>
#include <QDebug>


V4L2Pipeline::V4L2Pipeline(const Config& config, const DecoderInfo& decoderInfo)
    : m_config(config)
{
    qDebug() << "V4L2Pipeline: creating with decoder" << decoderInfo.device_path.c_str();

    qInfo() << "V4L2Pipeline: initializing...";
    qInfo() << "  RTP:" << config.rtp_listen_addr.c_str() << ":" << config.rtp_listen_port;
    qInfo() << "  Codec:" << (decoderInfo.codec == VideoCodec::H264 ? "H264" : "H265");
    qInfo() << "  V4L2 device:" << decoderInfo.device_path.c_str();
    qInfo() << "  Driver:" << decoderInfo.driver_name.c_str();
    qInfo() << "  Type:" << (decoderInfo.type == V4L2DecoderType::Stateless ? "Stateless" : "Stateful");
    if (!decoderInfo.media_device_path.empty()) {
        qInfo() << "  Media device:" << decoderInfo.media_device_path.c_str();
    }

    // Create components
    m_rtp_receiver = std::make_unique<UvgRtpReceiver>();

    auto device = V4L2Device::Open(decoderInfo.device_path);
    m_decoder = V4L2H264StatefulDecoder::Create(std::move(device));

    if (!m_rtp_receiver->init(config.rtp_listen_addr, config.rtp_listen_port, decoderInfo.codec)) {
        qFatal("V4L2Pipeline: failed to init RTP receiver: %s",
               m_rtp_receiver->get_last_error().c_str());
    }

    // Wire up callbacks
    m_rtp_receiver->set_frame_callback([this](uvgrtp::frame::rtp_frame* frame) {
        on_rtp_frame_received(frame);
    });

    // Note: decoder callbacks removed - we use explicit polling in processDecodedFramesLoop

    m_initialized = true;
    qInfo() << "V4L2Pipeline: initialized successfully"
            << (config.stub_presenter_mode ? "(STUB MODE - frames will be recycled immediately)" : "");
}

V4L2Pipeline::~V4L2Pipeline()
{
    stop();
    qDebug() << "V4L2Pipeline: destroyed";
}

bool V4L2Pipeline::start()
{
    if (!m_initialized) {
        qWarning() << "V4L2Pipeline: not initialized";
        return false;
    }

    if (m_running) {
        qWarning() << "V4L2Pipeline: already running";
        return true;
    }

    qInfo() << "V4L2Pipeline: starting...";

    // Start decoder first (needs to be ready to receive NALs)
    if (!m_decoder->start()) {
        qCritical() << "V4L2Pipeline: failed to start decoder";
        return false;
    }

    m_running = true;

    // Start Thread 1: RTP frame processing (before RTP receiver to be ready for frames)
    m_processing_thread = std::thread(&V4L2Pipeline::processRtpFrameLoop, this);

    // Start Thread 2: Decoded frame processing
    m_decode_output_thread = std::thread(&V4L2Pipeline::processDecodedFramesLoop, this);

    // Start RTP receiver
    if (!m_rtp_receiver->start()) {
        qCritical() << "V4L2Pipeline: failed to start RTP receiver";
        m_running = false;
        m_rtp_queue_cv.notify_all();
        if (m_processing_thread.joinable()) {
            m_processing_thread.join();
        }
        if (m_decode_output_thread.joinable()) {
            m_decode_output_thread.join();
        }
        m_decoder->stop();
        return false;
    }

    qInfo() << "V4L2Pipeline: started with 2 processing threads";
    return true;
}

void V4L2Pipeline::stop()
{
    if (!m_running) return;

    qInfo() << "V4L2Pipeline: stopping...";

    // Stop frame queue first (unblocks waiter thread)
    m_frame_queue.stop();

    // Stop RTP receiver (stop incoming data)
    if (m_rtp_receiver) {
        m_rtp_receiver->stop();
    }

    // Signal processing threads to stop and wake them up
    m_running = false;
    m_rtp_queue_cv.notify_all();

    // Wait for Thread 1: RTP frame processing
    if (m_processing_thread.joinable()) {
        m_processing_thread.join();
    }

    // Wait for Thread 2: Decoded frame processing
    // Note: This thread may be blocked in WaitForDecodedFrame()
    // TODO: Add proper interrupt mechanism for decoder wait
    if (m_decode_output_thread.joinable()) {
        m_decode_output_thread.join();
    }

    // Drain remaining RTP frames in queue
    {
        std::lock_guard<std::mutex> lock(m_rtp_queue_mutex);
        while (!m_rtp_frame_queue.empty()) {
            uvgrtp::frame::rtp_frame* frame = m_rtp_frame_queue.front();
            m_rtp_frame_queue.pop();
            UvgRtpReceiver::deallocate_frame(frame);
        }
    }

    // Stop decoder
    if (m_decoder) {
        m_decoder->stop();
    }

    // Reset frame queue (clears any remaining frames)
    m_frame_queue.reset();

    m_format_ready = false;

    qInfo() << "V4L2Pipeline: stopped";
}

const V4L2H264StatefulDecoder::Capabilities& V4L2Pipeline::get_decoder_capabilities() const
{
    static V4L2H264StatefulDecoder::Capabilities empty_caps;
    if (!m_decoder) return empty_caps;
    return m_decoder->get_capabilities();
}

V4L2Pipeline::Stats V4L2Pipeline::get_stats() const
{
    Stats stats;

    stats.rtp_frames_received = m_rtp_frames_received.load();
    stats.rtp_bytes_received = m_rtp_bytes_received.load();
    stats.nals_fed_to_decoder = m_nals_fed_to_decoder.load();
    stats.frames_from_decoder = m_frames_from_decoder.load();
    stats.frames_recycled_stub = m_frames_recycled_stub.load();

    if (m_decoder) {
        stats.decoder = m_decoder->get_stats();
    }
    stats.queue = m_frame_queue.get_stats();

    return stats;
}

void V4L2Pipeline::reset_stats()
{
    m_rtp_frames_received = 0;
    m_rtp_bytes_received = 0;
    m_nals_fed_to_decoder = 0;
    m_frames_from_decoder = 0;
    m_frames_recycled_stub = 0;

    if (m_decoder) {
        m_decoder->reset_stats();
    }
    m_frame_queue.reset_stats();
}

std::string V4L2Pipeline::get_last_error() const
{
    // Return first non-empty error
    if (m_rtp_receiver) {
        std::string err = m_rtp_receiver->get_last_error();
        if (!err.empty()) return "RTP: " + err;
    }

    if (m_decoder) {
        std::string err = m_decoder->get_last_error();
        if (!err.empty()) return "Decoder: " + err;
    }
    return "";
}

void V4L2Pipeline::on_rtp_frame_received(uvgrtp::frame::rtp_frame* frame)
{
    // Just enqueue the frame - processing happens in dedicated thread
    {
        std::lock_guard<std::mutex> lock(m_rtp_queue_mutex);
        m_rtp_frame_queue.push(frame);
    }
    m_rtp_queue_cv.notify_one();
}

void V4L2Pipeline::processRtpFrameLoop()
{
    qInfo() << "V4L2Pipeline: Thread 1 (RTP processing) started";

    while (m_running.load()) {
        uvgrtp::frame::rtp_frame* frame = nullptr;

        // Wait for a frame
        {
            std::unique_lock<std::mutex> lock(m_rtp_queue_mutex);
            m_rtp_queue_cv.wait(lock, [this] {
                return !m_rtp_frame_queue.empty() || !m_running.load();
            });

            if (!m_running.load() && m_rtp_frame_queue.empty()) {
                break;
            }

            if (!m_rtp_frame_queue.empty()) {
                frame = m_rtp_frame_queue.front();
                m_rtp_frame_queue.pop();
            }
        }

        if (frame) {
            // Update statistics
            m_rtp_frames_received++;
            m_rtp_bytes_received += frame->payload_len;

            // Feed NAL unit to decoder (blocking call)
            if (m_decoder && frame->payload && frame->payload_len > 0) {
                gsl::span<const uint8_t> nal_data(frame->payload, frame->payload_len);
                m_decoder->feed_nal_unit(nal_data);
                m_nals_fed_to_decoder++;
                // qInfo() << "V4L2Pipeline: fed NAL unit of size"
                //         << frame->payload_len << "bytes to decoder";
            }

            // Return frame to uvgRTP
            UvgRtpReceiver::deallocate_frame(frame);
        }
    }

    qInfo() << "V4L2Pipeline: Thread 1 (RTP processing) stopped";
}

void V4L2Pipeline::processDecodedFramesLoop()
{
    qInfo() << "V4L2Pipeline: Thread 2 (decoded frame processing) started"
             << (m_config.stub_presenter_mode ? "[STUB MODE]" : "[NORMAL MODE]");

    while (m_running.load()) {
        try {
            // Wait for decoded frame (blocking)
            DecodedFrame decoded_frame = m_decoder->wait_for_decoded_frame();

            if (!decoded_frame.is_valid()) {
                qWarning() << "V4L2Pipeline: received invalid decoded frame";
                continue;
            }

            m_frames_from_decoder++;

            if (m_config.stub_presenter_mode) {
                // STUB MODE: Immediately recycle buffer back to decoder
                // This is for testing RTP reception and decoding without display
                m_decoder->recycle_decoded_buffer(decoded_frame.buffer_index);
                m_frames_recycled_stub++;

                // Log every 100 frames for monitoring
                if (m_frames_recycled_stub % 100 == 0) {
                    qDebug() << "V4L2Pipeline: [STUB] decoded and recycled"
                             << m_frames_recycled_stub.load() << "frames";
                }
            } else {
                // NORMAL MODE: Pass frame to presenter via PlaceboFrameQueue
                PlaceboFrame placebo_frame;
                placebo_frame.buffer_index = decoded_frame.buffer_index;
                placebo_frame.plane_count = decoded_frame.planes_count;
                placebo_frame.timestamp_us = decoded_frame.timestamp_us;
                placebo_frame.sequence = m_frames_from_decoder.load();

                // Copy plane information
                for (uint32_t i = 0; i < decoded_frame.planes_count && i < 4; ++i) {
                    placebo_frame.planes[i].fd = decoded_frame.planes[i].fd;
                    placebo_frame.planes[i].offset = decoded_frame.planes[i].offset;
                    placebo_frame.planes[i].pitch = decoded_frame.planes[i].length;
                    placebo_frame.planes[i].size = decoded_frame.planes[i].bytesused;
                }

                // TODO: Fill in width, height, pixel_format from decoder capabilities
                // once we handle SOURCE_CHANGE event properly

                on_frame_decoded(std::move(placebo_frame));
            }
        } catch (const std::exception& e) {
            if (m_running.load()) {
                qWarning() << "V4L2Pipeline: error waiting for decoded frame:" << e.what();
            }
            // On error, check if we should continue
            if (!m_running.load()) {
                break;
            }
        }
    }

    qInfo() << "V4L2Pipeline: Thread 2 (decoded frame processing) stopped";
}

void V4L2Pipeline::on_frame_decoded(PlaceboFrame frame)
{
    // Push frame to queue (this will trigger render via waiter thread)
    if (m_running) {
        // First, check for any buffers returned by renderer and recycle them
        PlaceboFrame returned_frame;
        while (m_frame_queue.try_pop_returned(returned_frame)) {
            if (returned_frame.buffer_index != UINT32_MAX && m_decoder) {
                m_decoder->recycle_buffer(returned_frame.buffer_index);
            }
        }

        // Now push the new decoded frame
        m_frame_queue.push(frame);
    }
    // Note: if not running, V4L2 will handle buffer cleanup when stopping
}

void V4L2Pipeline::on_decoder_capabilities(const V4L2H264StatefulDecoder::Capabilities& caps)
{
    qInfo() << "V4L2Pipeline: decoder capabilities:"
            << caps.width << "x" << caps.height
            << "pixel_format:" << Qt::hex << caps.pixel_format
            << "planes:" << caps.plane_count;

    // Update frame format for renderer
    m_frame_format.width = caps.width;
    m_frame_format.height = caps.height;
    m_frame_format.pixel_format = caps.pixel_format;
    m_frame_format.plane_count = caps.plane_count;
    m_frame_format.colorspace = caps.colorspace;
    m_frame_format.ycbcr_enc = caps.ycbcr_enc;
    m_frame_format.quantization = caps.quantization;
    m_frame_format.xfer_func = caps.xfer_func;

    m_format_ready = true;
}

#endif // ENABLE_V4L2_GL_PLAYER
