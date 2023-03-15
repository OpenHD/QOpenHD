#include "gstrtpaudioplayer.h"
#include "gst/gstparse.h"
#include "gst/gstpipeline.h"

#include <assert.h>
#include <qdebug.h>

#include <sstream>

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
    ss<<"audiotestsrc ! autoaudiosink";
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
        return;
    }
    if(!m_gst_pipeline || !(GST_IS_PIPELINE(m_gst_pipeline))){
        qDebug()<<"Cannot construct pipeline";
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
