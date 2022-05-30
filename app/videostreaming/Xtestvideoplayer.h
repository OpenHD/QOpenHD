#ifndef XTESTVIDEOPLAYER_H
#define XTESTVIDEOPLAYER_H

#include <gst/gst.h>

#include <qqmlapplicationengine.h>

/**
 * Consti10
 * This video player works purely in software, but supports all the 3 OpenHD live video formats (h264,h265 and mjpeg).
 * Its inputs and outputs are easily defined:
 * 1) Input -> a udp port from which rtp video data is received.
 * 2) Output -> a qml window ???? not sure yet exactly how things go here.
 */
class XTestVideoPlayer
{
public:
    typedef enum VideoCodec {
      VideoCodecH264,
      VideoCodecH265,
      VideoCodecMJPEG
    } VideoCodec;
    /**
     * @brief XTestVideoPlayer
     * @param enableVideoTest when set to true, the functionality of this class is changed to display a gstreamer test video
     * instead of decoding the video stream. Successive calls to startReceiving() are ignored in this case.
     */
    XTestVideoPlayer(QQmlApplicationEngine *engine,bool enableVideoTest);
    /**
     * @brief Start receiving and decoding the video data as for this configuration (codec, port). If the configuration has not changed since the last
     * call to startReceiving(), nothing is changed.
     * @param videoCodec the video codec the rtp data is interpreted as.
     * @param udp_port the udp port where to listen for the rtp data.
     */
    void startReceiving(VideoCodec videoCodec,int udp_port);
private:
    QQmlApplicationEngine *m_engine;
    const bool ENABLE_VIDEO_TEST;
    VideoCodec m_video_codec;
    int m_udp_port;
    void constructStartPieline();
private:
     GstElement * m_pipeline;
};

#endif // XTESTVIDEOPLAYER_H
