#include "rpimmaldecodedisplay.h"

#include <qdebug.h>


static bool initialized=false;

#define CHECK_STATUS(status, msg) if (status != MMAL_SUCCESS) { fprintf(stderr, msg"\n"); return; }

/** Callback from the decoder input port.
 * Buffer has been consumed and is available to be used again. */
static void input_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

    /* The decoder is done with the data, just recycle the buffer header into its pool */
    mmal_buffer_header_release(buffer);

    /* Kick the processing thread */
    vcos_semaphore_post(&ctx->semaphore);

    //fprintf(stderr,"decoder input callback\n");
}

/** Callback from the control port.
 * Component is sending us an event. */
static void control_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
   struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

   switch (buffer->cmd)
   {
   case MMAL_EVENT_EOS:
      /* Only sink component generate EOS events */
      break;
   case MMAL_EVENT_ERROR:
      /* Something went wrong. Signal this to the application */
      ctx->status = *(MMAL_STATUS_T *)buffer->data;
      break;
   default:
      break;
   }

   /* Done with the event, recycle it */
   mmal_buffer_header_release(buffer);

   qDebug("control cb. status %u\n", ctx->status);
}


RPIMMalDecodeDisplay::RPIMMalDecodeDisplay()
{

}


RPIMMalDecodeDisplay &RPIMMalDecodeDisplay::instance()
{

    static RPIMMalDecodeDisplay instance{};
    return instance;
}



void RPIMMalDecodeDisplay::initialize(const uint8_t *config_data, const int config_data_size, int width, int height, int fps)
{
    if(!initialized){
        initialized=true;
        bcm_host_init();
    }
     vcos_semaphore_create(&m_context.semaphore, "example", 1);

     MMAL_STATUS_T status;

     /* Create the graph */
    //status = mmal_graph_create(&m_graph, 0);
    //CHECK_STATUS(status, "failed to create graph");

    status = mmal_graph_new_component(graph, MMAL_COMPONENT_DEFAULT_VIDEO_DECODER, &m_decoder);
    CHECK_STATUS(status, "failed to create decoder");

    status = mmal_graph_new_component(graph, MMAL_COMPONENT_DEFAULT_VIDEO_RENDERER, &m_renderer);
    CHECK_STATUS(status, "failed to create renderer");


    /* Enable control port so we can receive events from the component */
    m_decoder->control->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&m_context;
    status = mmal_port_enable(m_decoder->control, control_callback);
    CHECK_STATUS(status, "failed to enable control port");

}



void RPIMMalDecodeDisplay::feed_frame(const uint8_t *frame_data, const int frame_data_size)
{

}
