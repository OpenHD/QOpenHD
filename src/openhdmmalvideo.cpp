#if defined(ENABLE_VIDEO_RENDER)
#if defined(__rasp_pi__)

#include <QtConcurrent>
#include <QtQuick>
#include <QThread>
#include <QtConcurrent>
#include <QFuture>

#include "openhdmmalvideo.h"
#include "openhdrender.h"
#include "constants.h"
#include "localmessage.h"

#include "sharedqueue.h"

#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/mmal_parameters_video.h"
#include "interface/mmal/util/mmal_util.h"
#include "interface/mmal/util/mmal_util_params.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/vcos/vcos.h"

using namespace std::chrono;


static bool initialized_mmal = false;

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


OpenHDMMALVideo::OpenHDMMALVideo(enum OpenHDStreamType stream_type): OpenHDVideo(stream_type) {
    qDebug() << "OpenHDMMALVideo::OpenHDMMALVideo()";
    connect(this, &OpenHDMMALVideo::configure, this, &OpenHDMMALVideo::mmalConfigure, Qt::DirectConnection);
}


OpenHDMMALVideo::~OpenHDMMALVideo() {
    qDebug() << "~OpenHDMMALVideo()";
}


void OpenHDMMALVideo::start() {
    // nothing needed
}


void OpenHDMMALVideo::stop() {
    if (m_decoder) {
       mmal_port_disable(m_decoder->input[0]);
       mmal_port_disable(m_decoder->output[0]);
       mmal_component_disable(m_decoder);
   }

   if (m_pool_in) {
       mmal_port_pool_destroy(m_decoder->input[0], m_pool_in);
   }

   if (m_pool_out) {
       mmal_port_pool_destroy(m_decoder->output[0], m_pool_out);
   }

   if (m_decoder) {
       mmal_component_destroy(m_decoder);
   }

   if (m_context.queue) {
       mmal_queue_destroy(m_context.queue);
   }

   vcos_semaphore_delete(&m_context.in_semaphore);
   vcos_semaphore_delete(&m_context.out_semaphore);
}


OpenHDRender* OpenHDMMALVideo::videoOut() const {
    return m_videoOut;
}


void OpenHDMMALVideo::setVideoOut(OpenHDRender *videoOut) {
    qDebug() << "OpenHDMMALVideo::setVideoOut(" << videoOut << ")";

    if (m_videoOut == videoOut) {
        return;
    }

    if (m_videoOut) {
        m_videoOut->disconnect(this);
    }

    m_videoOut = videoOut;

    emit videoOutChanged();
}


void OpenHDMMALVideo::mmalConfigure() {
    if (!initialized_mmal) {
        initialized_mmal = true;
        bcm_host_init();
    }

    auto t = QThread::currentThread();

    qDebug() << "OpenHDMMALVideo::mmalConfigure()";
    qDebug() << t;

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

    m_status = mmal_format_extradata_alloc(format_in, sps_len + pps_len);

    if (m_status != MMAL_SUCCESS) {
        qDebug() << "failed to allocate extradata in MMAL";
        return;
    }
    format_in->extradata_size = sps_len + pps_len;
    memcpy(format_in->extradata, sps, sps_len);
    memcpy(format_in->extradata + sps_len, pps, pps_len);


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
    m_decoder->output[0]->buffer_num = 15;
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

    isConfigured = true;

    QThread::msleep(100);



    // the pi decoder hardware always gives us this format, so we hardcode it
    m_videoOut->setFormat(width, height, QVideoFrame::PixelFormat::Format_YUV420P);

    /*
     * Input is currently driven directly by the incoming h264 parser, using a queue and a
     * separate loop does not seem to work in testing, might be a MediaCodec quirk or just a bug here
     * somewhere
     */
    //QFuture<void> input_future = QtConcurrent::run(this, &OpenHDMMALVideo::inputLoop);
    QFuture<void> render_future = QtConcurrent::run(this, &OpenHDMMALVideo::renderLoop);
}


