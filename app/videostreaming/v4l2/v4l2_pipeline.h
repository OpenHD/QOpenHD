// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef V4L2_PIPELINE_H
#define V4L2_PIPELINE_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <memory>
#include <string>
#include <atomic>

#include "uvgrtp_receiver.h"
#include "V4L2H264StatefulDecoder.h"
#include "v4l2_decoder_detector.h"
#include "../libplacebo/placebo_frame_queue.h"
#include "../libplacebo/placebo_renderer.h"

/**
 * @brief Complete video pipeline: uvgRTP → V4L2 Decoder → libplacebo Renderer
 *
 * This class coordinates the entire video pipeline:
 * 1. UvgRtpReceiver - receives RTP packets and reassembles NAL units
 * 2. V4L2Decoder - decodes NAL units using hardware V4L2 M2M decoder
 * 3. PlaceboFrameQueue - thread-safe frame handoff to renderer
 *
 * The PlaceboVideoItem connects to this pipeline to receive frames.
 *
 * Thread model:
 * - uvgRTP thread: receives RTP packets, reassembles NALs
 * - V4L2 decoder thread: decodes NALs, produces DMA-BUF frames
 * - Qt render thread: renders frames via PlaceboRenderer
 */
class V4L2Pipeline
{
public:
    /**
     * @brief Pipeline configuration
     */
    struct Config {
        // RTP reception
        std::string rtp_listen_addr = "0.0.0.0";
        uint16_t rtp_listen_port = 5600;
    };

    /**
     * @brief Construct pipeline with configuration and decoder info
     * @param config RTP configuration
     * @param decoder_info Detected V4L2 decoder to use
     */
    V4L2Pipeline(const Config& config, const V4L2DecoderDetector::DecoderInfo& decoder_info);
    ~V4L2Pipeline();

    // Delete copy/move
    V4L2Pipeline(const V4L2Pipeline&) = delete;
    V4L2Pipeline& operator=(const V4L2Pipeline&) = delete;

    /**
     * @brief Start the pipeline
     * @return true on success
     */
    bool start();

    /**
     * @brief Stop the pipeline
     */
    void stop();

    /**
     * @brief Check if pipeline is running
     */
    bool is_running() const { return m_running.load(); }

    /**
     * @brief Get the frame queue (for PlaceboVideoItem)
     */
    PlaceboFrameQueue& get_frame_queue() { return m_frame_queue; }

    /**
     * @brief Get current decoder capabilities
     * Only valid after decoder has processed first frame.
     */
    const V4L2H264StatefulDecoder::Capabilities& get_decoder_capabilities() const;

    /**
     * @brief Get pipeline statistics
     */
    struct Stats {
        UvgRtpReceiver::Stats rtp;
        V4L2H264StatefulDecoder::Stats decoder;
        PlaceboFrameQueue::Stats queue;
    };
    Stats get_stats() const;

    /**
     * @brief Reset all statistics
     */
    void reset_stats();

    /**
     * @brief Get last error from any component
     */
    std::string get_last_error() const;

private:
    // Components
    std::unique_ptr<UvgRtpReceiver> m_rtp_receiver;
    std::unique_ptr<V4L2H264StatefulDecoder> m_decoder;
    PlaceboFrameQueue m_frame_queue;

    // Configuration
    Config m_config;
    bool m_initialized = false;
    std::atomic<bool> m_running{false};

    // Callbacks
    void on_nal_received(const uint8_t* data, size_t size, int64_t timestamp_us);
    void on_frame_decoded(PlaceboFrame frame);
    void on_decoder_capabilities(const V4L2H264StatefulDecoder::Capabilities& caps);

    // Renderer format notification (to be picked up by PlaceboVideoItem)
    PlaceboRenderer::FrameFormat m_frame_format;
    std::atomic<bool> m_format_ready{false};
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // V4L2_PIPELINE_H
