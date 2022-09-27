#ifndef QOPENHDVIDEOHELPER_H
#define QOPENHDVIDEOHELPER_H

#include <QSettings>
#include <qqmlapplicationengine.h>
#include <qquickitem.h>
#include <qquickwindow.h>

#include <sstream>
#include <fstream>
#include <qfileinfo.h>

namespace QOpenHDVideoHelper{

// OpenHD supported video codecs
typedef enum VideoCodec {
  VideoCodecH264=0,
  VideoCodecH265=1,
  VideoCodecMJPEG=2
} VideoCodec;
static VideoCodec intToVideoCodec(int videoCodec){
    if(videoCodec==0)return VideoCodecH264;
    if(videoCodec==1)return VideoCodecH265;
    if(videoCodec==2)return VideoCodecMJPEG;
    qDebug() << "VideoCodec::intToVideoCodec::somethingWrong,using H264 as default";
    return VideoCodecH264;
}

enum class VideoTestMode{
    DISABLED, // disabled
    RAW_VIDEO, // raw video into qmlglsink. Doesn't check video decoding capabilities, only qmlsink capabilities
    RAW_VIDEO_ENCODE_DECODE // encode raw video, then decode it and then into qmlsink. When this passes, platform can do video decoding
};
static VideoTestMode videoTestModeFromInt(int value){
    if(value==1)return VideoTestMode::RAW_VIDEO;
    if(value==2)return VideoTestMode::RAW_VIDEO_ENCODE_DECODE;
    return VideoTestMode::DISABLED;
}

/**
 * No matter if the underlying decoding is done hw accelerated or on any platform, video is always
 * a constant stream of rtp data to a specific udp port. This is the only information to start a
 * QOpenHD video stream, except the output mechanism (can be int qt via GL, drm/kms, ...)
 */
struct VideoStreamConfig{
    // used for testing and development.
    VideoTestMode dev_test_video_mode = VideoTestMode::DISABLED;
    // the port where to receive rtp video data from
    int video_port = 0;
    // the video codec the received rtp data should be intepreted as.
    VideoCodec video_codec=VideoCodecH264;
    // force sw decoding (if there is a difference on the platform)
    // R.N this only makes a difference on RPI
    bool enable_software_video_decoder=false;
    // XX
    bool dev_jetson=false;
    //
    bool dev_enable_custom_pipeline=false;
    std::string dev_custom_pipeline="";
    //
    int dev_limit_fps_on_test_file=-1;
    // 2 configs are equal if all members are exactly the same.
    bool operator==(const VideoStreamConfig &o) const {
       return this->dev_test_video_mode == o.dev_test_video_mode && this->video_port == o.video_port && this->video_codec== o.video_codec
               && this->enable_software_video_decoder==o.enable_software_video_decoder && this->dev_jetson==o.dev_jetson &&
               this->dev_enable_custom_pipeline==o.dev_enable_custom_pipeline &&
               this->dev_custom_pipeline==o.dev_custom_pipeline &&
               this->dev_limit_fps_on_test_file == o.dev_limit_fps_on_test_file;
     }
    bool operator !=(const VideoStreamConfig &o) const {
        return !(*this==o);
    }
};

static VideoStreamConfig read_from_settings(){
    QSettings settings;
    QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig;
    _videoStreamConfig.dev_test_video_mode=QOpenHDVideoHelper::videoTestModeFromInt(settings.value("dev_test_video_mode", 0).toInt());
    const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
    _videoStreamConfig.video_codec=QOpenHDVideoHelper::intToVideoCodec(tmp_video_codec);
    _videoStreamConfig.enable_software_video_decoder=settings.value("enable_software_video_decoder", 0).toBool();
    _videoStreamConfig.dev_jetson=settings.value("dev_jetson",false).toBool();
    //
    _videoStreamConfig.dev_enable_custom_pipeline=settings.value("dev_enable_custom_pipeline",false).toBool();
    _videoStreamConfig.dev_limit_fps_on_test_file=settings.value("dev_limit_fps_on_test_file",-1).toInt();
    // QML text input sucks, so we read a file. Not ideal, but for testing only anyways
    {
        _videoStreamConfig.dev_custom_pipeline="";
        if(_videoStreamConfig.dev_enable_custom_pipeline){
            std::ifstream file("/usr/local/share/qopenhd/custom_pipeline.txt");
            if(file.is_open()){
                std::stringstream buffer;
                buffer << file.rdbuf();
                _videoStreamConfig.dev_custom_pipeline=buffer.str();
            }else{
                qDebug()<<"dev_enable_custom_pipeline but no file";
            }
        }
    }
    //_videoStreamConfig.dev_custom_pipeline=settings.value("dev_custom_pipeline","").toString().toStdString();
    return _videoStreamConfig;
}

// For OpenHD images, these files are copied over by the image builder and therefore can
// be used for testing / validation
static std::string get_default_openhd_test_file(const VideoCodec video_codec){
    std::stringstream in_filename;
    in_filename<<"/usr/local/share/testvideos/";
    if(video_codec==QOpenHDVideoHelper::VideoCodecH264){
        in_filename<<"rpi_1080.h264";
    }else if(video_codec==QOpenHDVideoHelper::VideoCodecH265){
        in_filename<<"jetson_test.h265";
    }else{
       in_filename<<"uv_640x480.mjpeg";
    }
    return in_filename.str();
}

//

// FFMPEG needs a ".sdp" file to do rtp udp h264,h265 or mjpeg
// For MJPEG we map mjpeg to 26 (mjpeg), for h264/5 we map h264/5 to 96 (general)
static std::string create_udp_rtp_sdp_file(const QOpenHDVideoHelper::VideoCodec& video_codec){
    std::stringstream ss;
    ss<<"c=IN IP4 127.0.0.1\n";
    //ss<<"v=0\n";
    //ss<<"t=0 0\n";
    //ss<<"width=1280\n";
    //ss<<"height=720\n";
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG){
         ss<<"m=video 5600 RTP/UDP 26\n";
        ss<<"a=rtpmap:26 JPEG/90000\n";
    }else{
        ss<<"m=video 5600 RTP/UDP 96\n";
        if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH264){
            ss<<"a=rtpmap:96 H264/90000\n";
        }else{
            assert(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH265);
            ss<<"a=rtpmap:96 H265/90000\n";
        }
    }
    return ss.str();
}
static void write_file_to_tmp(const std::string filename,const std::string content){
    std::ofstream _t(filename);
     _t << content;
     _t.close();
}
static void write_udp_rtp_sdp_files_to_tmp(){
    if(QFileInfo::exists("/tmp/rtp_h264.sdp")&&QFileInfo::exists("/tmp/rtp_h265.sdp")&&QFileInfo::exists("/tmp/rtp_mjpeg.sdp"))return;
    write_file_to_tmp("/tmp/rtp_h264.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecH264));
    write_file_to_tmp("/tmp/rtp_h265.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecH265));
    write_file_to_tmp("/tmp/rtp_mjpeg.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG));
}
static std::string get_udp_rtp_sdp_filename(const QOpenHDVideoHelper::VideoCodec& video_codec){
    // Make sure the sdp files exist (writing a file and then giving it to avcodec is easier than other alternatives).
    write_udp_rtp_sdp_files_to_tmp();
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH264)return "/tmp/rtp_h264.sdp";
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH265)return "/tmp/rtp_h265.sdp";
    return "/tmp/rtp_mjpeg.sdp";
}

}

// Must be in sync with OpenHD
namespace OHDIntegration{
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP = 5600; // first (primary) stream
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP = 5601; // secondary stream
}

#endif // QOPENHDVIDEOHELPER_H
