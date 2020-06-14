#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)

#include <QtConcurrent>
#include <QtQuick>
#include <QAndroidJniEnvironment>
#include <QThread>
#include <QUdpSocket>
#include <QtConcurrent>
#include <QFuture>

#include <media/NdkImage.h>
#include <media/NdkImageReader.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaCrypto.h>
#include <media/NdkMediaDrm.h>
#include <media/NdkMediaError.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <media/NdkMediaMuxer.h>

#include <android/native_activity.h>
#include <android/native_window_jni.h>
#include <android/rect.h>
#include <android/window.h>

#include "openhdandroidvideo.h"
#include "openhdandroidrender.h"
#include "constants.h"
#include "localmessage.h"

#include "sharedqueue.h"

using namespace std::chrono;



OpenHDAndroidVideo::OpenHDAndroidVideo(enum OpenHDStreamType stream_type): OpenHDVideo(stream_type) {
    qDebug() << "OpenHDAndroidVideo::OpenHDAndroidVideo()";
    connect(this, &OpenHDAndroidVideo::configure, this, &OpenHDAndroidVideo::androidConfigure, Qt::DirectConnection);
}

OpenHDAndroidVideo::~OpenHDAndroidVideo() {
    qDebug() << "~OpenHDAndroidVideo()";
}

void OpenHDAndroidVideo::start() {
    // nothing needed
}

void OpenHDAndroidVideo::stop() {
    if (codec) {
        if (isConfigured) {
            AMediaCodec_stop(codec);
            isConfigured = false;
        }
        AMediaCodec_delete(codec);
        codec = nullptr;
    }
    if (format) {
        AMediaFormat_delete(format);
        format = nullptr;
    }
}

OpenHDAndroidRender* OpenHDAndroidVideo::videoOut() const {
    return m_videoOut;
}

void OpenHDAndroidVideo::setVideoOut(OpenHDAndroidRender *videoOut) {
    qDebug() << "OpenHDAndroidVideo::setVideoOut()";
    if (m_videoOut == videoOut) {
        return;
    }

    if (m_videoOut) {
        m_videoOut->disconnect(this);
    }

    m_videoOut = videoOut;

    auto setSurfaceTexture = [=] {
        QAndroidJniEnvironment env;

        QAndroidJniObject surface("android/view/Surface",
                                  "(Landroid/graphics/SurfaceTexture;)V",
                                   m_videoOut->surfaceTexture().object());

        window = ANativeWindow_fromSurface(env, surface.object());
    };


    if (videoOut->surfaceTexture().isValid()) {
        setSurfaceTexture();
    } else {
        connect(m_videoOut.data(), &OpenHDAndroidRender::surfaceTextureChanged, this, setSurfaceTexture);
    }

    emit videoOutChanged();
}



void OpenHDAndroidVideo::androidConfigure() {

    auto t = QThread::currentThread();

    qDebug() << "OpenHDAndroidVideo::androidConfigure()";
    qDebug() << t;

    QAndroidJniObject surface("android/view/Surface", "(Landroid/graphics/SurfaceTexture;)V", m_videoOut->surfaceTexture().object());

    media_status_t status;

    codec = AMediaCodec_createDecoderByType("video/avc");



    format = AMediaFormat_new();
    AMediaFormat_setString(format, AMEDIAFORMAT_KEY_MIME, "video/avc");
    AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_WIDTH, width);
    AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_HEIGHT, height);
    AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_PUSH_BLANK_BUFFERS_ON_STOP, 0);
    AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_MAX_INPUT_SIZE, 0);


    AMediaFormat_setBuffer (format, "csd-0", sps, sps_len);
    AMediaFormat_setBuffer (format, "csd-1", pps, pps_len);

    status = AMediaCodec_configure(codec,
                                   format,
                                   window,
                                   nullptr,
                                   0);


    switch (status) {
        case AMEDIA_OK: {
            break;
        }
        case AMEDIA_ERROR_UNKNOWN: {
            qDebug() << "AMediaCodec_configure: AMEDIA_ERROR_UNKNOWN";
            break;
        }
        case AMEDIA_ERROR_MALFORMED: {
            qDebug() << "AMediaCodec_configure: AMEDIA_ERROR_MALFORMED";
            break;
        }
        case AMEDIA_ERROR_UNSUPPORTED: {
            qDebug() << "AMediaCodec_configure: AMEDIA_ERROR_UNSUPPORTED";
            break;
        }
        case AMEDIA_ERROR_INVALID_OBJECT: {
            qDebug() << "AMediaCodec_configure: AMEDIA_ERROR_INVALID_OBJECT";
            break;
        }
        case AMEDIA_ERROR_INVALID_PARAMETER: {
            qDebug() << "AMediaCodec_configure: AMEDIA_ERROR_INVALID_PARAMETER";
            break;
        }
        default: {
            break;
        }
    }


    status = AMediaCodec_start(codec);

    if (status != AMEDIA_OK) {
        qDebug() << "AMediaCodec_start failed";
        stop();

        return;
    }

    isConfigured = true;

    QThread::msleep(100);

    //QFuture<void> input_future = QtConcurrent::run(this, &OpenHDAndroidVideo::inputLoop);
    QFuture<void> render_future = QtConcurrent::run(this, &OpenHDAndroidVideo::renderLoop);
}

void OpenHDAndroidVideo::inputLoop() {
    while (true) {
        //auto nalUnit = nalQueue.front();
        //processFrame(nalUnit);
    }
}

void OpenHDAndroidVideo::processFrame(QByteArray &nal, FrameType frameType) {
    if (frameType == FrameTypeAU) {
        return;
    }

    if (!isConfigured) {
        return;
    }

    while (true) {

        ssize_t buffIdx = AMediaCodec_dequeueInputBuffer(codec, 15000);

        if (buffIdx == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {
            QThread::msleep(1);
            continue;
        } else if (buffIdx < 0) {
            return;
        }


        auto now = steady_clock::now().time_since_epoch();
        auto pts = duration_cast<microseconds>(now).count();

        size_t buffsize;
        uint8_t* inputBuff = AMediaCodec_getInputBuffer(codec, buffIdx, &buffsize);
        size_t finalSize = 0;
        if (inputBuff) {
            memcpy(inputBuff, nal.data(), nal.size());
            finalSize = nal.size();
        }
        //qDebug() << "AMediaCodec_queueInputBuffer";
        AMediaCodec_queueInputBuffer(codec, buffIdx, 0, finalSize, pts, 0);
        break;
    }
}


void OpenHDAndroidVideo::renderLoop() {
    while (true) {
        if (!isConfigured) {
            return;
        }
        AMediaCodecBufferInfo info;
        auto status = AMediaCodec_dequeueOutputBuffer(codec, &info, -1);
        if (status >= 0) {
            //const int64_t ts = (int64_t)duration_cast<nanoseconds>(steady_clock::now().time_since_epoch()).count();
            //AMediaCodec_releaseOutputBufferAtTime(codec, status, ts);
            AMediaCodec_releaseOutputBuffer(codec, (size_t)status, info.size != 0);
        } else if (status == AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED) {
            //qDebug("output buffers changed");
        } else if (status == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
            //auto format = AMediaCodec_getOutputFormat(codec);
            //qDebug("format changed to: %s", AMediaFormat_toString(format));
            //AMediaFormat_delete(format);
        } else if (status == AMEDIACODEC_INFO_TRY_AGAIN_LATER) {
            //qDebug("no output buffer right now");
        } else {
            //qDebug("unexpected info code: %zd", status);
        }
    }
}

#endif
#endif
