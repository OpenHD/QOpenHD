#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

#include "helper_include_av.h"

class AVCodecDecoder : public QObject
{
public:
    AVCodecDecoder(QObject *parent = nullptr);

    void init(bool primaryStream);

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
};

#endif // AVCODEC_DECODER_H
