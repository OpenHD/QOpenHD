#include "camerastreammodel.h"

static std::string video_codec_to_string(int value){
    if(value==0)return "h264";
    if(value==1)return "h265";
    if(value==2)return "mjpeg";
    return "Unknown";
}

CameraStreamModel::CameraStreamModel(int m_camera_index,QObject *parent)
    : QObject{parent},
      m_camera_index(m_camera_index)
{

}

CameraStreamModel &CameraStreamModel::instance(int cam_index)
{
    if(cam_index==0){
        static CameraStreamModel instancePrimary{0};
        return instancePrimary;
    }else if(cam_index==1){
        static CameraStreamModel instanceSecondary{1};
        return instanceSecondary;
    }
    assert(false);
}


void CameraStreamModel::set_curr_set_video_bitrate_int(int value)
{
    auto tmp=std::to_string(value)+" MBit/s";
    set_curr_set_video_bitrate(tmp.c_str());
}

void CameraStreamModel::set_curr_set_video_codec_int(int value)
{
    auto tmp=video_codec_to_string(value);
    set_curr_set_video_codec(tmp.c_str());
}
