#include "rpimmaldecodedisplay.h"

#include "../../common/TimeHelper.hpp"

#include <qdebug.h>

// DIRTY BEGIN
MMAL_STATUS_T x_mmal_port_parameter_set_boolean(MMAL_PORT_T *port, uint32_t id, MMAL_BOOL_T value)
{
  MMAL_PARAMETER_BOOLEAN_T param = {{id, sizeof(param)}, value};
  return mmal_port_parameter_set(port, &param.hdr);
}
// DIRTY END


static void debug_mmal_format(MMAL_ES_FORMAT_T *format_out){
    qDebug(" type: %i, fourcc: %4.4s\n", format_out->type, (char *)&format_out->encoding);
    qDebug(" bitrate: %i, framed: %i\n", format_out->bitrate,
                      !!(format_out->flags & MMAL_ES_FORMAT_FLAG_FRAMED));
    qDebug(" extra data: %i, %p\n", format_out->extradata_size, format_out->extradata);
    const float fps=(float)format_out->es->video.frame_rate.num / (float)format_out->es->video.frame_rate.den;
    qDebug(" width: %i, height: %i, (%i,%i,%i,%i) fps:%f",
                      format_out->es->video.width, format_out->es->video.height,
                      format_out->es->video.crop.x, format_out->es->video.crop.y,
                      format_out->es->video.crop.width, format_out->es->video.crop.height,fps);
}

static bool initialized=false;

#define CHECK_STATUS(status, msg) if (status != MMAL_SUCCESS) { fprintf(stderr, msg"\n"); return false; }

// Callback from the decoder input port.
// Buffer has been consumed and is available to be used again.
static void input_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;

    //The decoder is done with the data, just recycle the buffer header into its pool
    mmal_buffer_header_release(buffer);
    //qDebug()<<"Buff available";

    // Kick the processing thread
    vcos_semaphore_post(&ctx->semaphore);
}

