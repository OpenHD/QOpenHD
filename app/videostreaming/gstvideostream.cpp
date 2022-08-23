#if defined(ENABLE_GSTREAMER)

#include "gstvideostream.h"

#include <QtConcurrent>
#include <QtQuick>
#include <sstream>

#include "gst_helper.hpp"
#include "QOpenHDVideoHelper.hpp"


static QOpenHDVideoHelper::VideoStreamConfig readVideoStreamConfigFromSettings(bool isPrimary){
    // read settings
    QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig=QOpenHDVideoHelper::read_from_settings();
    if(isPrimary){
         _videoStreamConfig.video_port=OHDIntegration::OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP;
    }else{
         _videoStreamConfig.video_port=OHDIntegration::OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP;
    }
    return _videoStreamConfig;
}

static std::string gst_create_caps(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    std::stringstream ss;
    if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
        ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)H264, payload=(int)96\" ! ";
    }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
        ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)H265\" ! ";
    }else{
        ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)mjpeg\" ! ";
    }
    return ss.str();
}

static std::string gst_create_rtp_decoder(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    std::stringstream ss;
    if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
        ss<<" rtph264depay ! ";
    }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
        ss<<" rtph265depay ! ";
    }else{
       ss<<" rtpjpegdepay ! ";
    }
    return ss.str();
}

static std::string gst_create_always_software_decoder(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    std::stringstream ss;
    switch(videoCodec){
        case QOpenHDVideoHelper::VideoCodecH264:{
             ss<<"avdec_h264 ! ";
        }break;
        case QOpenHDVideoHelper::VideoCodecH265:{
            ss<<"avdec_h265 ! ";
        }break;
        case QOpenHDVideoHelper::VideoCodecMJPEG:{
            // avdec_jpeg seems to not exist on some hardware
            //ss<<"avdec_mjpeg ! ";
            ss<<"decodebin force-sw-decoders=true ! ";
        }break;
        default:assert(true);
        }
    return ss.str();
}

static std::string gst_create_jeston_test(const QOpenHDVideoHelper::VideoCodec& videoCodec){
    /*switch(videoCodec){
        case QOpenHDVideoHelper::VideoCodecH264:{
             return "omxh264dec ! ";
        }break;
        case QOpenHDVideoHelper::VideoCodecH265:{
            return "omxh265dec ! ";
        }break;
        case QOpenHDVideoHelper::VideoCodecMJPEG:{
            // avdec_jpeg seems to not exist on some hardware
            //ss<<"avdec_mjpeg ! ";
            return "decodebin force-sw-decoders=true ! ";
        }break;
        default:
        assert(true);
        return "";
   }*/
   std::stringstream ss;
   ss<<"nvv4l2decoder ";
   if(videoCodec==QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG){
       ss<<"mjpeg=true ";
   }
   // TODO enable by default ?!
   //ss<<"enable-max-performance=true ";
   ss<<"! ";
   return ss.str();
}

static std::string gst_create_video_decoder(const QOpenHDVideoHelper::VideoCodec& videoCodec,bool force_sw,bool dev_jetson){
    if(dev_jetson){
        return gst_create_jeston_test(videoCodec);
    }
    if(force_sw){
        return gst_create_always_software_decoder(videoCodec);
    }
    std::stringstream ss;
    // NOTE: force sw only has an effect on when decodebin does hw automatically, and on h264
    if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
        //NOTE: decodebin on rpi for h264 only worked after we updated the kernel.
        ss<<"decodebin ! ";
    }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
        ss<<"decodebin ! ";
    }else{
       ss<<"decodebin ! ";
    }
    return ss.str();
}

/**
 * @brief constructGstreamerPipeline for sw decoding of all OenHD supported video formats (h264,h265,mjpeg)
 * The last element is a qmlglsink, such that the video can be rendered.
 * @param enableVideoTest if true, a testsrc is created and the other parameters are omitted (no decoding)
 * @param videoCodec the video codec the received rtp data is interpreted as
 * @param udp_port the udp port to listen for rtp data
 * @return the built pipeline, as a string
 */
