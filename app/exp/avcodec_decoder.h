#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "avcodec_helper.hpp"
#include "../videostreaming/QOpenHDVideoHelper.hpp"
#include "../common_consti/TimeHelper.hpp"

//#include "mmal/rpimmaldisplay.h"
//exp
//#include "drm_kms/drmprime_out.h"

class AVCodecDecoder : public QObject
{
public:
    AVCodecDecoder(QObject *parent = nullptr);

    void init(bool primaryStream);

    void cancel();
private:
    AVCodecContext *decoder_ctx = nullptr;
    const AVCodec *decoder = nullptr;
    std::unique_ptr<std::thread> decode_thread=nullptr;
private:
    void constant_decode();
    // VOODO, will be documented at some point ;)
    int lulatsch();
    // feed one frame to the decoder, then wait until the frame is returned
    // (This gives the lowest latency on most decoders that have a "lockstep").
    // If we didn't get a frame out for X seconds after feeding a frame more than X times,
    // This will stop performing the lockstep. In this case, either the decoder cannot decode
    // the video without buffering (which is bad, but some IP camera(s) create such a stream)
    // or the underlying decode implementation (e.g. rpi foundation h264 !? investigate) has some quirks.
    int decode_and_wait_for_frame(AVPacket *packet);
    // Called every time we get a new frame from the decoder, do what you wish here ;)
    void on_new_frame(AVFrame* frame);
    int open_input_error_count=0;
    bool has_been_canceled=false;
    bool request_restart=false;
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
};

#endif // AVCODEC_DECODER_H
