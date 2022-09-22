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
        // We set the GPU memory, so we have space, mre buffers here don#t hurt and can provide a benefit
        // for some streams
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
   {
           /*MMAL_DISPLAYREGION_T dr = {};

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
           }*/
           // EXP set layer begin

            MMAL_DISPLAYREGION_T dr = {};
            dr.set |= MMAL_DISPLAY_SET_LAYER;
            //dr.layer = -128;
            dr.layer = 0;

            status = mmal_port_parameter_set(m_InputPort, &dr.hdr);
            if (status != MMAL_SUCCESS) {
                qDebug()<<"X mmal_port_parameter_set error"<<mmal_status_to_string(status);
                return;
            }else{
                qDebug()<<"X mmal set layer";
            }



           updateDisplayRegion();
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
    /*MMAL_STATUS_T status;
        int currentPosX, currentPosY;
        MMAL_DISPLAYREGION_T dr;

        dr.hdr.id = MMAL_PARAMETER_DISPLAYREGION;
        dr.hdr.size = sizeof(MMAL_DISPLAYREGION_T);
        dr.set = MMAL_DISPLAY_SET_DEST_RECT;

        SDL_GetWindowPosition(m_Window, &currentPosX, &currentPosY);

        if ((SDL_GetWindowFlags(m_Window) & SDL_WINDOW_INPUT_FOCUS) == 0) {
            dr.dest_rect.x = 0;
            dr.dest_rect.y = 0;
            dr.dest_rect.width = 0;
            dr.dest_rect.height = 0;

            // Force a re-evaluation next time
            m_LastWindowPosX = -1;
            m_LastWindowPosY = -1;
        }
        else if (m_LastWindowPosX != currentPosX || m_LastWindowPosY != currentPosY) {
            SDL_Rect src, dst;
            src.x = src.y = 0;
            src.w = m_VideoWidth;
            src.h = m_VideoHeight;
            dst.x = dst.y = 0;
            SDL_GetWindowSize(m_Window, &dst.w, &dst.h);

            StreamUtils::scaleSourceToDestinationSurface(&src, &dst);

            dr.dest_rect.x = currentPosX + dst.x;
            dr.dest_rect.y = currentPosY + dst.y;
            dr.dest_rect.width = dst.w;
            dr.dest_rect.height = dst.h;

            m_LastWindowPosX = currentPosX;
            m_LastWindowPosY = currentPosY;
        }
        else {
            // Nothing to do
            return;
        }

        status = mmal_port_parameter_set(m_InputPort, &dr.hdr);
        if (status != MMAL_SUCCESS) {
            SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
                        "mmal_port_parameter_set() failed: %x (%s)",
                        status, mmal_status_to_string(status));
        }*/
}

void RpiMMALDisplay::display_frame(AVFrame *frame)
{
    assert(frame->format==AV_PIX_FMT_MMAL);
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
    }
    else {
        // Prevent the buffer from being freed during av_frame_free()
        // until rendering is complete. The reference is dropped in
        // InputPortCallback().
        mmal_buffer_header_acquire(buffer);
    }
    qDebug()<<"RpiMMALDisplay::display_mmal_frame";
}

void RpiMMALDisplay::InputPortCallback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    qDebug()<<"RpiMMALDisplay::InputPortCallback";
    mmal_buffer_header_release(buffer);
}
