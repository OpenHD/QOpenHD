#include "camerastreammodel.h"
#include "qdebug.h"
#include "util/WorkaroundMessageBox.h"

#include <qsettings.h>

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

void CameraStreamModel::dirty_set_curr_set_video_codec_int(int value)
{
    auto tmp=video_codec_to_string(value);
    set_curr_set_video_codec(tmp.c_str());
}

void CameraStreamModel::dirty_set_curr_set_video_codec_for_cam(int cam_index, int video_codec_in_openhd)
{
    if(cam_index==0){
        CameraStreamModel::instance(0).dirty_set_curr_set_video_codec_int(video_codec_in_openhd);
        if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
            QSettings settings;
            const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
            if(tmp_video_codec!=video_codec_in_openhd){
                // video codec mismatch, update the QOpenHD settings
                settings.setValue("selectedVideoCodecPrimary",video_codec_in_openhd);
                qDebug()<<"Changed electedVideoCodecPrimary in QOpenHD to "<<video_codec_in_openhd;
                workaround::makePopupMessage("Changed VideoCodec Primary in QOpenHD");
            }
        }
    }else if(cam_index==1){
        CameraStreamModel::instance(1).dirty_set_curr_set_video_codec_int(video_codec_in_openhd);
       if(video_codec_in_openhd==0 || video_codec_in_openhd==1 || video_codec_in_openhd==2){
           QSettings settings;
           const int tmp_video_codec = settings.value("selectedVideoCodecSecondary", 0).toInt();
           if(tmp_video_codec!=video_codec_in_openhd){
               // video codec mismatch, update the QOpenHD settings
               settings.setValue("selectedVideoCodecSecondary",video_codec_in_openhd);
               qDebug()<<"Changed selectedVideoCodecSecondary in QOpenHD to "<<video_codec_in_openhd;
               workaround::makePopupMessage("Changed VideoCodec Secondary in QOpenHD");
           }
       }
    }else{
        qWarning("Invalid cam index");
    }
}