// Callback from the control port.
// Component is sending us an event.
static void control_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
   struct CONTEXT_T *ctx = (struct CONTEXT_T *)port->userdata;
   switch (buffer->cmd){
   case MMAL_EVENT_EOS:
      // Only sink component generate EOS events
      break;
   case MMAL_EVENT_ERROR:
      // Something went wrong. Signal this to the application
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


bool RPIMMalDecodeDisplay::initialize(const uint8_t *config_data, const int config_data_size, int width, int height, int fps)
{
    if(!initialized){
        initialized=true;
        bcm_host_init();
    }
	// used to init the semaphore initial count, should match n of allocated input buffers
    // 10 input buffers (~frames) should be plenty for all cases, fifo anyways
    static constexpr auto N_INPUT_BUFFERS=2;
    // also, 10 output buffers should be plenty, fifo anyways
    static constexpr auto N_OUTPUT_BUFFERS=5;

     vcos_semaphore_create(&m_context.semaphore, "example", N_INPUT_BUFFERS);

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

	// NOTE: fps seems to have no effect
    qDebug()<<"Configuring rpi mmal with "<<width<<"x"<<height<<"@"<<fps<<" config data size:"<<config_data_size;
    //
    // Set format of video decoder input port
    MMAL_ES_FORMAT_T* format_in = m_decoder->input[0]->format;
    format_in->type = MMAL_ES_TYPE_VIDEO;
    format_in->encoding = MMAL_ENCODING_H264;
    format_in->es->video.width = width;
    format_in->es->video.height = height;
    format_in->es->video.frame_rate.num = fps;
    format_in->es->video.frame_rate.den = 1;
    format_in->es->video.par.num = 1;
    format_in->es->video.par.den = 1;
    // We don't need this, since we set MMAL_BUFFER_HEADER_FLAG_FRAME_END for each frame
    // BUT - Do it anyways !!!
    // Weird - this flag seems to eliminte the "720p 60fps issue" even thugh I have no idea why.
    // Because in theory, we should not need it since we set MMAL_BUFFER_HEADER_FLAG_FRAME_END
    // If the data is known to be framed then the following flag should be set:
    format_in->flags |= MMAL_ES_FORMAT_FLAG_FRAMED;

    //SOURCE_READ_CODEC_CONFIG_DATA(codec_header_bytes, codec_header_bytes_size);
    m_status = mmal_format_extradata_alloc(format_in, config_data_size);
    CHECK_STATUS(m_status, "failed to allocate extradata");
    //format_in->extradata_size = codec_header_bytes_size;
    format_in->extradata_size = config_data_size;
    if (format_in->extradata_size){
        qDebug()<<"copying extradata";
        memcpy(format_in->extradata, config_data, format_in->extradata_size);
    }

    // No idea if needed or not, but do it anyways
    m_status = x_mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_VIDEO_INTERPOLATE_TIMESTAMPS, MMAL_FALSE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to disable timestamp interpolation on output port";
        return false;
    }

    /*
     * Zero copy is important on rpi / embedded devices. However, that's why we use the mmal graph stuff, it
     * should be zero copy directly to the HW composer.
     * Setting this manually seems to break things though.
     */
    /*m_status = x_mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set zero copy on output port";
        return false;
    }*/

    // Should be on by default, but just to make sure, set it anyways
    // Don't discard corrupt decoded frames, pass them on to the Arm side for rendering.
    m_status = x_mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_VIDEO_DECODE_ERROR_CONCEALMENT, MMAL_FALSE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set error concealment on output port";
        return false;
    }

    m_status = mmal_port_format_commit(m_decoder->input[0]);
    CHECK_STATUS(m_status, "failed to commit format");
    qDebug()<<"Input format:";
    debug_mmal_format(m_decoder->input[0]->format);

    m_status = mmal_port_format_commit(m_decoder->output[0]);
    CHECK_STATUS(m_status, "failed to commit format");
    qDebug()<<"Output format:";
    debug_mmal_format(m_decoder->output[0]->format);

    qDebug()<<"Decoder input buffer_num_min"<<m_decoder->input[0]->buffer_num_min;
    //m_decoder->input[0]->buffer_num = m_decoder->input[0]->buffer_num_min;
    m_decoder->input[0]->buffer_num = N_INPUT_BUFFERS;

    //m_decoder->input[0]->buffer_size = m_decoder->input[0]->buffer_size_min+1024;
    // 1MByte is completely overkill, that would be 480 Mbit/s at 60fps ;)
    m_decoder->input[0]->buffer_size = 1024*1024;

    qDebug()<<"Decoder output buffer_num_min"<<m_decoder->output[0]->buffer_num_min;
    //m_decoder->output[0]->buffer_num = m_decoder->output[0]->buffer_num_min;
    m_decoder->output[0]->buffer_num = N_OUTPUT_BUFFERS;
    m_decoder->output[0]->buffer_size = m_decoder->output[0]->buffer_size_min;


    /*m_status = x_mmal_port_parameter_set_boolean(m_decoder->output[0], MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE);
    if (m_status != MMAL_SUCCESS) {
        qDebug() << "Failed to set zero copy on output port";
    }else{
        qDebug()<<" set zero copy on output";
    }*/

    m_pool_in = mmal_pool_create(m_decoder->input[0]->buffer_num,m_decoder->input[0]->buffer_size);

    qDebug()<<"Done creating m_pool_in";

    m_context.queue = mmal_queue_create();

    // Store a reference to our context in each port (will be used during callbacks)
    m_decoder->input[0]->userdata = (struct MMAL_PORT_USERDATA_T*)(void *)&m_context;

    m_status = mmal_port_enable(m_decoder->input[0], input_callback);
    CHECK_STATUS(m_status, "failed to enable input port")

    // connect them up - this propagates port settings from outputs to inputs
    m_status = mmal_graph_new_connection(m_graph, m_decoder->output[0], m_renderer->input[0],  0, NULL);
    CHECK_STATUS(m_status, "failed to connect decoder to renderer");

    qDebug()<<"done mmal_graph_new_connection";

    m_status = mmal_graph_enable(m_graph, NULL, NULL);
    CHECK_STATUS(m_status, "failed to enable graph");

    qDebug()<<"RPIMMalDecodeDisplay::initialize::done";
    updateDisplayRegion();
    return true;
}


