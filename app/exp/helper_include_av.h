#ifndef HELPER_INCLUDE_AVCODEC_H
#define HELPER_INCLUDE_AVCODEC_H

// Include all the "av" stuff we need
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

#endif // HELPER_INCLUDE_AVCODEC_H
