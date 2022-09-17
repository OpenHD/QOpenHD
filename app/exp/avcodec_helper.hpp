//
// Created by consti10 on 04.09.22.
//

#ifndef HELLO_DRMPRIME__AVCODEC_HELPER_HPP_
#define HELLO_DRMPRIME__AVCODEC_HELPER_HPP_

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

#include <iostream>
#include <string>
#include <sstream>

// For some reaseon av_frame_cropped_width doesn't exit on ffmpeg default on ubuntu
// but on rpi, it does !
static int x_av_frame_cropped_width(const AVFrame* frame){
  return frame->width;
}

static int x_av_frame_cropped_height(const AVFrame* frame){
  return frame->height;
}


static std::string safe_av_hwdevice_get_type_name(enum AVHWDeviceType type){
  auto tmp= av_hwdevice_get_type_name(type);
  if(tmp== nullptr){
	return "null";
  }
  return {tmp};
}

static std::string safe_av_get_pix_fmt_name(enum AVPixelFormat pix_fmt){
  auto tmp= av_get_pix_fmt_name(pix_fmt);
  if(tmp== nullptr){
	return "null";
  }
  return {tmp};
}

static std::string all_av_hwframe_transfer_formats(AVBufferRef *hwframe_ctx){
  std::stringstream ss;
  if(hwframe_ctx== nullptr){
	ss<<"Frame has no hwframe_ctx\n";
	return ss.str();
  }
  enum AVPixelFormat *formats;
  const auto err = av_hwframe_transfer_get_formats(hwframe_ctx, AV_HWFRAME_TRANSFER_DIRECTION_FROM, &formats, 0);
  if (err < 0) {
	ss<<"av_hwframe_transfer_get_formats error\n";
	return ss.str();
  }
  ss<<"Supported transfers:";
  for (int i = 0; formats[i] != AV_PIX_FMT_NONE; i++) {
	ss<<i<<":"<<safe_av_get_pix_fmt_name(formats[i])<<",";
  }
  ss<<"\n";
  av_freep(&formats);
  return ss.str();
}

static std::string all_av_hwdevice_types(){
  std::stringstream ss;
  AVHWDeviceType tmp_type=AV_HWDEVICE_TYPE_NONE;
  ss<< "Available HW device types:";
  while((tmp_type = av_hwdevice_iterate_types(tmp_type)) != AV_HWDEVICE_TYPE_NONE){
	ss<<" "<<safe_av_hwdevice_get_type_name(tmp_type);
  }
  ss<<"\n";
  return ss.str();
}

static std::string all_formats_to_string(const enum AVPixelFormat *pix_fmts){
  std::stringstream ss;
  ss<<"PixelFormats:[";
  if(pix_fmts== nullptr){
	ss<<"none]";
	return ss.str();
  }
  for(int i=0;;i++){
	auto tmp=pix_fmts[i];
	if(tmp==AV_PIX_FMT_NONE)break;
	ss<<safe_av_get_pix_fmt_name(tmp)<<",";
  }
  ss<<"]";
  return ss.str();
}


#endif //HELLO_DRMPRIME__AVCODEC_HELPER_HPP_