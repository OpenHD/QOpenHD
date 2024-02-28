#include "gstrtpaudioplayer.h"
#include "gst/gstparse.h"
#include "gst/gstpipeline.h"

#include <assert.h>
#include <qdebug.h>
#include <sstream>

#include <logging/logmessagesmodel.h>

GstRtpAudioPlayer::GstRtpAudioPlayer()
{

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
    ss<<" ! rtppcmadepay ! audio/x-alaw, rate=8000, channels=1 ! alawdec ! autoaudiosink sync=false";
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
        on_error("audio parse launch error");
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
