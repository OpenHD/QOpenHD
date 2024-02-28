#include "gstrtpaudioplayer.h"
#include "gst/gstparse.h"
#include "gst/gstpipeline.h"

#include <assert.h>
#include <qdebug.h>
#include <sstream>

#include <logging/logmessagesmodel.h>

G_BEGIN_DECLS
// The static plugins we use
#if defined(__android__) || defined(__ios__)
    GST_PLUGIN_STATIC_DECLARE(coreelements);
    GST_PLUGIN_STATIC_DECLARE(playback);
    GST_PLUGIN_STATIC_DECLARE(libav);
    GST_PLUGIN_STATIC_DECLARE(rtp);
    GST_PLUGIN_STATIC_DECLARE(rtsp);
    GST_PLUGIN_STATIC_DECLARE(udp);
    GST_PLUGIN_STATIC_DECLARE(videoparsersbad);
    GST_PLUGIN_STATIC_DECLARE(x264);
    GST_PLUGIN_STATIC_DECLARE(rtpmanager);
    GST_PLUGIN_STATIC_DECLARE(isomp4);
    GST_PLUGIN_STATIC_DECLARE(matroska);
    GST_PLUGIN_STATIC_DECLARE(mpegtsdemux);
    GST_PLUGIN_STATIC_DECLARE(opengl);
    GST_PLUGIN_STATIC_DECLARE(tcp);
    GST_PLUGIN_STATIC_DECLARE(app);//XX
    GST_PLUGIN_STATIC_DECLARE(alaw);
    //GST_PLUGIN_STATIC_DECLARE(autodetect);
#if defined(__android__)
    GST_PLUGIN_STATIC_DECLARE(androidmedia);
#elif defined(__ios__)
    GST_PLUGIN_STATIC_DECLARE(applemedia);
#endif
#endif
    GST_PLUGIN_STATIC_DECLARE(qmlgl);
    GST_PLUGIN_STATIC_DECLARE(qgc);
G_END_DECLS

GstRtpAudioPlayer::GstRtpAudioPlayer()
{
#if defined(__android__) || defined(__ios__)
    GST_PLUGIN_STATIC_REGISTER(coreelements);
    GST_PLUGIN_STATIC_REGISTER(playback);
    GST_PLUGIN_STATIC_REGISTER(libav);
    GST_PLUGIN_STATIC_REGISTER(rtp);
    GST_PLUGIN_STATIC_REGISTER(rtsp);
    GST_PLUGIN_STATIC_REGISTER(udp);
    GST_PLUGIN_STATIC_REGISTER(videoparsersbad);
    GST_PLUGIN_STATIC_REGISTER(x264);
    GST_PLUGIN_STATIC_REGISTER(rtpmanager);
    GST_PLUGIN_STATIC_REGISTER(isomp4);
    GST_PLUGIN_STATIC_REGISTER(matroska);
    GST_PLUGIN_STATIC_REGISTER(mpegtsdemux);
    GST_PLUGIN_STATIC_REGISTER(opengl);
    GST_PLUGIN_STATIC_REGISTER(tcp);
    GST_PLUGIN_STATIC_REGISTER(app);//XX
    GST_PLUGIN_STATIC_REGISTER(alaw);
    //GST_PLUGIN_STATIC_REGISTER(autodetect);
#if defined(__android__)
    GST_PLUGIN_STATIC_REGISTER(androidmedia);
#elif defined(__ios__)
    GST_PLUGIN_STATIC_REGISTER(applemedia);
#endif
#endif
}

GstRtpAudioPlayer &GstRtpAudioPlayer::instance()
{
    static GstRtpAudioPlayer instance{};
    return instance;
}


static std::string construct_gstreamer_pipeline(){
    std::stringstream ss;
    //ss<<"audiotestsrc ! autoaudiosink";
    //ss<<"udpsrc port=5610 caps=\"application/x-rtp, media=(string)audio, clock-rate=(int)8000, encoding-name=(string)L16, encoding-params=(string)1, channels=(int)1, payload=(int)96\" ! rtpL16depay ! queue ! autoaudiosink sync=false";
    ss<<"udpsrc port=5610 caps=\"application/x-rtp, media=(string)audio, clock-rate=(int)8000, encoding-name=(string)PCMA\"";
    ss<<" ! rtppcmadepay ! audio/x-alaw, rate=8000, channels=1 ! alawdec ! ";
    //ss<<"autoaudiosink sync=false";
    ss<<"openslessink";
    return ss.str();
}

void GstRtpAudioPlayer::start_playing()
{
    qDebug()<<"GstRtpAudioPlayer::start_playing() begin";
    assert(m_gst_pipeline==nullptr);
    const auto pipeline=construct_gstreamer_pipeline();
    GError *error = nullptr;
    m_gst_pipeline = gst_parse_launch(pipeline.c_str(), &error);
    qDebug() << "GSTREAMER PIPE=[" << pipeline.c_str()<<"]";
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
        //on_error("audio parse launch error");
        on_error(error->message);
        return;
    }
    if(!m_gst_pipeline || !(GST_IS_PIPELINE(m_gst_pipeline))){
        qDebug()<<"Cannot construct pipeline";
        on_error("audio pipeline error");
        m_gst_pipeline = nullptr;
        return;
    }
    gst_element_set_state (m_gst_pipeline, GST_STATE_PLAYING);
    qDebug()<<"GstRtpAudioPlayer::start_playing() end";
}

void GstRtpAudioPlayer::stop_playing()
{
    if (m_gst_pipeline != nullptr) {
        gst_element_send_event ((GstElement*)m_gst_pipeline, gst_event_new_eos ());
        gst_element_set_state(m_gst_pipeline, GST_STATE_PAUSED);
        gst_element_set_state (m_gst_pipeline, GST_STATE_NULL);
        gst_object_unref (m_gst_pipeline);
        m_gst_pipeline=nullptr;
    }
}

void GstRtpAudioPlayer::on_error(std::string tag)
{
    LogMessagesModel::instanceGround().add_message_debug("QOpenHD",tag.c_str());
}
