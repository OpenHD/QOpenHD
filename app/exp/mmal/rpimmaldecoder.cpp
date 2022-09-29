#include "rpimmaldecoder.h"

#include "rpimmaldisplay.h"

#include <qdebug.h>


static bool initialized_mmal=false;

/*
 * Callback from the input port.
 * Buffer has been consumed and is available to be used again.
 */
static void input_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
   struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

   /* The decoder is done with the data, just recycle the buffer header into its pool */
   mmal_buffer_header_release(buffer);

   /* Signal the prcocessFrame function */
   vcos_semaphore_post(&ctx->in_semaphore);
}

/*
 * Callback from the output port.
 * Buffer has been produced by the port and is available for processing.
 */
static void output_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
   struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

   /* Queue the decoded video frame so renderLoop can get it */
   mmal_queue_put(ctx->queue, buffer);

   /* Signal the renderLoop */
   vcos_semaphore_post(&ctx->out_semaphore);
}

RPIMMALDecoder::RPIMMALDecoder()
{

}

RPIMMALDecoder &RPIMMALDecoder::instance()
{

    static RPIMMALDecoder instance;
    return instance;
}

void RPIMMALDecoder::initialize(const uint8_t *config_data, const int config_data_size,int width,int height,int fps)
{
    qDebug()<<"RPIMMALDecoder::initialize";
    if (!initialized_mmal) {
        initialized_mmal = true;
        bcm_host_init();
    }

    /*
     * Used to signal the input function and the output loop that a buffer is ready,
     * which prevents us from having to loop and burn CPU time, and also ensures that
     * there is no delay before using the available buffer.
     */
    vcos_semaphore_create(&m_context.in_semaphore, "qopenhd_in", 1);
    vcos_semaphore_create(&m_context.out_semaphore, "qopenhd_out", 1);

    m_status = mmal_component_create(MMAL_COMPONENT_DEFAULT_VIDEO_DECODER, &m_decoder);

    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to create MMAL decoder";
        return;
    }

    /*
     * Set format of video decoder input port
     */
    MMAL_ES_FORMAT_T *format_in = m_decoder->input[0]->format;

    format_in->type = MMAL_ES_TYPE_VIDEO;
    format_in->encoding = MMAL_ENCODING_H264;
    format_in->es->video.width = VCOS_ALIGN_UP(width, 32);
    format_in->es->video.height = VCOS_ALIGN_UP(height, 16);
    format_in->es->video.frame_rate.num = fps;
    format_in->es->video.frame_rate.den = 1;
    format_in->es->video.par.num = 1;
    format_in->es->video.par.den = 1;
    /*
     * If the data is known to be framed then the following flag should be set:
     */
    format_in->flags |= MMAL_ES_FORMAT_FLAG_FRAMED;

    m_status = mmal_format_extradata_alloc(format_in, config_data_size);

    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to allocate extradata in MMAL";
        return;
    }
    format_in->extradata_size = config_data_size;
    memcpy(format_in->extradata,config_data, config_data_size);

    /*
     * Set zero copy on the input port, which uses VCSM to map the buffers into arm memory address space,
     * allowing us to avoid copying the buffer back to the GPU side once we fill it with h264 data. There
     * isn't much overhead either way since the amount of data is small, but we can do it so we will.
     */
    m_status = mmal_port_parameter_set_boolean(m_decoder->input[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set zero copy on input port";
        return;
    }
    m_status = mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set zero copy on output port";
        return;
    }

    m_status = mmal_port_format_commit(m_decoder->input[0]);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to commit input format";
        return;
    }


    /*
     * Don't infer timestamps from the framerate
     */
    m_status = mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_VIDEO_INTERPOLATE_TIMESTAMPS, MMAL_FALSE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to disable timestamp interpolation on output port";
        return;
    }

    /*
     * Set zero copy on the output port, which uses VCSM to map the decoded frame buffers into arm memory
     * address space, allowing us to avoid copying large amounts of data from GPU->Arm for every single
     * decoded frame.
     *
     * The overhead of the copying would be significant enough to affect framerate. Testing suggests it
     * becomes a factor around the 60fps+ rate, but even if we could technically get away with it, it
     * would waste resources.
     */
    m_status = mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set zero copy on output port";
        return;
    }

    /*
     * Don't discard corrupt decoded frames, pass them on to the Arm side for rendering.
     */
    m_status = mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_VIDEO_DECODE_ERROR_CONCEALMENT, MMAL_FALSE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set error concealment on output port";
        return;
    }

    m_status = mmal_port_format_commit(m_decoder->output[0]);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to commit output format";
        return;
    }



    MMAL_ES_FORMAT_T *format_out = m_decoder->output[0]->format;

    qDebug("%s\n", m_decoder->output[0]->name);
    qDebug(" type: %i, fourcc: %4.4s\n", format_out->type, (char *)&format_out->encoding);
    qDebug(" bitrate: %i, framed: %i\n", format_out->bitrate,
                      !!(format_out->flags & MMAL_ES_FORMAT_FLAG_FRAMED));
    qDebug(" extra data: %i, %p\n", format_out->extradata_size, format_out->extradata);
    qDebug(" width: %i, height: %i, (%i,%i,%i,%i)\n",
                      format_out->es->video.width, format_out->es->video.height,
                      format_out->es->video.crop.x, format_out->es->video.crop.y,
                      format_out->es->video.crop.width, format_out->es->video.crop.height);

    /*
     * Size of the input buffers used for h264 data. These only need to be large enough for the
     * largest NAL unit we will likely feed to the decoder, 512KB seems ok in testing but may
     * need to be a bit larger for higher bitrates.
     */
    m_decoder->input[0]->buffer_num = 15;
    m_decoder->input[0]->buffer_size = 768 * 1024;
    m_pool_in = mmal_port_pool_create(m_decoder->input[0],
                                       m_decoder->input[0]->buffer_num,
                                       m_decoder->input[0]->buffer_size);

    if (!m_pool_in) {
        qDebug() << "failed to create input pool in MMAL";
        return;
    }

    /*
     * Decoded frame buffers, these have to be large enough to hold an entire raw frame. The h264 decoder
     * can't decode anything much larger than 1080p, but a single 1080p YUV420 frame is about 3.2MB
     * so we add some extra margin on top of that.
     */
    m_decoder->output[0]->buffer_num = 5;
    m_decoder->output[0]->buffer_size = 3500000;
    m_pool_out = mmal_port_pool_create(m_decoder->output[0],
                                       m_decoder->output[0]->buffer_num,
                                       m_decoder->output[0]->buffer_size);

    if (!m_pool_out) {
        qDebug() << "failed to create input pool in MMAL";
        return;
    }

    m_context.queue = mmal_queue_create();

    /*
     * Provide a context pointer that will be passed back to us in the input and output callbacks
     */
    m_decoder->input[0]->userdata = (MMAL_PORT_USERDATA_T *)&m_context;
    m_decoder->output[0]->userdata = (MMAL_PORT_USERDATA_T *)&m_context;


    m_status = mmal_port_enable(m_decoder->input[0], input_callback);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to set input callback in MMAL";
        return;
    }
    m_status = mmal_port_enable(m_decoder->output[0], output_callback);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to set output callback in MMAL";
        return;
    }

    m_status = mmal_component_enable(m_decoder);

    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to enable decoder in MMAL";
        return;
    }
    qDebug()<<"RPIMMALDecoder init done successfully()";
}

