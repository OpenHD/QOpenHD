#ifndef GST_PLATFORM_INCLUDE_H
#define GST_PLATFORM_INCLUDE_H


// Use this file to include gstreamer into your project, independend of platform
// (TODO: rn everythng except standart ubuntu has been deleted).
// exposes a initGstreamerOrThrow() method that should be called before any actual gstreamer calls.

#include "QOpenHDVideoHelper.hpp"
#include "qglobal.h"
#include <gst/gst.h>
#include <QString>
#include <qquickitem.h>
#include <stdexcept>
#include <sstream>
#include <qqmlapplicationengine.h>
#include <QDebug>
#include <logging/logmessagesmodel.h>

/**
 * @brief initGstreamer, throw a run time exception when failing
 */
static void initGstreamerOrThrow(){
    GError* error = nullptr;
    if (!gst_init_check(nullptr,nullptr, &error)) {
        std::stringstream ss;
        ss<<"Cannot initialize gstreamer";
        ss<<error->code<<":"<<error->message;
        g_error_free(error);
        throw std::runtime_error(ss.str().c_str());
    }
}

// Similar to above, but takes argc/ argv from command line.
// This way it is possible to pass on extra stuff at run time onto gstreamer by launching
// QOpenHD with some argc/ argvalues
static void init_gstreamer(int argc,char* argv[]){
    GError* error = nullptr;
    if (!gst_init_check(&argc,&argv, &error)) {
        std::stringstream ss;
        ss<<"Cannot initialize gstreamer";
        ss<<error->code<<":"<<error->message;
        g_error_free(error);
        qWarning("gst_init_check failed");
        return;
    }
    qDebug("gst_init_check success");
}

// If qmlgl plugin was dynamically linked, this will force GStreamer to go find it and
// load it before the QML gets loaded in main.cpp (without this, Qt will complain that
// it can't find org.freedesktop.gstreamer.GLVideoItem)
// From https://github.com/GStreamer/gst-examples/blob/b27bcc187e867897dcd169cd46f8d9bc403210e8/playback/player/qt/main.cpp#L51
// NOTE: Basically, it looks as if you NEED to do this before QT loads any .qml file(s) and if it fails
// qmlglsink won't work !!
static bool init_qmlglsink(){
    GstElement *sink = gst_element_factory_make("qmlglsink", NULL);
    if(sink==nullptr){
        return false;
    }
    gst_object_unref(sink);
    return true;
}

static void init_qmlglsink_and_log(){
    const bool success=init_qmlglsink();
    if(success){
        qDebug()<<"qmlglsink found - gstreamer + qmlglsink should work";
    }else{
        qWarning("qmlglsink not found - check your gstreamer installation");
        // We display this as an openhd log, just because it has happened so often now that people complain about secondary video not working,
        // which almost always is the missing gst package
        LogMessagesModel::instanceGround().add_message_warn("QOpenHD","QMLGLSINK not found (secondary video won't work)");
    }
}

// not sure, customize the path where gstreamer log is written to
static void customizeGstreamerLogPath(){
    char debuglevel[] = "*:3";
    #if defined(__android__)
    char logpath[] = "/sdcard";
    #else
    char logpath[] = "/tmp";
    #endif
    qputenv("GST_DEBUG", debuglevel);
    QString file = QString("%1/%2").arg(logpath).arg("gstreamer-log.txt");
    qputenv("GST_DEBUG_NO_COLOR", "1");
    qputenv("GST_DEBUG_FILE", file.toStdString().c_str());
    qputenv("GST_DEBUG_DUMP_DOT_DIR", logpath);
}

static QString get_gstreamer_version() {
    guint major, minor, micro, nano;
    gst_version(&major, &minor, &micro, &nano);
    QString gst_ver = QString();
    QTextStream s(&gst_ver);
    s << major;
    s << ".";
    s << minor;
    s << ".";
    s << micro;
    return gst_ver;
}

// link gstreamer qmlglsink to qt window
static void link_gsteamer_to_qt_window(GstElement *qmlglsink,QQuickItem *qtOutWindow){
      g_object_set(qmlglsink, "widget", gpointer(qtOutWindow), NULL);
}

// find qmlglsink in gstreamer pipeline and link it to the window
static void link_gstreamer_pipe_to_qt_window(GstElement * m_pipeline,QQuickItem *qtOutWindow){
    GstElement *qmlglsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qmlglsink");
    if(qmlglsink==nullptr){
        qDebug()<<"link_gstreamer_pipe_to_qt_window: no qmlglimagesink";
        return;
    }
    link_gsteamer_to_qt_window(qmlglsink,qtOutWindow);
}


// Creates a pipeline whose last element produces rtp h264,h265 or mjpeg data
static std::string create_debug_encoded_data_producer(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    std::stringstream ss;
    ss<<"videotestsrc ! video/x-raw, format=I420,width=640,height=480,framerate=30/1 ! ";
    if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
        ss<<"x264enc bitrate=5000 tune=zerolatency key-int-max=10 ! h264parse config-interval=-1 ! ";
        ss<<"rtph264pay mtu=1024 ! ";
    }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
        ss<<"x265enc bitrate=5000 tune=zerolatency ! ";
        ss<<"rtph265pay mtu=1024 ! ";
    }else{
        ss<<"jpegenc ! ";
        ss << "rtpjpegpay mtu=1024 ! ";
    }
    ss<<"queue ! ";
    return ss.str();
}
namespace pipeline{
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
static std::string create_out_caps(const VideoCodec& codec){
    if(codec==VideoCodec::H264){
        std::stringstream ss;
        ss<<"video/x-h264";
        ss<<", stream-format=\"byte-stream\"";
        //ss<<", alignment=\"nal\"";
        ss<<" ! ";
        return ss.str();
    }else if(codec==VideoCodec::H265){
        std::stringstream ss;
        ss<<"video/x-h265";
        ss<<", stream-format=\"byte-stream\"";
        //ss<<", alignment=\"nal\"";
        ss<<" ! ";
        return ss.str();
    }else{
        return "todo";
    }
    assert(false);
}
}


#endif // GST_PLATFORM_INCLUDE_H
