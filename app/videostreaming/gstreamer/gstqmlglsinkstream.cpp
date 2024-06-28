#include "gstqmlglsinkstream.h"

#include <QtQuick>
#include <sstream>

#include "gst_helper.hpp"

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
   if(videoCodec==QOpenHDVideoHelper::VideoCodec::VideoCodecH264){
       // WTF WTF
       ss<<"h264parse ! ";
   }else if(videoCodec==QOpenHDVideoHelper::VideoCodec::VideoCodecH265){
       // WTF WTF
       ss<<"h265parse ! ";
   }
   ss<<"nvv4l2decoder ";
   if(videoCodec==QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG){
       ss<<"mjpeg=true ";
   }
   // TODO enable by default ?!
   //ss<<"enable-max-performance=true ";
   // does this help ?!
   ss<<"enable-error-check=true ";
   ss<<"! ";
   return ss.str();
}

static std::string gst_create_video_decoder(const QOpenHDVideoHelper::VideoCodec& videoCodec,bool force_sw){
   qDebug()<<"gst_create_video_decoder force_sw:"<<force_sw;
    if(force_sw){
        return gst_create_always_software_decoder(videoCodec);
    }
    std::stringstream ss;
    // NOTE: force sw only has an effect on when decodebin does hw automatically, and on h264
    if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
        //NOTE: decodebin on rpi for h264 only worked after we updated the kernel.
        ss<<"h264parse ! ";
        ss<<"decodebin ! ";
    }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
        //ss<<"h265parse ! ";
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
    // QmlglSik is always for secondary video -
    // unless the user switched them around

    auto stream_config=config.secondary_stream_config;
    if(config.generic.qopenhd_switch_primary_secondary){
       stream_config=config.primary_stream_config;
    }
    std::stringstream ss;

    ss<<"udpsrc port="<<stream_config.udp_rtp_input_port<<" ";
    ss<<pipeline::gst_create_rtp_caps(pipeline::conv_codec(stream_config.video_codec))<<" ! ";

    // add rtp decoder
    ss<<pipeline::create_rtp_depacketize_for_codec(pipeline::conv_codec(stream_config.video_codec));
    // add video decoder
    ss<<gst_create_video_decoder(stream_config.video_codec,stream_config.enable_software_video_decoder);

    //ss<<" videoconvert n-threads=2 ! queue ! video/x-raw,format=RGBA !";
    if(false){
        ss<<"nvvidconv ! glupload  ! qmlglsink name=qmlglsink sync=false";
    }else{
        ss << " queue ! ";
        ss << " glupload ! glcolorconvert !";
        ss << " qmlglsink name=qmlglsink sync=false";
    }
    return ss.str();
}

static void debug_gstreamer_pipeline_state(GstElement *gst_pipeline){
    assert(gst_pipeline!=nullptr);
    GstState state;
    GstState pending;
    auto returnValue = gst_element_get_state(gst_pipeline, &state, &pending, 1000*1000*1000); // timeout in ns
    if (returnValue == 0) {
        qDebug()<<"Gstreamer most likely there is something wrong with the pipeline "<<returnValue;
    }
}

GstQmlGlSinkStream::GstQmlGlSinkStream(bool is_primary,QObject *parent)
    : QObject(parent),
      timer(new QTimer),
      m_isPrimaryStream(is_primary)
{
    qDebug() << "GstQmlGlSinkStream::GstQmlGlSinkStream()";
    // NOTE: the gstreamer init stuff should be already called via main !
}

GstQmlGlSinkStream::~GstQmlGlSinkStream() {
     qDebug() << "GstQmlGlSinkStream::~GstQmlGlSinkStream()begin";
    if(timer){
        timer->stop();
        delete timer;
    }
    stopVideoSafe();
    qDebug() << "GstQmlGlSinkStream::~GstQmlGlSinkStream()end";
}

GstQmlGlSinkStream& GstQmlGlSinkStream::instancePrimary()
{
    qDebug() << "GstQmlGlSinkStream::instancePrimary()";
    static GstQmlGlSinkStream instancePrimary{true};
    return instancePrimary;
}

GstQmlGlSinkStream& GstQmlGlSinkStream::instanceSecondary()
{
    qDebug() << "GstQmlGlSinkStream::instanceSecondary()";
    static GstQmlGlSinkStream instanceSecondary{false};
    return instanceSecondary;
}


void GstQmlGlSinkStream::init(QQuickItem* videoOutputWindow) {
    qDebug() << "GstQmlGlSinkStream::init();START";
    // we do not support changing the output window once it is assigned
    assert(m_videoOutputWindow==nullptr);
    assert(videoOutputWindow);
    m_videoOutputWindow=videoOutputWindow;
    m_videoStreamConfig=QOpenHDVideoHelper::read_config_from_settings();
    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
    QObject::connect(timer, &QTimer::timeout, this, &GstQmlGlSinkStream::timerCallback);
    timer->start(1000);
    qDebug() << "GstQmlGlSinkStream::init();END";
}

void GstQmlGlSinkStream::check_common_mistakes_then_init(QQuickItem* qmlglsinkvideoitem)
{
    if(qmlglsinkvideoitem==nullptr){
        qWarning("init called withut valid window");
        return;
    }
    if(m_videoOutputWindow!=nullptr){
        qWarning("init called with window already set");
        return;
    }
    init(qmlglsinkvideoitem);
}



static gboolean PipelineCb(GstBus *bus, GstMessage *msg, gpointer data) {
    auto instance = static_cast<GstQmlGlSinkStream*>(data);
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


void GstQmlGlSinkStream::startVideo() {
    qDebug()<<"GstQmlGlSinkStream::startVideo() begin";
    if(m_pipeline!=nullptr){
        //qDebug()<<"You probably forgot to call stopVideo";
        stopVideoSafe();
        assert(m_pipeline==nullptr);
    }
    const auto pipeline=constructGstreamerPipeline(m_videoStreamConfig);
    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=[" << pipeline.c_str()<<"]";
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

    gst_element_set_state (m_pipeline, GST_STATE_PLAYING);
    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
    qDebug()<<"GstQmlGlSinkStream::startVideo() end";
}

void GstQmlGlSinkStream::stopVideoSafe() {
    qDebug() << "GstQmlGlSinkStream::stopVideoSafe()::begin";
    if (m_pipeline != nullptr) {
        // Needed on jetson ?!
        gst_element_send_event ((GstElement*)m_pipeline, gst_event_new_eos ());
        gst_element_set_state(m_pipeline, GST_STATE_PAUSED);
        gst_element_set_state (m_pipeline, GST_STATE_NULL);
        gst_object_unref (m_pipeline);
        m_pipeline=nullptr;
    }
    qDebug() << "GstQmlGlSinkStream::stopVideoSafe()::end";
}

void GstQmlGlSinkStream::dev_restart_stream()
{
    // we just set decoder error to true, such that the timer will stop and then restart the video stream
    has_decoder_error=true;
}

void GstQmlGlSinkStream::timerCallback() {
    if(m_videoOutputWindow==nullptr){
        if(nTimesVideoQmlElementNotSet<10){
            // Most likely the qmlglsink is not found by qt - install gstreamer with qmlglsink enabled)
            qDebug()<<"no qmlglsink window, cannot start video";
        }
        nTimesVideoQmlElementNotSet++;
        return;
    }
    assert(m_videoOutputWindow!=nullptr);
    // read config from settings
    const QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig=QOpenHDVideoHelper::read_config_from_settings();
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


