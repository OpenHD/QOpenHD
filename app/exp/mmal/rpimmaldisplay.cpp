#include "rpimmaldisplay.h"

#include <qdebug.h>


RpiMMALDisplay::RpiMMALDisplay()
{

}

RpiMMALDisplay &RpiMMALDisplay::instance()
{
    static RpiMMALDisplay instance;
    return instance;
}


void RpiMMALDisplay::init(int video_width,int video_height)
{
    qDebug()<<"Test MMAL";
    MMAL_STATUS_T status;
    status = mmal_component_create(MMAL_COMPONENT_DEFAULT_VIDEO_RENDERER, &m_Renderer);
   if (status != MMAL_SUCCESS) {
       qDebug()<<"MMAl error";
       return;
   }else{
       qDebug()<<"MMAL success";
   }

   m_InputPort = m_Renderer->input[0];

   m_InputPort->format->encoding = MMAL_ENCODING_OPAQUE;
   m_InputPort->format->es->video.width = video_width;
   m_InputPort->format->es->video.height = video_width;
   m_InputPort->format->es->video.crop.x = 0;
   m_InputPort->format->es->video.crop.y = 0;
   m_InputPort->format->es->video.crop.width = video_width;
   m_InputPort->format->es->video.crop.height = video_width;

   // Setting colorspace like this doesn't seem to make a difference,
   // but we'll do it just in case it starts working in the future.
   // The default appears to be Rec. 709 already.
   m_InputPort->format->es->video.color_space = MMAL_COLOR_SPACE_ITUR_BT709;

   status = mmal_port_format_commit(m_InputPort);
   if (status != MMAL_SUCCESS) {
       qDebug()<<"MMAL mmal_port_format_commit error";
      return;
   }

   status = mmal_component_enable(m_Renderer);
   if (status != MMAL_SUCCESS) {
       qDebug()<<"MMAL mmal_component_enable error";
       return;
   }
   qDebug()<<"MMAL ready ?!";

}

void RpiMMALDisplay::cleanup()
{
    if (m_InputPort != nullptr) {
            mmal_port_disable(m_InputPort);
        }

        if (m_Renderer != nullptr) {
            mmal_component_destroy(m_Renderer);
        }
}
