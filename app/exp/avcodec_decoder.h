#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "avcodec_helper.hpp"

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
};

#endif // AVCODEC_DECODER_H