bool RPIMMalDecodeDisplay::feed_frame(const uint8_t *frame_data, const int frame_data_size,std::optional<std::chrono::milliseconds> opt_upper_wait_limit)
{
    //qDebug()<<"RPIMMALDecoder::feed_frame";
    //if(true)return;

    const auto begin=std::chrono::steady_clock::now();
    MMAL_BUFFER_HEADER_T *buffer=nullptr;

    while (true) {
        if(opt_upper_wait_limit){
            const auto elapsed=std::chrono::steady_clock::now()-begin;
            if(elapsed>=opt_upper_wait_limit.value()){
                const auto queue_len=mmal_queue_length(m_pool_in->queue);
                qDebug()<<"No frame after "<<MyTimeHelper::R(std::chrono::steady_clock::now()-begin).c_str()<<" queue length:"<<queue_len;
                return false;
            }
        }

        // We first try and get a frame from the input pool without waiting on the semaphore -
        // Quite likely there is one available immediately
        buffer = mmal_queue_get(m_pool_in->queue);

        if (buffer != nullptr) {
            // We got a buffer, copy data into it and feed it to the decoder
            //qDebug()<<"RPIMMALDecoder::feed_frame:got buffer,send";
            int n_bytes_to_copy=frame_data_size;
            // Since I do not know how to put this buffer back into the queue, I decided to just copy
            // as much as possible and then feed the frame to the decoder in case we exceed the allocated buffer size.
            // Note that we allocate input buffers of size 1024*124 bytes, which should be enough for "everything".
            if(frame_data_size>buffer->alloc_size){
                qDebug()<<"RPIMMalDecodeDisplay::feed_frame MMAL buffer not big enough for frame (weird), dropping";
                n_bytes_to_copy=buffer->alloc_size;
            }

            memcpy(buffer->data,frame_data, n_bytes_to_copy);
            buffer->length = frame_data_size;

            buffer->offset = 0;
            // Don't forget this flag, without it the decoder will parse this data again
            // and create at least one additional frame of latency
            buffer->flags |= MMAL_BUFFER_HEADER_FLAG_FRAME_END;

            buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;
            // used to measure decode latency
            //buffer->pts = getTimeUs();

            m_status = mmal_port_send_buffer(m_decoder->input[0], buffer);
            if (m_status != MMAL_SUCCESS) {
                qDebug()<<"Cannot feed frame ?!";
                return false;
                break;
            }
            break;
        }
        // If we didn't get a buffer the first time, we wait on the semaphore kicked off by the callback that is called
        // when there is a new buffer available
        if(opt_upper_wait_limit){
             const uint32_t wait_ms=5; // We keep the thread busy a bit by purpose
             vcos_semaphore_wait_timeout(&m_context.semaphore,wait_ms);
        }else{
            vcos_semaphore_wait(&m_context.semaphore);
        }
    }
    return true;
}

void RPIMMalDecodeDisplay::cleanup()
{
    qDebug()<<"RPIMMalDecodeDisplay::cleanup() begin";
    if(!m_graph){
        qDebug()<<"RPIMMalDecodeDisplay::cleanup() no graph";
        return;
    }
    // Stop everything. Not strictly necessary since mmal_component_destroy()
    //will do that anyway
    mmal_port_disable(m_decoder->input[0]);
    mmal_port_disable(m_decoder->control);

    // Stop everything
    fprintf(stderr, "stop");
    mmal_graph_disable(m_graph);
    // Cleanup everything
    if (m_decoder){
        mmal_component_release(m_decoder);
    }
    if (m_renderer){
        mmal_component_release(m_renderer);
    }
    if (m_graph){
        mmal_graph_destroy(m_graph);
    }
    qDebug()<<"RPIMMalDecodeDisplay::cleanup() end";
}

void RPIMMalDecodeDisplay::updateDisplayRegion()
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

    const auto rotation=QOpenHDVideoHelper::get_display_rotation();
    if(rotation==90){
        dr.set |=MMAL_DISPLAY_SET_TRANSFORM;
        dr.transform =MMAL_DISPLAY_ROT90;
    }

    /*const int screen_width=2560;
    const int screen_height=1440;
    const int video_width=1920;
    const int video_height=1080;*/

    status = mmal_port_parameter_set(m_renderer->input[0], &dr.hdr);
    if (status != MMAL_SUCCESS) {
        qDebug()<<"X mmal_port_parameter_set error";
        return;
    }else{
        qDebug()<<"X mmal set layer";
    }
    display_region_needs_update=false;
    qDebug()<<"updateDisplayRegion::end";
}