static std::string constructGstreamerPipeline(const QOpenHDVideoHelper::VideoStreamConfig& config){
    std::stringstream ss;
    if(config.dev_enable_custom_pipeline){
        qDebug()<<"Warning using custom pipeline, dev only";
        return config.dev_custom_pipeline;
    }
    if(config.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::RAW_VIDEO){
        ss << "videotestsrc pattern=smpte ! ";
        ss << "video/x-raw,format=RGBA,width=640,height=480 ! ";
        ss << "queue ! ";
        ss << "glupload ! glcolorconvert ! ";
        ss << "qmlglsink name=qmlglsink sync=false";
        return ss.str();
    }else if(config.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::RAW_VIDEO_ENCODE_DECODE){
        ss<<QOpenHDVideoHelper::create_debug_encoded_data_producer(config.video_codec);
    }else{
        ss<<"udpsrc port="<<config.video_port<<" ";
        ss<<gst_create_caps(config.video_codec);
    }
    // add rtp decoder
    ss<<gst_create_rtp_decoder(config.video_codec);
    // add video decoder
    ss<<gst_create_video_decoder(config.video_codec,config.enable_software_video_decoder,config.dev_jetson);

    //ss<<" videoconvert n-threads=2 ! queue ! video/x-raw,format=RGBA !";
    if(config.dev_jetson){
        ss<<"nvvidconv ! glupload  ! qmlglsink name=qmlglsink sync=false";
    }else{
        ss << " queue ! ";
        ss << " glupload ! glcolorconvert !";
        ss << " qmlglsink name=qmlglsink sync=false";
    }
    return ss.str();
}

GstVideoStream::GstVideoStream(QObject *parent): QObject(parent), timer(new QTimer) {
    qDebug() << "GstVideoStream::GstVideoStream()";
    // developer testing
    //QSettings settings;
    //settings.setValue("dev_test_video_mode",0);
    // NOTE: the gstreamer init stuff should be already called via main - only this way we can
    // pass in the parameters. Calling it again should have no effect then.
    initGstreamerOrThrow();
    initQmlGlSinkOrThrow();
    //customizeGstreamerLogPath();
}


GstVideoStream::~GstVideoStream() {
    stopVideoSafe();
    qDebug() << "GstVideoStream::~GstVideoStream()";
}


void GstVideoStream::init(QQuickItem* videoOutputWindow,bool primaryStream) {
    m_videoOutputWindow=videoOutputWindow;
    m_isPrimaryStream=primaryStream;
    m_videoStreamConfig=readVideoStreamConfigFromSettings(m_isPrimaryStream);
    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
    QObject::connect(timer, &QTimer::timeout, this, &GstVideoStream::timerCallback);
    timer->start(1000);
    qDebug() << "GstVideoStream::init()";
}



static gboolean PipelineCb(GstBus *bus, GstMessage *msg, gpointer data) {
    auto instance = static_cast<GstVideoStream*>(data);
    //qDebug()<<"PipelineCb"<<QString(GST_MESSAGE_TYPE_NAME(msg));
    switch (GST_MESSAGE_TYPE(msg)){
    case GST_MESSAGE_EOS:{
            break;
        }
        case GST_MESSAGE_ERROR: {
          gchar  *debug;
          GError *error;
          gst_message_parse_error (msg, &error, &debug);
          g_free (debug);
          qDebug()<<"Error:"<<QString(error->message);
          g_printerr ("Error: %s\n", error->message);
          g_error_free (error);
          instance->has_decoder_error=true;
          break;
        }
        case GST_MESSAGE_WARNING:{
            gchar  *debug;
            GError *error;
            gst_message_parse_warning(msg, &error, &debug);
            g_free (debug);
            qDebug()<<"Error:"<<QString(error->message);
            g_printerr ("Error: %s\n", error->message);
            g_error_free (error);
            break;
        }
        case GST_MESSAGE_INFO:{
            break;
        }
        case GST_MESSAGE_TAG:{
            //GstTagList* gstTagList;
            //gst_message_parse_tag(msg,&gstTagList);
            break;
        }
        case GST_MESSAGE_BUFFERING:{
            break;
        }
        case GST_MESSAGE_ELEMENT:{
            auto m = QString(gst_structure_get_name(gst_message_get_structure(msg)));
            if (m == "GstUDPSrcTimeout") {
                 qDebug() << "GstUDPSrcTimeout";
                instance->lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
            }
            break;
        }
        case GST_MESSAGE_LATENCY: {
            break;
        }
        case GST_MESSAGE_QOS: {
            break;
        }
        case GST_MESSAGE_UNKNOWN: {
            break;
        }
        default: {
            break;
        }
    }

    return TRUE;
}

