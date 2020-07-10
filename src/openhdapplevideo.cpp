#if defined(ENABLE_VIDEO_RENDER)
#if defined(__apple__)

#include <QtConcurrent>
#include <QtQuick>
#include <QThread>
#include <QtConcurrent>
#include <QFuture>

#include "openhdapplevideo.h"
#include "openhdrender.h"
#include "constants.h"
#include "localmessage.h"

#include "sharedqueue.h"

#include <VideoToolbox/VideoToolbox.h>

#include "h264_common.h"

#include "appleplatform.h"


using namespace std::chrono;


void decompressionOutputCallback(void *decompressionOutputRefCon,
                                 void *sourceFrameRefCon,
                                 OSStatus status,
                                 VTDecodeInfoFlags infoFlags,
                                 CVImageBufferRef imageBuffer,
                                 CMTime presentationTimeStamp,
                                 CMTime presentationDuration) {
    OpenHDAppleVideo *t = static_cast<OpenHDAppleVideo*>(decompressionOutputRefCon);

    if (status != noErr) {
        qDebug() << "Decompressed error: " << status;
    } else {
        t->processDecodedFrame(imageBuffer);
    }
}


OpenHDAppleVideo::OpenHDAppleVideo(enum OpenHDStreamType stream_type): OpenHDVideo(stream_type) {
    qDebug() << "OpenHDAppleVideo::OpenHDAppleVideo()";
    connect(this, &OpenHDAppleVideo::configure, this, &OpenHDAppleVideo::vtdecConfigure, Qt::DirectConnection);

    connect(this, &OpenHDAppleVideo::setup, this, &OpenHDAppleVideo::onSetup);

}

void OpenHDAppleVideo::onSetup() {
    qDebug() << "OpenHDAppleVideo::onSetup()";

    #if defined(__ios__)
    auto applePlatform = ApplePlatform::instance();
    connect(applePlatform, &ApplePlatform::willEnterForeground, this, &OpenHDAppleVideo::start, Qt::QueuedConnection);
    connect(applePlatform, &ApplePlatform::didEnterBackground, this, &OpenHDAppleVideo::stop, Qt::QueuedConnection);
    #endif
}


OpenHDAppleVideo::~OpenHDAppleVideo() {
    qDebug() << "~OpenHDAppleVideo()";
}


void OpenHDAppleVideo::start() {
    m_background = false;
    m_restart = true;
}


void OpenHDAppleVideo::stop() {
    m_background = true;
    if (m_decompressionSession != nullptr) {
        VTDecompressionSessionInvalidate(m_decompressionSession);
        CFRelease(m_decompressionSession);
        m_decompressionSession = nullptr;
    }
    if (m_formatDesc != nullptr) {
        CFRelease(m_formatDesc);
        m_formatDesc = nullptr;
    }
}


OpenHDRender* OpenHDAppleVideo::videoOut() const {
    return m_videoOut;
}


void OpenHDAppleVideo::setVideoOut(OpenHDRender *videoOut) {
    qDebug() << "OpenHDAppleVideo::setVideoOut(" << videoOut << ")";

    if (m_videoOut == videoOut) {
        return;
    }

    if (m_videoOut) {
        //m_videoOut->disconnect(this);
    }

    m_videoOut = videoOut;

    emit videoOutChanged();
}


