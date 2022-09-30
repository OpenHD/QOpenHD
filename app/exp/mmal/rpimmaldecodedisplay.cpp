#include "rpimmaldecodedisplay.h"

#include "../../common_consti/TimeHelper.hpp"

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

     /* Create the graph */
    m_status = mmal_graph_create(&m_graph, 0);
    CHECK_STATUS(m_status, "failed to create graph");

    m_status = mmal_graph_new_component(m_graph, MMAL_COMPONENT_DEFAULT_VIDEO_DECODER, &m_decoder);
    CHECK_STATUS(m_status, "failed to create decoder");

    m_status = mmal_graph_new_component(m_graph, MMAL_COMPONENT_DEFAULT_VIDEO_RENDERER, &m_renderer);
    CHECK_STATUS(m_status, "failed to create renderer");


    /* Enable control port so we can receive events from the component */
    m_decoder->control->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&m_context;
    m_status = mmal_port_enable(m_decoder->control, control_callback);
    CHECK_STATUS(m_status, "failed to enable control port");

    //
    // Set format of video decoder input port
    format_in = m_decoder->input[0]->format;
    format_in->type = MMAL_ES_TYPE_VIDEO;
    format_in->encoding = MMAL_ENCODING_H264;
    format_in->es->video.width = width;
    format_in->es->video.height = height;
    format_in->es->video.frame_rate.num = 25;
    format_in->es->video.frame_rate.den = 1;
    format_in->es->video.par.num = 1;
    format_in->es->video.par.den = 1;
    /* If the data is known to be framed then the following flag should be set:*/
     //format_in->flags |= MMAL_ES_FORMAT_FLAG_FRAMED;



    //SOURCE_READ_CODEC_CONFIG_DATA(codec_header_bytes, codec_header_bytes_size);
    //m_status = mmal_format_extradata_alloc(format_in, codec_header_bytes_size);
    m_status = mmal_format_extradata_alloc(format_in, config_data_size);
    CHECK_STATUS(m_status, "failed to allocate extradata");
    //format_in->extradata_size = codec_header_bytes_size;
    format_in->extradata_size = config_data_size;
    if (format_in->extradata_size){
        memcpy(format_in->extradata, config_data, format_in->extradata_size);
    }

    m_status = mmal_port_format_commit(m_decoder->input[0]);
    CHECK_STATUS(m_status, "failed to commit format");

    m_status = mmal_port_format_commit(m_decoder->output[0]);
    CHECK_STATUS(m_status, "failed to commit format");

    m_decoder->input[0]->buffer_num = m_decoder->input[0]->buffer_num_min;
    m_decoder->input[0]->buffer_size = m_decoder->input[0]->buffer_size_min;

    m_decoder->output[0]->buffer_num = m_decoder->output[0]->buffer_num_min;
    m_decoder->output[0]->buffer_size = m_decoder->output[0]->buffer_size_min;

    m_pool_in = mmal_pool_create(m_decoder->input[0]->buffer_num,m_decoder->input[0]->buffer_size);

    /*context.queue = mmal_queue_create();

    // Store a reference to our context in each port (will be used during callbacks)
    decoder->input[0]->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&context;

    status = mmal_port_enable(decoder->input[0], input_callback);
    CHECK_STATUS(status, "failed to enable input port")


    // connect them up - this propagates port settings from outputs to inputs
    status = mmal_graph_new_connection(graph, decoder->output[0], renderer->input[0],  0, NULL);
    CHECK_STATUS(status, "failed to connect decoder to renderer");


     // Start playback
    fprintf(stderr, "start");
    m_status = mmal_graph_enable(m_graph, NULL, NULL);
    CHECK_STATUS(status, "failed to enable graph");*/


}


void RPIMMalDecodeDisplay::feed_frame(const uint8_t *frame_data, const int frame_data_size)
{
    qDebug()<<"RPIMMALDecoder::feed_frame";

    MMAL_BUFFER_HEADER_T *buffer;

    while (true) {
        vcos_semaphore_wait(&m_context.semaphore);

        if ((buffer = mmal_queue_get(m_pool_in->queue)) != nullptr) {

            qDebug()<<"RPIMMALDecoder::feed_frame:got buffer,send";

            memcpy(buffer->data,frame_data, frame_data_size);
            buffer->length = frame_data_size;

            buffer->offset = 0;

            buffer->flags |= MMAL_BUFFER_HEADER_FLAG_FRAME_END;

            buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;
            // used to measure decode latency
            buffer->pts = getTimeUs();

            m_status = mmal_port_send_buffer(m_decoder->input[0], buffer);
            if (m_status != MMAL_SUCCESS) {
                qDebug()<<"Cannot feed frame ?!";
                break;
            }
            break;
        }
    }
}
