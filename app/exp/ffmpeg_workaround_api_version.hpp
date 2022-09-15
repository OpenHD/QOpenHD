//
// Created by consti10 on 04.09.22.
//

#ifndef HELLO_DRMPRIME__FFMPEG_WORKAROUND_API_VERSION_HPP_
#define HELLO_DRMPRIME__FFMPEG_WORKAROUND_API_VERSION_HPP_

// For some reaseon av_frame_cropped_width doesn't exit on ffmpeg default on ubuntu
// but on rpi, it does !
static int av_frame_cropped_width(const AVFrame* frame){
  return frame->width;
}

static int av_frame_cropped_height(const AVFrame* frame){
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

static void print_hwframe_transfer_formats(AVBufferRef *hwframe_ctx){
  if(hwframe_ctx== nullptr){
	std::cout<<"Frame has no hwframe_ctx\n";
	return;
  }
  enum AVPixelFormat *formats;
  const auto err = av_hwframe_transfer_get_formats(hwframe_ctx, AV_HWFRAME_TRANSFER_DIRECTION_FROM, &formats, 0);
  if (err < 0) {
	std::cout<<"av_hwframe_transfer_get_formats error\n";
	return;
  }
  std::stringstream ss;
  ss<<"Supported transfers:";
  for (int i = 0; formats[i] != AV_PIX_FMT_NONE; i++) {
	ss<<i<<":"<<safe_av_get_pix_fmt_name(formats[i])<<",";
  }
  ss<<"\n";
  std::cout<<ss.str();
  av_freep(&formats);
}

static void print_av_hwdevice_types(){
  std::stringstream ss;
  AVHWDeviceType tmp_type=AV_HWDEVICE_TYPE_NONE;
  ss<< "Available HW device types:";
  while((tmp_type = av_hwdevice_iterate_types(tmp_type)) != AV_HWDEVICE_TYPE_NONE){
	ss<<" "<<safe_av_hwdevice_get_type_name(tmp_type);
  }
  ss<<"\n";
  fprintf(stdout, "%s",ss.str().c_str());
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


#endif //HELLO_DRMPRIME__FFMPEG_WORKAROUND_API_VERSION_HPP_