void OpenHDMMALVideo::inputLoop() {
    while (true) {
        auto nalUnit = nalQueue.front();
        //processFrame(nalUnit);
    }
}


void OpenHDMMALVideo::processFrame(QByteArray &nal, FrameType frameType) {
    if (!isConfigured) {
        return;
    }

    MMAL_BUFFER_HEADER_T *buffer;

    while (true) {
        vcos_semaphore_wait(&m_context.in_semaphore);

        if ((buffer = mmal_queue_get(m_pool_in->queue)) != nullptr) {

            memcpy(buffer->data, nal.data(), nal.length());
            buffer->length = nal.length();

            buffer->offset = 0;

            buffer->flags |= MMAL_BUFFER_HEADER_FLAG_FRAME_END;

            buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;

            if (!buffer->length) {
                break;
            }

            m_status = mmal_port_send_buffer(m_decoder->input[0], buffer);
            if (m_status != MMAL_SUCCESS) {
                break;
            }
            break;
        }
    }
}


void OpenHDMMALVideo::renderLoop() {

    MMAL_BUFFER_HEADER_T *buffer;
    MMAL_STATUS_T status = MMAL_EINVAL;

    while (true) {
        vcos_semaphore_wait(&m_context.out_semaphore);


        /* Get decoded frame */
        while ((buffer = mmal_queue_get(m_context.queue)) != NULL) {
            if (buffer->cmd) {
                if (m_videoOut) {
                    double frameSize = 1920 * 1080 * 1.5;
                    uint8_t *dummyFrame = (uint8_t*)malloc(sizeof(char) * frameSize);
                    memset(dummyFrame, 0, (size_t)frameSize);
                    m_videoOut->paintFrame(dummyFrame, (size_t)frameSize);
                    m_videoOut->paintFrame(dummyFrame, (size_t)frameSize);
                    m_videoOut->paintFrame(dummyFrame, (size_t)frameSize);
                    m_videoOut->paintFrame(dummyFrame, (size_t)frameSize);
                    free(dummyFrame);
                }
                if (buffer->cmd == MMAL_EVENT_FORMAT_CHANGED) {
                    MMAL_EVENT_FORMAT_CHANGED_T *event = mmal_event_format_changed_get(buffer);
                    /*Assume we can't reuse the buffers, so have to disable, destroy
                      pool, create new pool, enable port, feed in buffers.*/
                    status = mmal_port_disable(m_decoder->output[0]);

                    //Clear the queue of all buffers
                    while(mmal_queue_length(m_pool_out->queue) != m_pool_out->headers_num) {
                        MMAL_BUFFER_HEADER_T *buf;
                        vcos_semaphore_wait(&m_context.out_semaphore);
                        buf = mmal_queue_get(m_context.queue);
                        mmal_buffer_header_release(buf);
                    }

                    mmal_port_pool_destroy(m_decoder->output[0], m_pool_out);
                    status = mmal_format_full_copy(m_decoder->output[0]->format, event->format);
                    status = mmal_port_format_commit(m_decoder->output[0]);

                    m_pool_out = mmal_port_pool_create(m_decoder->output[0],
                            m_decoder->output[0]->buffer_num,
                            m_decoder->output[0]->buffer_size);

                    status = mmal_port_enable(m_decoder->output[0], output_callback);
                    m_videoOut->setFormat(event->format->es->video.width, event->format->es->video.height, QVideoFrame::PixelFormat::Format_YUV420P);
                }
                mmal_buffer_header_release(buffer);
            } else {
                // buffer is released by the renderer when it finishes with the frame
                if (m_videoOut) {
                    m_videoOut->paintFrame(buffer);
                }
                m_frames = m_frames + 1;
                qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
                auto elapsed = current_timestamp - m_last_time;
                if (elapsed > 5000) {
                    auto fps = m_frames / (elapsed / 1000.0);
                    m_last_time = current_timestamp;
                    m_frames = 0;
                }
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

#endif
#endif
