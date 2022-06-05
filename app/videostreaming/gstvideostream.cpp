#if defined(ENABLE_GSTREAMER)

#include "gstvideostream.h"

#include <QtConcurrent>
#include <QtQuick>
#include <sstream>

#include "gst_helper.hpp"
#include "QOpenHDVideoHelper.hpp"


static QOpenHDVideoHelper::VideoStreamConfig readVideoStreamConfigFromSettings(bool isPrimary){
    // read settings
    QSettings settings;
    QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig;
    _videoStreamConfig.enable_videotest=settings.value("dev_enable_test_video", false).toBool();
    const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
    _videoStreamConfig.video_codec=QOpenHDVideoHelper::intToVideoCodec(tmp_video_codec);
    //auto _main_video_port = settings.value("main_video_port", main_default_port).toInt();
    if(isPrimary){
         _videoStreamConfig.video_port=OHDIntegration::OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP;
    }else{
         _videoStreamConfig.video_port=OHDIntegration::OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP;
    }
    return _videoStreamConfig;
}

/**
 * @brief constructGstreamerPipeline for sw decoding of all OenHD supported video formats (h264,h265,mjpeg)
 * The last element is a qmlglsink, such that the video can be rendered.
 * @param enableVideoTest if true, a testsrc is created and the other parameters are omitted (no decoding)
 * @param videoCodec the video codec the received rtp data is interpreted as
 * @param udp_port the udp port to listen for rtp data
 * @return the built pipeline, as a string
 */
static std::string constructGstreamerPipeline(bool enableVideoTest,QOpenHDVideoHelper::VideoCodec videoCodec,int udp_port){
    std::stringstream ss;
    if(enableVideoTest){
        qDebug() << "Using video test";
        ss << "videotestsrc pattern=smpte !";
        ss << "video/x-raw,width=640,height=480 !";
        ss << "queue !";
    }else{
        ss<<"udpsrc port="<<udp_port<<" ";
        if(videoCodec==QOpenHDVideoHelper::VideoCodecH264){
            ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)H264, payload=(int)96\" ! rtph264depay ! ";
        }else if(videoCodec==QOpenHDVideoHelper::VideoCodecH265){
            ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)H265\" ! rtph265depay ! ";
        }else{
            //m_video_codec==VideoCodecMJPEG
            ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)mjpeg\" ! rtpjpegdepay ! ";
        }
        ss<<"decodebin ! ";
    }
    ss << " glupload ! glcolorconvert !";
    ss << " qmlglsink name=qmlglsink sync=false";
    return ss.str();
}

GstVideoStream::GstVideoStream(QObject *parent): QObject(parent), timer(new QTimer) {
    qDebug() << "GstVideoStream::GstVideoStream()";
    // developer testing
    //QSettings settings;
    //settings.setValue("dev_enable_test_video",true);
    initGstreamerOrThrow();
    initQmlGlSinkOrThrow();
    customizeGstreamerLogPath();
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

    switch (GST_MESSAGE_TYPE(msg)){
    case GST_MESSAGE_EOS:{
            break;
        }
        case GST_MESSAGE_ERROR:{
            break;
        }
        case GST_MESSAGE_WARNING:{
            break;
        }
        case GST_MESSAGE_INFO:{
            break;
        }
        case GST_MESSAGE_TAG:{
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


void GstVideoStream::startVideo() {
    if(m_pipeline!=nullptr){
        //qDebug()<<"You probably forgot to call stopVideo";
        stopVideoSafe();
        assert(m_pipeline==nullptr);
    }
    const auto pipeline=constructGstreamerPipeline(m_videoStreamConfig.enable_videotest,m_videoStreamConfig.video_codec,m_videoStreamConfig.video_port);
    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=" << pipeline.c_str();
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
    }

    link_gstreamer_pipe_to_qt_window(m_pipeline,m_videoOutputWindow);

    GstBus *bus = gst_pipeline_get_bus (GST_PIPELINE(m_pipeline));
    gst_bus_add_signal_watch(bus);
    g_signal_connect(bus, "message", (GCallback)PipelineCb, this);

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
    qDebug() << "GstVideoStream::_stop()";
    if (m_pipeline != nullptr) {
        gst_element_set_state (m_pipeline, GST_STATE_NULL);
        gst_object_unref (m_pipeline);
        m_pipeline=nullptr;
    }
}

void GstVideoStream::timerCallback() {
    assert(m_videoOutputWindow!=nullptr);
    // read config from settings
    const QOpenHDVideoHelper::VideoStreamConfig _videoStreamConfig=readVideoStreamConfigFromSettings(m_isPrimaryStream);
    // check if settings have changed or we haven't started anything at all yet
    if((m_videoStreamConfig!=_videoStreamConfig) || m_pipeline == nullptr){
        m_videoStreamConfig=_videoStreamConfig;
        startVideo();
    }
    // check if we are getting video - TODO
    const auto currentTime = QDateTime::currentMSecsSinceEpoch();
    /*if (currentTime - lastDataTimeout < 2500) {
        if (m_stream_type == StreamTypeMain) {
            OpenHD::instance()->set_main_video_running(false);
        } else {
            OpenHD::instance()->set_pip_video_running(false);
        }
    } else {
        if (m_stream_type == StreamTypeMain) {
            OpenHD::instance()->set_main_video_running(true);
        } else {
            OpenHD::instance()->set_pip_video_running(true);
        }
    }*/
}



#endif
