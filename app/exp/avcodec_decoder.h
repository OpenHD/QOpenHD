#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "avcodec_helper.hpp"
#include "../videostreaming/QOpenHDVideoHelper.hpp"

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
    int lulatsch();
    //
    int decode_and_wait_for_frame(AVPacket *packet);
    void on_new_frame(AVFrame* frame);
    int open_input_error_count=0;
    bool has_been_canceled=false;
    bool request_restart=false;
    int n_no_output_frame_after_x_seconds=0;
private:
    // Completely ineficient, but only way since QT settings callback(s) don't properly work
    // runs every 1 second
    std::unique_ptr<QTimer> timer_check_settings_changed = nullptr;
    void timer_check_settings_changed_callback();
    QOpenHDVideoHelper::VideoStreamConfig m_last_video_settings;
};

#endif // AVCODEC_DECODER_H
