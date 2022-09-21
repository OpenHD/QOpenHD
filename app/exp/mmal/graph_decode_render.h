#include "bcm_host.h"
#include <interface/mmal/mmal.h>
#include <interface/mmal/util/mmal_connection.h>
#include <interface/mmal/util/mmal_graph.h>
#include <interface/mmal/util/mmal_util.h>
#include <interface/mmal/util/mmal_default_components.h>
#include <interface/mmal/util/mmal_util_params.h>
#include <stdio.h>
#include "interface/vcos/vcos.h"



#define CHECK_STATUS(status, msg) if (status != MMAL_SUCCESS) { fprintf(stderr, msg"\n"); goto error; }


static uint8_t codec_header_bytes[128];
static unsigned int codec_header_bytes_size = sizeof(codec_header_bytes);

static FILE *source_file;

/* Macros abstracting the I/O, just to make the example code clearer */
#define SOURCE_OPEN(uri) \
    source_file = fopen(uri, "rb"); if (!source_file) goto error;
#define SOURCE_READ_CODEC_CONFIG_DATA(bytes, size) \
    size = fread(bytes, 1, size, source_file); rewind(source_file)
#define SOURCE_READ_DATA_INTO_BUFFER(a) \
    a->length = fread(a->data, 1, a->alloc_size - 128, source_file); \
    a->offset = 0; a->pts = a->dts = MMAL_TIME_UNKNOWN
#define SOURCE_CLOSE() \
    if (source_file) fclose(source_file)

/** Context for our application */
static struct CONTEXT_T {
    VCOS_SEMAPHORE_T semaphore;
    MMAL_QUEUE_T *queue;
    MMAL_STATUS_T status;
} context;

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

   fprintf(stderr,"control cb. status %u\n", ctx->status);
}

static void x_run() {

    MMAL_STATUS_T status;
    MMAL_GRAPH_T *graph = 0;
    MMAL_COMPONENT_T *decoder = 0, *renderer=0;
    MMAL_POOL_T *pool_in = 0;
    MMAL_ES_FORMAT_T * format_in=0;
    MMAL_PARAMETER_BOOLEAN_T zc;
    MMAL_BOOL_T eos_sent = MMAL_FALSE;


    bcm_host_init();
    vcos_semaphore_create(&context.semaphore, "example", 1);

    SOURCE_OPEN("test.h264_2")


    /* Create the graph */
    status = mmal_graph_create(&graph, 0);
    CHECK_STATUS(status, "failed to create graph");

    status = mmal_graph_new_component(graph, MMAL_COMPONENT_DEFAULT_VIDEO_DECODER, &decoder);
    CHECK_STATUS(status, "failed to create decoder");

    status = mmal_graph_new_component(graph, MMAL_COMPONENT_DEFAULT_VIDEO_RENDERER, &renderer);
    CHECK_STATUS(status, "failed to create renderer");



    /* Enable control port so we can receive events from the component */
    decoder->control->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&context;
    status = mmal_port_enable(decoder->control, control_callback);
    CHECK_STATUS(status, "failed to enable control port");


    /* Set the zero-copy parameter on the input port */
  /* zc = {{MMAL_PARAMETER_ZERO_COPY, sizeof(zc)}, MMAL_TRUE};
    status = mmal_port_parameter_set(decoder->input[0], &zc.hdr);
    fprintf(stderr, "status: %i\n", status);*/

    /* Set the zero-copy parameter on the output port */
    /*status = mmal_port_parameter_set_boolean(decoder->output[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    fprintf(stderr, "status: %i\n", status);*/


    /* Set format of video decoder input port */
    format_in = decoder->input[0]->format;
    format_in->type = MMAL_ES_TYPE_VIDEO;
    format_in->encoding = MMAL_ENCODING_H264;
    format_in->es->video.width = 1280;
    format_in->es->video.height = 720;
    format_in->es->video.frame_rate.num = 25;
    format_in->es->video.frame_rate.den = 1;
    format_in->es->video.par.num = 1;
    format_in->es->video.par.den = 1;
    /* If the data is known to be framed then the following flag should be set:*/
     //format_in->flags |= MMAL_ES_FORMAT_FLAG_FRAMED;



    SOURCE_READ_CODEC_CONFIG_DATA(codec_header_bytes, codec_header_bytes_size);
    status = mmal_format_extradata_alloc(format_in, codec_header_bytes_size);
    CHECK_STATUS(status, "failed to allocate extradata");
    format_in->extradata_size = codec_header_bytes_size;
    if (format_in->extradata_size)
      memcpy(format_in->extradata, codec_header_bytes, format_in->extradata_size);


    status = mmal_port_format_commit(decoder->input[0]);
    CHECK_STATUS(status, "failed to commit format");


    status = mmal_port_format_commit(decoder->output[0]);
    CHECK_STATUS(status, "failed to commit format");

    decoder->input[0]->buffer_num = decoder->input[0]->buffer_num_min;
    decoder->input[0]->buffer_size = decoder->input[0]->buffer_size_min;

    decoder->output[0]->buffer_num = decoder->output[0]->buffer_num_min;
    decoder->output[0]->buffer_size = decoder->output[0]->buffer_size_min;

    pool_in = mmal_pool_create(decoder->input[0]->buffer_num,decoder->input[0]->buffer_size);

    context.queue = mmal_queue_create();

    /* Store a reference to our context in each port (will be used during callbacks) */
    decoder->input[0]->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&context;

    status = mmal_port_enable(decoder->input[0], input_callback);
    CHECK_STATUS(status, "failed to enable input port")


    /* connect them up - this propagates port settings from outputs to inputs */
    status = mmal_graph_new_connection(graph, decoder->output[0], renderer->input[0],  0, NULL);
    CHECK_STATUS(status, "failed to connect decoder to renderer");


     /* Start playback */
    fprintf(stderr, "start");
    status = mmal_graph_enable(graph, NULL, NULL);
    CHECK_STATUS(status, "failed to enable graph");

    while(eos_sent == MMAL_FALSE)
    {
        MMAL_BUFFER_HEADER_T *buffer;

        /* Wait for buffer headers to be available on either the decoder input or the encoder output port */
        vcos_semaphore_wait(&context.semaphore);

        /* Send data to decode to the input port of the video decoder */
        if ((buffer = mmal_queue_get(pool_in->queue)) != NULL)
        {
            SOURCE_READ_DATA_INTO_BUFFER(buffer);
            if(!buffer->length) eos_sent = MMAL_TRUE;

             buffer->flags = buffer->length ? 0 : MMAL_BUFFER_HEADER_FLAG_EOS;
             buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;
             //fprintf(stderr, "sending %i bytes\n", (int)buffer->length);
             status = mmal_port_send_buffer(decoder->input[0], buffer);
            CHECK_STATUS(status, "failed to send buffer");
        }
    }

    /* Stop decoding */
    fprintf(stderr, "stop decoding\n");

    /* Stop everything. Not strictly necessary since mmal_component_destroy()
       * will do that anyway */
    mmal_port_disable(decoder->input[0]);
    mmal_port_disable(decoder->control);

    /* Stop everything */
    fprintf(stderr, "stop");
    mmal_graph_disable(graph);

error:
    /* Cleanup everything */
    if (decoder)
        mmal_component_release(decoder);
    if (renderer)
        mmal_component_release(renderer);
    if (graph)
        mmal_graph_destroy(graph);

    return status == MMAL_SUCCESS ? 0 : -1;

}
