#include "rpimmaldisplay.h"


#include "bcm_host.h"

#include <qdebug.h>


static void control_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
   struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

   switch (buffer->cmd)
   {
   case MMAL_EVENT_EOS:
      /* Only sink component generate EOS events */
      break;
   case MMAL_EVENT_ERROR:
       qDebug()<<"control_callback got error";
      /* Something went wrong. Signal this to the application */
      //ctx->status = *(MMAL_STATUS_T *)buffer->data;
      break;
   default:
      break;
   }

   /* Done with the event, recycle it */
   mmal_buffer_header_release(buffer);

   //qDebug()<<"control cb. status"<< ctx->status;
}

RpiMMALDisplay::RpiMMALDisplay()
{

}

RpiMMALDisplay &RpiMMALDisplay::instance()
{
    static RpiMMALDisplay instance;
    return instance;
}

bool RpiMMALDisplay::prepareDecoderContext(AVCodecContext *context, AVDictionary **options)
{
    // FFmpeg defaults this to 10 which is too large to fit in the default 64 MB VRAM split.
    // Reducing to 2 seems to work fine for our bitstreams (max of 1 buffered frame needed).
    //av_dict_set_int(options, "extra_buffers", 2, 0);
    // Consti10: We set the GPU memory, so we don't need to be scared, and also OpenHD does
    // not specify in any way that the stream generated at the air needs to have no frame buffering
    // (Since a webcam for example might not offer this option).
    av_dict_set_int(options, "extra_buffers", 10, 0);

    // MMAL seems to dislike certain initial width and height values, but it seems okay
    // with getting zero for the width and height. We'll zero them all the time to be safe.
    context->width = 0;
    context->height = 0;

    qDebug()<<"Using MMAL renderer";

    return true;
}


void RpiMMALDisplay::init(int video_width,int video_height)
{
    qDebug()<<"Test MMAL";
    bcm_host_init();
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
   status = mmal_port_enable(m_InputPort, InputPortCallback);
   if (status != MMAL_SUCCESS) {
        qDebug()<<"mmal_port_enable"<<mmal_status_to_string(status);
       return;
   }
   updateDisplayRegion();
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
    if(!display_region_needs_update){
        return;
    }
    qDebug()<<"updateDisplayRegion::begin";
    // We don't need to set anything in regards to source or dest recangle by using the
    // "letterbox" mode - if the video ratio doesn't match the screen, black bars will be added
    // while filling as much area as possible.
    MMAL_STATUS_T status;
    MMAL_DISPLAYREGION_T dr = {};
    dr.hdr.id = MMAL_PARAMETER_DISPLAYREGION;
    dr.hdr.size = sizeof(MMAL_DISPLAYREGION_T);
    // We need to go lower than -127 since that is where QT decides to go on.
    dr.set |= MMAL_DISPLAY_SET_LAYER;
    dr.layer = -128;
    //dr.layer = 0;
    //status = mmal_port_parameter_get(m_InputPort, &dr.hdr);
    // Not sure if that makes a difference, but tell the composer that his layer is
    // fully opaque such that it doesn't need to compose anything below it.
    dr.set |= MMAL_DISPLAY_SET_ALPHA;
    dr.alpha= 255;

    // In case the video doesn't exactly fill the screen (ratio mismatch)
    // Add black bars to the side or to the top
    dr.set |=  MMAL_DISPLAY_SET_MODE;
    dr.mode =  MMAL_DISPLAY_MODE_LETTERBOX;

    /*const int screen_width=2560;
    const int screen_height=1440;
    const int video_width=1920;
    const int video_height=1080;*/

    status = mmal_port_parameter_set(m_InputPort, &dr.hdr);
    if (status != MMAL_SUCCESS) {
        qDebug()<<"X mmal_port_parameter_set error"<<mmal_status_to_string(status);
        return;
    }else{
        qDebug()<<"X mmal set layer";
    }
    display_region_needs_update=false;
    qDebug()<<"updateDisplayRegion::end";
}

void RpiMMALDisplay::display_frame(AVFrame *frame)
{
    assert(frame);
    assert(frame->format==AV_PIX_FMT_MMAL);
    if(!has_been_initialized){
        init(frame->width,frame->height);
        has_been_initialized=true;
    }
    MMAL_BUFFER_HEADER_T* buffer = (MMAL_BUFFER_HEADER_T*)frame->data[3];
    display_mmal_frame(buffer);
}

void RpiMMALDisplay::display_mmal_frame(MMAL_BUFFER_HEADER_T *buffer)
{
    MMAL_STATUS_T status;

    // Update the destination display region in case the window moved
    updateDisplayRegion();

    status = mmal_port_send_buffer(m_InputPort, buffer);
    if (status != MMAL_SUCCESS) {
        qDebug()<<"mmal_port_send_buffer() failed: "<<mmal_status_to_string(status);
        // added for mmal decoder, not ffmpeg
         mmal_buffer_header_release(buffer);
    }
    else {
        // Prevent the buffer from being freed during av_frame_free()
        // until rendering is complete. The reference is dropped in
        // InputPortCallback().
        mmal_buffer_header_acquire(buffer);
    }
    //qDebug()<<"RpiMMALDisplay::display_mmal_frame";
}

void RpiMMALDisplay::extra_init(int width, int height)
{
    if(!has_been_initialized){
        init(width,height);
        has_been_initialized=true;
    }
}

void RpiMMALDisplay::InputPortCallback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    //qDebug()<<"RpiMMALDisplay::InputPortCallback";
    mmal_buffer_header_release(buffer);
}
