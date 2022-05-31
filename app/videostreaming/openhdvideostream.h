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
};

/**
 * Consti10
 * This video player works purely in software, but supports all the 3 OpenHD live video formats (h264,h265 and mjpeg).
 * Its inputs and outputs are easily defined:
 * 1) Input -> a udp port from which rtp video data is received.
 * 2) Output -> a qml window ???? not sure yet exactly how to call that.
 * And processing is done via gstreamer.
 */
class OpenHDVideoStream : public QObject
{
    Q_OBJECT

public:

    OpenHDVideoStream(QObject *parent = nullptr);
    virtual ~OpenHDVideoStream();

    /**
     * @brief init
     * @param videoStreamConfig the config for this video stream.
     * @param videoOutputWindow the qt window where the decoded data is displayed.
     */
    void init(QQuickItem* videoOutputWindow);
    //VideoStreamConfig videoStreamConfig,

    qint64 lastDataTimeout = 0;

signals:
    void videoRunning(bool running);

public slots:
    void startVideo();
    void stopVideo();

private:
    void _start();
    void _stop();
    QString m_elementName;

    void _timer() ;
    // Where the video is output to.
    QQuickItem* m_videoOutputWindow;
    // The gstreamer pipeline
    GstElement * m_pipeline;
    bool firstRun = true;

    VideoStreamConfig m_videoStreamConfig;

    QTimer* timer = nullptr;

    GMainLoop *mainLoop = nullptr;
};

#endif // OpenHDVideoStream_H

#endif
