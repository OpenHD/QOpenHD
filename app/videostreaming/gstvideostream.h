#if defined(ENABLE_GSTREAMER)

#ifndef OpenHDVideoStream_H
#define OpenHDVideoStream_H

#include <QObject>
#include <qquickitem.h>

#include <QtQml>
#include <gst/gst.h>


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
 * Consti10
 * This video player works purely in software (Gstreamer), but supports all the 3 OpenHD live video formats (h264,h265 and mjpeg).
 * Its inputs and outputs are easily defined:
 * 1) Input -> a udp port from which rtp video data is received.
 * 2) Output -> a qml window ???? not sure yet exactly how to call that.
 */
class GstVideoStream : public QObject{
    Q_OBJECT
public:
    /**
     * The constructor is delayed, remember to use init().
     */
    GstVideoStream(QObject *parent = nullptr);
    virtual ~GstVideoStream();
    /**
     * @brief after setting the output window, this does not immediately start streaming -
     * it starts a timer that checks in regular intervalls if any video-related settings (like the videoCodec) have changed
     * and then starts / re-starts the decoding and display process.
     * @param videoOutputWindow the qt window where the decoded data is displayed.
     * @param primaryStream primary and secondary stream use different UDP ports
     */
    void init(QQuickItem* videoOutputWindow,bool primaryStream);
    // for checking if video data actually arrives
    // public because set by static method
    qint64 lastDataTimeout = 0;
    void startVideo();
    void stopVideoSafe();
private:
    /**
     * @brief fired by m_timer.
     * Checks every second if the enable_videotest setting has changed, if so we restart the
     * stream and let the the pipeline be reconstructed using whichever video source is now enabled.
     */
    void timerCallback();
    // Where the video is output to.
    QQuickItem* m_videoOutputWindow;
    // The gstreamer pipeline
    GstElement * m_pipeline=nullptr;
    // the current configuration, is continously synced with settings
    VideoStreamConfig m_videoStreamConfig;
    // runs every 1 second
    QTimer* timer = nullptr;
    bool m_isPrimaryStream=true;
    bool firstCheck=true;
};

#endif // OpenHDVideoStream_H

#endif
