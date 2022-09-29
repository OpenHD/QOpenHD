#include "rpimmaldecoder.h"



RPIMMALDecoder::RPIMMALDecoder()
{

}

void RPIMMALDecoder::initialize(const uint8_t *config_data, const int config_data_size,int width,int height,int fps)
{
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
}



void RPIMMALDecoder::on_new_frame(MMAL_BUFFER_HEADER_T *buffer)
{

}