void RPIMMALDecoder::feed_frame(const uint8_t *frame_data, const int frame_data_size)
{
    qDebug()<<"RPIMMALDecoder::feed_frame";

    MMAL_BUFFER_HEADER_T *buffer;

    while (true) {
        vcos_semaphore_wait(&m_context.in_semaphore);

        if ((buffer = mmal_queue_get(m_pool_in->queue)) != nullptr) {

            memcpy(buffer->data,frame_data, frame_data_size);
            buffer->length = frame_data_size;

            buffer->offset = 0;

            buffer->flags |= MMAL_BUFFER_HEADER_FLAG_FRAME_END;

            buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;


            m_status = mmal_port_send_buffer(m_decoder->input[0], buffer);
            if (m_status != MMAL_SUCCESS) {
                qDebug()<<"Cannot feed frame ?!";
                break;
            }
            break;
        }
    }
}


void RPIMMALDecoder::on_new_frame(MMAL_BUFFER_HEADER_T *buffer)
{
    qDebug()<<"RPIMMALDecoder::on_new_frame";
    RpiMMALDisplay::instance().display_mmal_frame(buffer);
}


void RPIMMALDecoder::output_frame_loop()
{
    MMAL_BUFFER_HEADER_T *buffer;
    MMAL_STATUS_T status = MMAL_EINVAL;

    while (true) {
        vcos_semaphore_wait(&m_context.out_semaphore);


        /* Get decoded frame */
        while ((buffer = mmal_queue_get(m_context.queue)) != NULL) {
            if (buffer->cmd) {

                if (buffer->cmd == MMAL_EVENT_FORMAT_CHANGED) {
                    qDebug()<<"Got MMAL_EVENT_FORMAT_CHANGED";
                }
                mmal_buffer_header_release(buffer);
            } else {
                // buffer is released by the renderer when it finishes with the frame
                on_new_frame(buffer);
            }
        }

        /* Send empty buffers to the output port of the decoder */
        while ((buffer = mmal_queue_get(m_pool_out->queue)) != nullptr) {
            m_status = mmal_port_send_buffer(m_decoder->output[0], buffer);
            if (m_status != MMAL_SUCCESS) {
                //qDebug() << "failed to send output buffer";
            }
        }
    }
}