// https://gstreamer.freedesktop.org/documentation/application-development/basics/helloworld.html?gi-language=c
static gboolean bus_call (GstBus *bus,GstMessage *msg,gpointer data){
  qDebug()<<"bus_call"<<QString(GST_MESSAGE_TYPE_NAME(msg));
  switch (GST_MESSAGE_TYPE (msg)) {
    case GST_MESSAGE_EOS:
      qDebug()<<"End of stream\n";
      break;
    case GST_MESSAGE_ERROR: {
      gchar  *debug;
      GError *error;
      gst_message_parse_error (msg, &error, &debug);
      g_free (debug);
      qDebug()<<"Error:"<<QString(error->message);
      g_printerr ("Error: %s\n", error->message);
      g_error_free (error);
      break;
    }
    default:
      break;
  }
  return TRUE;
}


void GstVideoStream::startVideo() {
    if(m_pipeline!=nullptr){
        //qDebug()<<"You probably forgot to call stopVideo";
        stopVideoSafe();
        assert(m_pipeline==nullptr);
    }
    const auto pipeline=constructGstreamerPipeline(m_videoStreamConfig);
    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=" << pipeline.c_str();
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
        return;
    }
    if(!m_pipeline || !(GST_IS_PIPELINE(m_pipeline))){
        qDebug()<<"Cannot construct pipeline";
        m_pipeline = nullptr;
        return;
    }

    GstBus *bus = gst_pipeline_get_bus (GST_PIPELINE(m_pipeline));
    gst_bus_add_signal_watch(bus);
    auto bus_watch_id = gst_bus_add_watch (bus, bus_call,this);
    g_signal_connect(bus, "message", (GCallback)PipelineCb, this);
    gst_object_unref (bus);

    link_gstreamer_pipe_to_qt_window(m_pipeline,m_videoOutputWindow);

    /*
     * When the app first launches we have to wait for the QML element to be ready before the pipeline
     * starts pushing frames to it.
     *
     * After that point we can just set the pipeline to GST_STATE_PLAYING directly.
     */
    /*if (firstRun) {
        firstRun = false;
        //rootObject->scheduleRenderJob(new SetPlaying (m_pipeline), QQuickWindow::BeforeSynchronizingStage);
    } else {
        gst_element_set_state (m_pipeline, GST_STATE_PLAYING);
    }*/
     gst_element_set_state (m_pipeline, GST_STATE_PLAYING);
    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
}

void GstVideoStream::stopVideoSafe() {
    qDebug() << "GstVideoStream::stopVideoSafe()::begin";
    if (m_pipeline != nullptr) {
        gst_element_set_state(m_pipeline, GST_STATE_PAUSED);
        gst_element_set_state (m_pipeline, GST_STATE_NULL);
        gst_object_unref (m_pipeline);
        m_pipeline=nullptr;
    }
    qDebug() << "GstVideoStream::stopVideoSafe()::end";
}

void GstVideoStream::timerCallback() {
    if(m_videoOutputWindow==nullptr){
        // Most likely the qmlglsink is not found by qt - install gstreamer with qmlglsink enabled)
        qDebug()<<"no qmlglsink window, cannot start video";
        return;
    }
    assert(m_videoOutputWindow!=nullptr);
    // read config from settings
    const QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig=readVideoStreamConfigFromSettings(m_isPrimaryStream);
    // check if settings have changed or we haven't started anything at all yet
    if((m_videoStreamConfig!=_videoStreamConfig) || m_pipeline == nullptr){
        m_videoStreamConfig=_videoStreamConfig;
        startVideo();
    }else{
        if(has_decoder_error){
            qDebug()<<"Decoder or pipeline error - restarting";
            stopVideoSafe();
            startVideo();
            has_decoder_error=false;
        }
    }
    // check if we are getting video - TODO
    const auto currentTime = QDateTime::currentMSecsSinceEpoch();
    /*if (currentTime - lastDataTimeout < 2500) {
        // stream is not running
    } else {
        // stream is running
    }*/
}



#endif
