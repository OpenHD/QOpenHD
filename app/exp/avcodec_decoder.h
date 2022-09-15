#ifndef AVCODEC_DECODER_H
#define AVCODEC_DECODER_H

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

class AVCodecDecoder
{
public:
    AVCodecDecoder();
};

#endif // AVCODEC_DECODER_H
