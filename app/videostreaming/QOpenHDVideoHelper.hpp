#ifndef QOPENHDVIDEOHELPER_H
#define QOPENHDVIDEOHELPER_H

#include <qqmlapplicationengine.h>
#include <qquickitem.h>
#include <qquickwindow.h>

#include <sstream>

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
    // when set to true, overwrites the rtp decoding, use a raw test video source (if possible). Only for developers.
    // 0 = disabled
    // 1 = raw video
    // 2 = ra video encode and decode
    // >2 disabled
    VideoTestMode dev_test_video_mode = VideoTestMode::DISABLED;
    // the port where to receive rtp video data from
    int video_port = 0;
    // the video codec the received rtp data should be intepreted as.
    VideoCodec video_codec=VideoCodecH264;
    // force sw decoding (if there is a difference on the platform)
    // R.N this only makes a difference on RPI
    bool enable_software_video_decoder=false;
    // 2 configs are equal if all members are exactly the same.
    bool operator==(const VideoStreamConfig &o) const {
       return this->dev_test_video_mode == o.dev_test_video_mode && this->video_port == o.video_port && this->video_codec== o.video_codec
               && this->enable_software_video_decoder==o.enable_software_video_decoder;
     }
    bool operator !=(const VideoStreamConfig &o) const {
        return !(*this==o);
    }
};

/**
 * Find the qt window where video is output to.
 * @param isMainStream QOpenHD supports upt to 2 simultaneous streams, they each have their own respective window.
 * @return nullptr if window cannot be found, the window to display video with otherwise.
 */
static QQuickItem* find_qt_video_window(QQmlApplicationEngine& m_engine,const bool isMainStream=true){
    QString m_elementName;
    if(isMainStream){
         m_elementName = "mainVideoGStreamer";
    }else{
         m_elementName = "pipVideoGStreamer";
    }
    QQuickItem *videoItem;
    QQuickWindow *rootObject;
    auto rootObjects = m_engine.rootObjects();
    if (rootObjects.length() < 1) {
        qDebug() << "Failed to obtain root object list!";
        return nullptr;
    }
    rootObject = static_cast<QQuickWindow *>(rootObjects.first());
    videoItem = rootObject->findChild<QQuickItem *>(m_elementName.toUtf8());
    qDebug() << "Setting element on " << m_elementName;
    if (videoItem == nullptr) {
        qDebug() << "Failed to obtain video item pointer for " << m_elementName;
        return nullptr;
    }
    return videoItem;
}

// Creates a pipeline whose last element produces rtp h164,h265 or mjpeg data
static std::string create_debug_encoded_data_producer(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    std::stringstream ss;
    ss<<"videotestsrc ! video/x-raw, format=I420,width=640,height=480,framerate=30/1 ! ";
    if(videoCodec==VideoCodecH264){
        ss<<"x264enc bitrate=5000 tune=zerolatency key-int-max=10 ! h264parse config-interval=-1 ! ";
        ss<<"rtph264pay mtu=1024 ! ";
    }else if(videoCodec==VideoCodecH265){
        ss<<"x265enc bitrate=5000 tune=zerolatency key-int-max=10 ! ";
        ss<<"rtph265pay mtu=1024 ! ";
    }else{
        ss<<"jpegenc !";
        ss << "rtpjpegpay mtu=1024 ! ";
    }
    ss<<"queue ! ";
    return ss.str();
}


}

// Must be in sync with OpenHD
namespace OHDIntegration{
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP = 5620; // first (primary) stream
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP = 5621; // secondary stream
}

#endif // QOPENHDVIDEOHELPER_H
