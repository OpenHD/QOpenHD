#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

#include <qtimer.h>
#include <thread>
#include <memory>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/pixdesc.h>
#include <libavutil/hwcontext.h>
#include <libavutil/opt.h>
#include <libavutil/avassert.h>
#include <libavutil/imgutils.h>
#include <libavutil/buffer.h>
#include <libavutil/frame.h>
    //
#include "libavutil/frame.h"
#include "libavutil/hwcontext.h"
#include "libavutil/hwcontext_drm.h"
#include "libavutil/pixdesc.h"
}

class AVCodecDecoder : public QObject
{
public:
    AVCodecDecoder(QObject *parent = nullptr);

    void init(bool primaryStream);

private:
    //QTimer* timer = nullptr;
    AVCodecContext *decoder_ctx = nullptr;
    const AVCodec *decoder = nullptr;
    //
    int decode_and_wait_for_frame(AVPacket *packet);
    std::unique_ptr<std::thread> decode_thread=nullptr;

private:
    void constant_decode();
    int lulatsch();
    void on_new_frame(AVFrame* frame);
};

#endif // AVCODEC_DECODER_H
