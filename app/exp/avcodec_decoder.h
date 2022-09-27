#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "avcodec_helper.hpp"
#include "../videostreaming/QOpenHDVideoHelper.hpp"
#include "../common_consti/TimeHelper.hpp"

#include "rtp/rtpreceiver.h"

#include <mutex>
#include <deque>
#include <optional>
#include <queue>

#ifdef HAVE_MMAL
#include "mmal/rpimmaldisplay.h"
//#include "mmal/graph_decode_render.h"
#endif
//exp
//#include "drm_kms/drmprime_out.h"

class AVCodecDecoder : public QObject
{
public:
    AVCodecDecoder(QObject *parent = nullptr);

    void init(bool primaryStream);
    void terminate();
private:
    AVCodecContext *decoder_ctx = nullptr;
    const AVCodec *decoder = nullptr;
    std::unique_ptr<std::thread> decode_thread=nullptr;
private:
    void constant_decode();
    // Since we are basically doing connectionless live streaming, where config data comes in regular intervals,
    // The easiest approach here is to just "open" the stream, then decode until an error occurs
    // and do this in a loop. The "decode until error" is needed because due to the fact that the input stream
    // might be incomplete, we cannot quarantee that the decoder won't encounter any errors.
    int open_and_decode_until_error();
    // feed one frame to the decoder, then wait until the frame is returned
    // (This gives the lowest latency on most decoders that have a "lockstep").
    // If we didn't get a frame out for X seconds after feeding a frame more than X times,
    // This will stop performing the lockstep. In this case, either the decoder cannot decode
    // the video without buffering (which is bad, but some IP camera(s) create such a stream)
    // or the underlying decode implementation (e.g. rpi foundation h264 !? investigate) has some quirks.
    int decode_and_wait_for_frame(AVPacket *packet);
    int decode_config_data(AVPacket *packet);
    // Called every time we get a new frame from the decoder, do what you wish here ;)
    void on_new_frame(AVFrame* frame);
    int open_input_error_count=0;
    // simle restart, e.g. when the video codec or the video resolution has changed
    bool request_restart=false;
    // Completely stop (Exit QOpenHD)
    bool m_should_terminate=false;
    int n_no_output_frame_after_x_seconds=0;
    bool use_frame_timestamps_for_latency=false;
    AvgCalculator avg_decode_time{"Decode"};
private:
    // Completely ineficient, but only way since QT settings callback(s) don't properly work
    // runs every 1 second
    std::unique_ptr<QTimer> timer_check_settings_changed = nullptr;
    void timer_check_settings_changed_callback();
    QOpenHDVideoHelper::VideoStreamConfig m_last_video_settings;
private:
    int last_frame_width=-1;
    int last_frame_height=-1;
private:
    //std::unique_ptr<DRMPrimeOut> drm_prime_out=nullptr;
private:
    //std::unique_ptr<std::thread> m_pull_frames_from_ffmpeg_thread=nullptr;
    //std::mutex m_ffmpeg_dequeue_or_queue_mutex;
    bool test_dequeue_fames=false;
    void dequeue_frames_test();
    // This should catch the cases where timestamps are modified by the decoder
    // and therefore the measured value is garbage
private:
    // timestamp used during feed frame
    void add_fed_timestamp(int64_t ts);
    bool check_is_a_valid_timestamp(int64_t ts);
    void debug_is_valid_timestamp(int64_t ts);
    // Must be big enough to catch frame buffering+1, small enough to fit in memory
    // and be searchable with a for loop. !00 sounds like a good fit.
    static constexpr auto MAX_FED_TIMESTAMPS_QUEUE_SIZE=100;
    std::deque<int64_t> m_fed_timestamps_queue;
private:
    const bool enable_wtf=false;
    void fetch_frame_or_feed_input_packet();
    void enqueue_av_packet(AVPacket packet);
    std::optional<AVPacket> fetch_av_packet_if_available();
    std::mutex m_av_packet_queue_mutex;
    std::queue<AVPacket> m_av_packet_queue;
    bool keep_fetching_frames_or_input_packets=false;
private:
    // EXP manual RTP
    AVCodecParserContext *m_pCodecPaser=nullptr;
    void parse_rtp_test();
private:
    std::unique_ptr<RTPReceiver> m_rtp_receiver=nullptr;
private:
    void open_and_decode_until_error_custom_rtp();
    AVCodecParserContext *parser;
};

#endif // AVCODEC_DECODER_H
