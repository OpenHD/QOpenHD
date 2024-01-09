#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "avcodec_helper.hpp"
#include "QOpenHDVideoHelper.hpp"
#include "../../common/TimeHelper.hpp"

#include "rtp/rtpreceiver.h"

#include <mutex>
#include <deque>
#include <optional>
#include <queue>
#include <atomic>

#include <custom/rawreceiver.h>

//exp
//#include "drm_kms/drmprime_out.h"

// DIRTY
//#define HACK_RAW


/**
 * Decoding and display of primary video on all platforms except android
 * NOTE: On rpi, we actually don't use avcodec, but the decode service workaround (mmal)
 * since it is the only way to get (ish) low latency h264 video on rpi.
 */
class AVCodecDecoder : public QObject
{
public:
    AVCodecDecoder(QObject *parent = nullptr);
    ~AVCodecDecoder();
    // called when app is created
    void init(bool primaryStream);
    // called when app terminates
    void terminate();
private:
    AVCodecContext *decoder_ctx = nullptr;
    const AVCodec *decoder = nullptr;
    std::unique_ptr<std::thread> decode_thread=nullptr;
private:
    // The logic of this decode "machine" is simple:
    // Start decoding as soon as enough config data has been received
    // Ccompletely restart the decoding in case an error occurs
    // or the settings changed (e.g. a switch of the video codec).
    void constant_decode();
    // Since we are basically doing connectionless live streaming, where config data comes in regular intervals,
    // The easiest approach here is to just "open" the stream, then decode until an error occurs
    // and do this in a loop. The "decode until error" is needed because due to the fact that the input stream
    // might be incomplete, we cannot quarantee that the decoder won't encounter any errors.
    int open_and_decode_until_error(const QOpenHDVideoHelper::VideoStreamConfig settings);
    // feed one frame to the decoder, then wait until the frame is returned
    // (This gives the lowest latency on most decoders that have a "lockstep").
    // If we didn't get a frame out for X seconds after feeding a frame more than X times,
    // This will stop performing the lockstep. In this case, either the decoder cannot decode
    // the video without buffering (which is bad, but some IP camera(s) create such a stream)
    // or the underlying decode implementation (e.g. rpi foundation h264 !? investigate) has some quirks.
    int decode_and_wait_for_frame(AVPacket *packet,std::optional<std::chrono::steady_clock::time_point> parse_time=std::nullopt);
    // Just send data to the codec, do not check or wait for a frame
    int decode_config_data(AVPacket *packet);
    // Called every time we get a new frame from the decoder, do what you wish here ;)
    void on_new_frame(AVFrame* frame);
    // simle restart, e.g. when the video codec or the video resolution has changed we need to break
    // out of a running "constant_decode_xx" loop
    std::atomic<bool> request_restart=false;
    // Completely stop (Exit QOpenHD)
    bool m_should_terminate=false;
    int n_no_output_frame_after_x_seconds=0;
    bool use_frame_timestamps_for_latency=false;
    AvgCalculator avg_decode_time{"Decode"};
    AvgCalculator avg_parse_time{"Parse&Enqueue"};
    AvgCalculator avg_send_mmal_frame_to_display{"MMAL send frame"};
    static constexpr std::chrono::milliseconds kDefaultFrameTimeout{33*2};
private:
    // Completely ineficient, but only way since QT settings callback(s) don't properly work
    // runs every 1 second, reads the settings and checks if they differ from the previosly
    // read settings. In case they differ, request a complete restart from the decoder.
    std::unique_ptr<QTimer> timer_check_settings_changed = nullptr;
    void timer_check_settings_changed_callback();
    QOpenHDVideoHelper::VideoStreamConfig m_last_video_settings;
private:
    int last_frame_width=-1;
    int last_frame_height=-1;
private:
    //std::unique_ptr<DRMPrimeOut> drm_prime_out=nullptr;
private:
    // timestamp used during feed frame
    void timestamp_add_fed(int64_t ts);
    bool timestamp_check_valid(int64_t ts);
    void timestamp_debug_valid(int64_t ts);
    // Must be big enough to catch frame buffering+1, small enough to fit in memory
    // and be searchable with a for loop. !00 sounds like a good fit.
    static constexpr auto MAX_FED_TIMESTAMPS_QUEUE_SIZE=100;
    std::deque<int64_t> m_fed_timestamps_queue;
private:
    void fetch_frame_or_feed_input_packet();
private:
#ifdef HACK_RAW
     std::unique_ptr<RawReceiver> m_rtp_receiver=nullptr;
#else
   std::unique_ptr<RTPReceiver> m_rtp_receiver=nullptr;
#endif
private:
    // Custom rtp parse (and therefore limited to h264 and h265)
    // AND always goes the avcodec decode route (SW decode or avcodec mmal decode).
    // Used for SW decode, for MMAL h264 we go the custom rtp WITHOUT avcodec route by default !
    void open_and_decode_until_error_custom_rtp(const QOpenHDVideoHelper::VideoStreamConfig settings);
    bool feed_rtp_frame_if_available();
private:
    void reset_before_decode_start();
    // On some platforms, it is easiest to just start and stop a service that does the video decode (QOpenHD is then transparently layered on top)
    void dirty_generic_decode_via_external_decode_service(const QOpenHDVideoHelper::VideoStreamConfig& settings);
};

#endif // AVCODEC_DECODER_H
