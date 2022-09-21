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
       qDebug()<<"MMAL mmal_port_format_commit error"<<mmal_status_to_string(status);
      return;
   }

   status = mmal_component_enable(m_Renderer);
   if (status != MMAL_SUCCESS) {
       qDebug()<<"MMAL mmal_component_enable error"<<mmal_status_to_string(status);
       return;
   }
   {
           MMAL_DISPLAYREGION_T dr = {};

           dr.hdr.id = MMAL_PARAMETER_DISPLAYREGION;
           dr.hdr.size = sizeof(MMAL_DISPLAYREGION_T);

           dr.set |= MMAL_DISPLAY_SET_FULLSCREEN;
           dr.fullscreen = MMAL_FALSE;

           dr.set |= MMAL_DISPLAY_SET_MODE;
           dr.mode = MMAL_DISPLAY_MODE_LETTERBOX;

           dr.set |= MMAL_DISPLAY_SET_NOASPECT;
           dr.noaspect = MMAL_TRUE;

           dr.set |= MMAL_DISPLAY_SET_SRC_RECT;
           dr.src_rect.x = 0;
           dr.src_rect.y = 0;
           dr.src_rect.width = video_width;
           dr.src_rect.height = video_height;

           status = mmal_port_parameter_set(m_InputPort, &dr.hdr);
           if (status != MMAL_SUCCESS) {
               qDebug()<<"mmal_port_parameter_set error"<<mmal_status_to_string(status);
               return;
           }
   }
   status = mmal_port_enable(m_InputPort, InputPortCallback);
      if (status != MMAL_SUCCESS) {
           qDebug()<<"mmal_port_enable"<<mmal_status_to_string(status);
          return;
      }
   qDebug()<<"MMAL ready X?!";

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

void RpiMMALDisplay::updateDisplayRegion()
{

}

void RpiMMALDisplay::display_frame(AVFrame *frame)
{
    MMAL_BUFFER_HEADER_T* buffer = (MMAL_BUFFER_HEADER_T*)frame->data[3];
    MMAL_STATUS_T status;

    // Update the destination display region in case the window moved
    updateDisplayRegion();

    status = mmal_port_send_buffer(m_InputPort, buffer);
    if (status != MMAL_SUCCESS) {
        qDebug()<<"mmal_port_send_buffer() failed: "<<mmal_status_to_string(status));
    }
    else {
        // Prevent the buffer from being freed during av_frame_free()
        // until rendering is complete. The reference is dropped in
        // InputPortCallback().
        mmal_buffer_header_acquire(buffer);
    }
}

void RpiMMALDisplay::InputPortCallback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
     mmal_buffer_header_release(buffer);
}
