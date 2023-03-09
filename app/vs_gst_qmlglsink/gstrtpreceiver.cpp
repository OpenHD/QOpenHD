#include "gstrtpreceiver.h"
#include "gst/gstparse.h"
#include "gst/gstpipeline.h"
#include "gst/app/gstappsink.h"

#include <cstring>

#include "../vs_avcodec/nalu/NALU.hpp"

GstRtpReceiver::GstRtpReceiver(int udp_port, QOpenHDVideoHelper::VideoCodec video_codec)
{
    m_port=udp_port;
    m_video_codec=video_codec;
}

GstRtpReceiver::~GstRtpReceiver()
{

}

enum class VideoCodec {
  H264=0,
  H265,
  MJPEG
};
static VideoCodec conv_codec(const QOpenHDVideoHelper::VideoCodec codec){
    if(codec==QOpenHDVideoHelper::VideoCodecH264)return VideoCodec::H264;
    if(codec==QOpenHDVideoHelper::VideoCodecH265)return VideoCodec::H265;
    return VideoCodec::MJPEG;
}

static std::string gst_create_rtp_caps(const VideoCodec& videoCodec){
  std::stringstream ss;
  if(videoCodec==VideoCodec::H264){
    ss<<"caps=\"application/x-rtp, media=(string)video, encoding-name=(string)H264, payload=(int)96\"";
  }else if(videoCodec==VideoCodec::H265){
    ss<<"caps=\"application/x-rtp, media=(string)video, encoding-name=(string)H265\"";
  }else{
    ss<<"caps=\"application/x-rtp, media=(string)video, encoding-name=(string)mjpeg\"";
  }
  return ss.str();
}
static std::string create_rtp_depacketize_for_codec(const VideoCodec& codec){
  if(codec==VideoCodec::H264)return "rtph264depay ! ";
  if(codec==VideoCodec::H265)return "rtph265depay ! ";
  if(codec==VideoCodec::MJPEG)return "rtpjpegdepay ! ";
  assert(false);
  return "";
}
static std::string create_parse_for_codec(const VideoCodec& codec){
  // config-interval=-1 = makes 100% sure each keyframe has SPS and PPS
  if(codec==VideoCodec::H264)return "h264parse config-interval=-1 ! ";
  if(codec==VideoCodec::H265)return "h265parse config-interval=-1  ! ";
  if(codec==VideoCodec::MJPEG)return "jpegparse ! ";
  assert(false);
  return "";
}
static std::string create_out_h264(){
    std::stringstream ss;
    ss<<"video/x-h264";
    ss<<", stream-format=\"byte-stream\"";
    //ss<<", alignment=\"nal\"";
    ss<<" ! ";
    return ss.str();
}

static std::shared_ptr<std::vector<uint8_t>> gst_copy_buffer(GstBuffer* buffer){
  assert(buffer);
  const auto buff_size = gst_buffer_get_size(buffer);
  //openhd::log::get_default()->debug("Got buffer size {}", buff_size);
  auto ret = std::make_shared<std::vector<uint8_t>>(buff_size);
  GstMapInfo map;
  gst_buffer_map(buffer, &map, GST_MAP_READ);
  assert(map.size == buff_size);
  std::memcpy(ret->data(), map.data, buff_size);
  gst_buffer_unmap(buffer, &map);
  return ret;
}

static void loop_pull_appsink_samples(bool& keep_looping,GstElement *app_sink_element,
                                      const GstRtpReceiver::NEW_FRAME_CALLBACK out_cb){
  assert(app_sink_element);
  assert(out_cb);
  const uint64_t timeout_ns=std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::milliseconds(100)).count();
  while (keep_looping){
    GstSample* sample = gst_app_sink_try_pull_sample(GST_APP_SINK(app_sink_element),timeout_ns);
    if (sample) {
      //openhd::log::get_default()->debug("Got sample");
      //auto buffer_list=gst_sample_get_buffer_list(sample);
      //openhd::log::get_default()->debug("Got sample {}", gst_buffer_list_length(buffer_list));
      //gst_debug_sample(sample);
      GstBuffer* buffer = gst_sample_get_buffer(sample);
      if (buffer) {
        //openhd::gst_debug_buffer(buffer);
        auto buff_copy=gst_copy_buffer(buffer);
        //openhd::log::get_default()->debug("Got buffer size {}", buff_copy->size());
        out_cb(buff_copy);
      }
      gst_sample_unref(sample);
    }
  }
}


std::string GstRtpReceiver::construct_gstreamer_pipeline()
{
    const auto codec=conv_codec(m_video_codec);
    std::stringstream ss;
    ss<<"udpsrc address=\"127.0.0.1\" port="<<m_port<<" "<<gst_create_rtp_caps(codec)<<" ! ";
    ss<<create_rtp_depacketize_for_codec(codec);
    ss<<create_parse_for_codec(codec);
    ss<<create_out_h264();
    ss<<" appsink drop=true name=out_appsink";
    return ss.str();
}

void GstRtpReceiver::loop_pull_samples()
{
    assert(m_app_sink_element);
      auto cb=[this](std::shared_ptr<std::vector<uint8_t>> sample){
          this->on_new_sample(sample);
      };
      loop_pull_appsink_samples(m_pull_samples_run,m_app_sink_element,cb);
}

void GstRtpReceiver::on_new_sample(std::shared_ptr<std::vector<uint8_t> > sample)
{
    if(m_cb){
        m_cb(sample);
    }else{
        NALU nalu(sample->data(),sample->size());
        qDebug()<<"Got frame:"<<nalu.get_nal_unit_type_as_string().c_str();
    }
}


void GstRtpReceiver::start_receiving(NEW_FRAME_CALLBACK cb)
{
    qDebug()<<"GstRtpReceiver::start_receiving begin";
    assert(m_gst_pipeline==nullptr);
    m_cb=cb;

    const auto pipeline=construct_gstreamer_pipeline();
    GError *error = nullptr;
    m_gst_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=[" << pipeline.c_str()<<"]";
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
        return;
    }
    if(!m_gst_pipeline || !(GST_IS_PIPELINE(m_gst_pipeline))){
        qDebug()<<"Cannot construct pipeline";
        m_gst_pipeline = nullptr;
        return;
    }
    gst_element_set_state (m_gst_pipeline, GST_STATE_PLAYING);
    //
    // we pull data out of the gst pipeline as cpu memory buffer(s) using the gstreamer "appsink" element
    m_app_sink_element=gst_bin_get_by_name(GST_BIN(m_gst_pipeline), "out_appsink");
    assert(m_app_sink_element);
    m_pull_samples_run= true;
    m_pull_samples_thread=std::make_unique<std::thread>(&GstRtpReceiver::loop_pull_samples, this);

    qDebug()<<"GstRtpReceiver::start_receiving end";
}

void GstRtpReceiver::stop_receiving()
{
     m_pull_samples_run=false;
     if(m_pull_samples_thread){
         m_pull_samples_thread->join();
         m_pull_samples_thread=nullptr;
     }
     //TODO unref appsink reference
     if (m_gst_pipeline != nullptr) {
         // Needed on jetson ?!
         gst_element_send_event ((GstElement*)m_gst_pipeline, gst_event_new_eos ());
         gst_element_set_state(m_gst_pipeline, GST_STATE_PAUSED);
         gst_element_set_state (m_gst_pipeline, GST_STATE_NULL);
         gst_object_unref (m_gst_pipeline);
         m_gst_pipeline=nullptr;
     }
}

