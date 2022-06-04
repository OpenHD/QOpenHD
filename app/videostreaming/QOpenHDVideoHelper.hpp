#ifndef QOPENHDVIDEOHELPER_H
#define QOPENHDVIDEOHELPER_H

#include <qqmlapplicationengine.h>
#include <qquickitem.h>
#include <qquickwindow.h>



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
    return VideoCodecH265;
}

/**
 * No matter if the underlying decoding is done hw accelerated or on any platform, video is always
 * a constant stream of rtp data to a specific udp port. This is the only information to start a
 * QOpenHD video stream, except the output mechanism (can be int qt via GL, drm/kms, ...)
 */
struct VideoStreamConfig{
    // when set to true, overwrites the rtp decoding, use a raw test video source (if possible). Only for developers.
    bool enable_videotest = false;
    // the port where to receive rtp video data from
    int video_port = 0;
    // the video codec the received rtp data should be intepreted as.
    VideoCodec video_codec=VideoCodecH264;
    // 2 configs are equal if all members are exactly the same.
    bool operator==(const VideoStreamConfig &o) const {
       return this->enable_videotest == o.enable_videotest && this->video_port == o.video_port && this->video_codec== o.video_codec;
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



}

// Must be in sync with OpenHD
namespace OHDIntegration{
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP = 5620; // first (primary) stream
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP = 5621; // secondary stream
}

#endif // QOPENHDVIDEOHELPER_H