void OpenHDAppleVideo::vtdecConfigure() {
    auto t = QThread::currentThread();

    qDebug() << "OpenHDAppleVideo::vtdecConfigure()";
    qDebug() << t;

    OSStatus status;

    if (m_formatDesc != nullptr) {
        CFRelease(m_formatDesc);
        m_formatDesc = nullptr;
    }

    // iOS decoder wants the SPS and PPS without any headers so we skip that part and use just the data
    uint8_t* vtdec_sps = (uint8_t*)malloc(sps_len - 4);
    uint8_t* vtdec_pps = (uint8_t*)malloc(pps_len - 4);

    memcpy(vtdec_sps, &sps[4], sps_len-4);
    memcpy(vtdec_pps, &pps[4], pps_len-4);

    uint8_t* parameterSetPointers[2] = {vtdec_sps, vtdec_pps};
    size_t parameterSetSizes[2] = {(size_t)sps_len-4, (size_t)pps_len-4};

    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                 2,
                                                                 (const uint8_t *const*)parameterSetPointers,
                                                                 parameterSetSizes,
                                                                 4,
                                                                 &m_formatDesc);

    free(vtdec_sps);
    free(vtdec_pps);

    if (status != noErr) {
        qDebug() << "CMVideoFormatDescriptionCreateFromH264ParameterSets() failed: " << (int)status;
        return;
    }
    qDebug() << "CMVideoFormatDescriptionCreateFromH264ParameterSets() success";


    // set up the callback that will be run whenever a frame is decoded
    m_decompressionSession = nullptr;
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = decompressionOutputCallback;
    callBackRecord.decompressionOutputRefCon = static_cast<void*>(this);

    #if defined(__ios__)
    int useGL = 1;

    const void *keys[] =   { kCVPixelBufferOpenGLESCompatibilityKey };
    const void *values[] = { CFNumberCreate(nullptr, kCFNumberIntType, &useGL) };

    CFDictionaryRef destinationImageBufferAttributes = CFDictionaryCreate(nullptr,
                                                                          keys,
                                                                          values,
                                                                          1,
                                                                          nullptr,
                                                                          nullptr);
    #else
    CFDictionaryRef destinationImageBufferAttributes = nullptr;
    #endif

    status = VTDecompressionSessionCreate(nullptr,
                                          m_formatDesc,
                                          nullptr,
                                          destinationImageBufferAttributes,
                                          &callBackRecord,
                                          &m_decompressionSession);

    if (status != noErr) {
        qDebug() << "Decompression session error:"  << status;
        return;
    }

    qDebug() << "Decompression session created";


    isConfigured = true;

    QThread::msleep(100);

    m_videoOut->setFormat(width, height, QVideoFrame::PixelFormat::Format_BGRA32);
}


void OpenHDAppleVideo::inputLoop() {

}


void OpenHDAppleVideo::processFrame(QByteArray &nal, webrtc::H264::NaluType frameType) {

    if (frameType == webrtc::H264::NaluType::kSps || frameType == webrtc::H264::NaluType::kPps || frameType == webrtc::H264::NaluType::kAud) {
        return;
    }

    CMSampleBufferRef sampleBuffer = nullptr;
    CMBlockBufferRef blockBuffer = nullptr;

    QByteArray avccBuffer;
    avccBuffer.append(nal.data(), nal.size());

    uint32_t dataLength32 = htonl(avccBuffer.size() - 4);
    memcpy (avccBuffer.data(), &dataLength32, sizeof (uint32_t));


    OSStatus status = CMBlockBufferCreateWithMemoryBlock(nullptr,
                                                         avccBuffer.data(),
                                                         avccBuffer.size(),
                                                         kCFAllocatorNull,
                                                         nullptr,
                                                         0,
                                                         avccBuffer.size(),
                                                         0,
                                                         &blockBuffer);

    // now create our sample buffer from the block buffer,
    if(status != noErr) {
        qDebug() << "CMBlockBufferCreateWithMemoryBlock fail: " << status;
        if (blockBuffer) {
            CFRelease(blockBuffer);
        }
        return;
    }

    const size_t sampleSize = avccBuffer.size();

    status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                       blockBuffer,
                                       m_formatDesc,
                                       1,
                                       0,
                                       nullptr,
                                       1,
                                       &sampleSize,
                                       &sampleBuffer);


    if (status != noErr) {
        qDebug() << "CMSampleBufferCreateReady fail: " << status;
        if (sampleBuffer) {
            CFRelease(sampleBuffer);
        }
        if (blockBuffer) {
            CFRelease(blockBuffer);
        }
        return;
    }

    // set some values of the sample buffer's attachments
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);


    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;

    status = VTDecompressionSessionDecodeFrame(m_decompressionSession,
                                               sampleBuffer,
                                               flags,
                                               nullptr,
                                               &flagOut);

    if (status != noErr) {
        qDebug() << "VTDecompressionSessionDecodeFrame fail: " << status;
    }

    if (sampleBuffer) {
        CFRelease(sampleBuffer);
    }
    if (blockBuffer) {
        CFRelease(blockBuffer);
    }
}


void OpenHDAppleVideo::processDecodedFrame(CVImageBufferRef imageBuffer) {
    if (m_videoOut) {
        m_videoOut->paintFrame(imageBuffer);
    }
}

void OpenHDAppleVideo::renderLoop() {

}

#endif
#endif
