#include "Xtestvideoplayer.h"

#include <qdebug.h>
#include <sstream>

XTestVideoPlayer::XTestVideoPlayer(QQmlApplicationEngine *engine,bool enableVideoTest):
    m_engine(engine),
    ENABLE_VIDEO_TEST(enableVideoTest)
{

}

void XTestVideoPlayer::startReceiving(VideoCodec videoCodec,int udp_port)
{
    if(ENABLE_VIDEO_TEST){
        constructStartPieline();
        return;
    }
    m_video_codec=videoCodec;
    m_udp_port=udp_port;
}

void XTestVideoPlayer::constructStartPieline()
{
    std::stringstream ss;
    if(ENABLE_VIDEO_TEST){
        qDebug() << "Using video test\n";
        ss << "videotestsrc pattern=smpte !";
        ss << "video/x-raw,width=640,height=480 !";
        ss << "queue !";
    }else{
        ss<<"udpsrc port="<<m_udp_port<<" ";

        if(m_video_codec==VideoCodecH264){

        }else if(m_video_codec==VideoCodecH265){

        }else{
            //m_video_codec==VideoCodecMJPEG
        }

    }

    ss << " glupload ! glcolorconvert !";
    ss << " qmlglsink name=qmlglsink sync=false";

    qDebug() << "GSTREAMER PIPE=" << ss.str().c_str();

    GError *error = nullptr;
    m_pipeline = gst_parse_launch(ss.str().c_str(), &error);
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
    }
    GstElement *qmlglsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qmlglsink");
}
