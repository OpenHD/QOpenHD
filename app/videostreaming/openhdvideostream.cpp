#if defined(ENABLE_GSTREAMER)

#include "openhdvideostream.h"

#include <QtConcurrent>
#include <QtQuick>

#include "gst_platform_include.h"

#include "../util/localmessage.h"
#include <sstream>

#include "openhd.h"
#include "QOpenHDVideoHelper.hpp"


OpenHDVideoStream::OpenHDVideoStream(QObject * parent): QObject(parent), timer(new QTimer) {
    qDebug() << "OpenHDVideoStream::OpenHDVideoStream()";

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

    initGstreamerOrThrow();
    initQmlGlSinkOrThrow();
}


OpenHDVideoStream::~OpenHDVideoStream() {
    qDebug() << "~OpenHDVideoStream()";
}


void OpenHDVideoStream::init(QQuickItem* videoOutputWindow) {
    VideoStreamConfig videoStreamConfig{true,0,VideoCodecH264};
    m_videoStreamConfig=videoStreamConfig;
    m_videoOutputWindow=videoOutputWindow;

    /*QSettings settings;
    m_enable_videotest = settings.value("enable_videotest", false).toBool();

    const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
    m_video_codec=intToVideoCodec(tmp_video_codec);*/


    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();

    QObject::connect(timer, &QTimer::timeout, this, &OpenHDVideoStream::_timer);
    timer->start(1000);

    qDebug() << "OpenHDVideoStream::init()";
}



static gboolean PipelineCb(GstBus *bus, GstMessage *msg, gpointer data) {
    auto instance = static_cast<OpenHDVideoStream*>(data);

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

static void link_gsteamer_to_qt_window(QQuickItem *qtOutWindow,GstElement *qmlglsink){
      g_object_set(qmlglsink, "widget", qtOutWindow, NULL);
}

/**
 * @brief constructGstreamerPipeline for sw decoding of all OenHD supported video formats (h264,h265,mjpeg)
 * The last element is a qmlglsink, such that the video can be rendered.
 * @param enableVideoTest if true, a testsrc is created and the other parameters are omitted (no decoding)
 * @param videoCodec the video codec the received rtp data is interpreted as
 * @param udp_port the udp port to listen for rtp data
 * @return the built pipeline, as a string
 */
static std::string constructGstreamerPipeline(bool enableVideoTest,VideoCodec videoCodec,int udp_port){
    std::stringstream ss;
    if(enableVideoTest){
        qDebug() << "Using video test\n";
        ss << "videotestsrc pattern=smpte !";
        ss << "video/x-raw,width=640,height=480 !";
        ss << "queue !";
    }else{
        ss<<"udpsrc port="<<udp_port<<" ";
        if(videoCodec==VideoCodecH264){
            ss<<"caps = \"application/x-rtp, media=(string)video, encoding-name=(string)H264, payload=(int)96\" ! rtph264depay ! ";
        }else if(videoCodec==VideoCodecH265){
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

void OpenHDVideoStream::_start() {
    const auto pipeline=constructGstreamerPipeline(true,VideoCodecH264,5620);

    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=" << pipeline.c_str();
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
    }
    GstElement *qmlglsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qmlglsink");

    GstBus *bus = gst_pipeline_get_bus (GST_PIPELINE(m_pipeline));

    gst_bus_add_signal_watch(bus);
    g_signal_connect(bus, "message", (GCallback)PipelineCb, this);

    link_gsteamer_to_qt_window(m_videoOutputWindow,qmlglsink);

    /*
     * When the app first launches we have to wait for the QML element to be ready before the pipeline
     * starts pushing frames to it.
     *
     * After that point we can just set the pipeline to GST_STATE_PLAYING directly.
     */
    if (firstRun) {
        firstRun = false;
        //rootObject->scheduleRenderJob(new SetPlaying (m_pipeline), QQuickWindow::BeforeSynchronizingStage);
    } else {
        gst_element_set_state (m_pipeline, GST_STATE_PLAYING);
    }

    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
    OpenHD::instance()->set_main_video_running(false);
    OpenHD::instance()->set_pip_video_running(false);

    mainLoop = g_main_loop_new(nullptr, FALSE);
    g_main_loop_run(mainLoop);
}

/*
 * Fired by m_timer.
 *
 * Checks every second if the enable_videotest setting has changed, if so we restart the
 * stream and let the the pipeline be reconstructed using whichever video source is now enabled.
 */
void OpenHDVideoStream::_timer() {    
    // skip everything until the video is known to have started at least once.
    if (firstRun) {
        return;
    }

    QSettings settings;

    VideoStreamConfig _videoStreamConfig;
    _videoStreamConfig.enable_videotest=settings.value("enable_videotest", false).toBool();
    const int tmp_video_codec = settings.value("selectedVideoCodecPrimary", 0).toInt();
    _videoStreamConfig.video_codec=intToVideoCodec(tmp_video_codec);
    //auto _main_video_port = settings.value("main_video_port", main_default_port).toInt();
    _videoStreamConfig.video_port=OHDIntegration::OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP;

    if(!(m_videoStreamConfig==_videoStreamConfig)){
        startVideo();
    }


    auto currentTime = QDateTime::currentMSecsSinceEpoch();

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


void OpenHDVideoStream::startVideo() {
    //QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
    _start();
}

void OpenHDVideoStream::_stop() {
    qDebug() << "OpenHDVideoStream::_stop()";
    if (m_pipeline != nullptr) {
        gst_element_set_state (m_pipeline, GST_STATE_NULL);
        //gst_object_unref (m_pipeline);
        g_main_loop_quit(mainLoop);
    }
}

void OpenHDVideoStream::stopVideo() {
    //QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_stop);
    _stop();
}


#endif
