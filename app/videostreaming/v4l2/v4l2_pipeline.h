// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef V4L2_PIPELINE_H
#define V4L2_PIPELINE_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <memory>
#include <string>
#include <atomic>

#if defined(ENABLE_UVGRTP)
#include "uvgrtp_receiver.h"
#endif
#include "v4l2_decoder.h"
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
 *
 * Singleton pattern for easy access from QML components.
 */
class V4L2Pipeline
{
public:
    /**
     * @brief Get singleton instance
     */
    static V4L2Pipeline& instance();

    // Delete copy/move
    V4L2Pipeline(const V4L2Pipeline&) = delete;
    V4L2Pipeline& operator=(const V4L2Pipeline&) = delete;

    /**
     * @brief Pipeline configuration
     */
    struct Config {
        // RTP reception
        std::string rtp_listen_addr = "0.0.0.0";
        uint16_t rtp_listen_port = 5600;

        // Codec
        enum class Codec { H264, H265 } codec = Codec::H264;

        // V4L2 device
        std::string v4l2_device = "/dev/video0";
    };

    /**
     * @brief Initialize the pipeline with given configuration
     * @param config Pipeline configuration
     * @return true on success
     */
    bool init(const Config& config);

    /**
     * @brief Initialize with default configuration (reads from QSettings)
     * @return true on success
     */
    bool init_from_settings();

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
    const V4L2Decoder::Capabilities& get_decoder_capabilities() const;

    /**
     * @brief Get pipeline statistics
     */
    struct Stats {
#if defined(ENABLE_UVGRTP)
        UvgRtpReceiver::Stats rtp;
#endif
        V4L2Decoder::Stats decoder;
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
    V4L2Pipeline();
    ~V4L2Pipeline();

    // Components
#if defined(ENABLE_UVGRTP)
    std::unique_ptr<UvgRtpReceiver> m_rtp_receiver;
#endif
    std::unique_ptr<V4L2Decoder> m_decoder;
    PlaceboFrameQueue m_frame_queue;

    // Configuration
    Config m_config;
    bool m_initialized = false;
    std::atomic<bool> m_running{false};

    // Callbacks
    void on_nal_received(const uint8_t* data, size_t size, int64_t timestamp_us);
    void on_frame_decoded(PlaceboFrame frame);
    void on_decoder_capabilities(const V4L2Decoder::Capabilities& caps);

    // Renderer format notification (to be picked up by PlaceboVideoItem)
    PlaceboRenderer::FrameFormat m_frame_format;
    std::atomic<bool> m_format_ready{false};
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // V4L2_PIPELINE_H
