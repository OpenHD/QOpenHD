#if defined(ENABLE_VIDEO_RENDER)

#include "openhdrender.h"

#include <QQuickWindow>
#include <QApplication>
#include <QCoreApplication>
#include <QOpenGLContext>

#if defined(__apple__)
#include <VideoToolbox/VideoToolbox.h>

// copied from Qt source to avoid pulling in an objc++ header
QVideoFrame::PixelFormat QtPixelFormatFromCVFormat(OSType avPixelFormat)
{
    /* BGRA <-> ARGB "swap" is intentional:
       to work correctly with GL_RGBA, color swap shaders
       (in QSG node renderer etc.). */
    switch (avPixelFormat) {
    case kCVPixelFormatType_32ARGB:
        return QVideoFrame::Format_BGRA32;
    case kCVPixelFormatType_32BGRA:
        return QVideoFrame::Format_ARGB32;
    case kCVPixelFormatType_24RGB:
        return QVideoFrame::Format_RGB24;
    case kCVPixelFormatType_24BGR:
        return QVideoFrame::Format_BGR24;
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
        return QVideoFrame::Format_NV12;
    case kCVPixelFormatType_422YpCbCr8:
        return QVideoFrame::Format_UYVY;
    case kCVPixelFormatType_422YpCbCr8_yuvs:
        return QVideoFrame::Format_YUYV;
    default:
        return QVideoFrame::Format_Invalid;
    }
}


class CVPixelBufferVideoBuffer : public QAbstractPlanarVideoBuffer
{
public:
    CVPixelBufferVideoBuffer(CVPixelBufferRef buffer, OpenHDRender *renderer)
    #ifndef Q_OS_IOS
    : QAbstractPlanarVideoBuffer(NoHandle)
    #else
    : QAbstractPlanarVideoBuffer(renderer->supportsTextures()
                                     && CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA
                                     ? GLTextureHandle : NoHandle)
    , m_texture(nullptr)
    #endif
    , m_renderer(renderer)
    , m_buffer(buffer)
    , m_mode(NotMapped) {

        CVPixelBufferRetain(m_buffer);
    }

    virtual ~CVPixelBufferVideoBuffer() {
        unmap();
        #ifdef Q_OS_IOS
        if (m_texture) {
            CFRelease(m_texture);
        }
        #endif
        CVPixelBufferRelease(m_buffer);
    }

    MapMode mapMode() const {
        return m_mode;
    }

    /*
     * Copied from Qt source.
     *
     * The framework version of this class depends on a different rendering method that we
     * don't use, so we copy the method here instead
     */
    int map(QAbstractVideoBuffer::MapMode mode, int *numBytes, int bytesPerLine[4], uchar *data[4]) {
        const size_t nPlanes = CVPixelBufferGetPlaneCount(m_buffer);

        if (!nPlanes) {
            data[0] = map(mode, numBytes, bytesPerLine);
            return data[0] ? 1 : 0;
        }

        if (mode != QAbstractVideoBuffer::NotMapped && m_mode == QAbstractVideoBuffer::NotMapped) {
            CVPixelBufferLockBaseAddress(m_buffer, mode == QAbstractVideoBuffer::ReadOnly
                                                               ? kCVPixelBufferLock_ReadOnly
                                                               : 0);

            if (numBytes)
                *numBytes = CVPixelBufferGetDataSize(m_buffer);

            if (bytesPerLine) {
                bytesPerLine[0] = CVPixelBufferGetBytesPerRowOfPlane(m_buffer, 0);
                bytesPerLine[1] = CVPixelBufferGetBytesPerRowOfPlane(m_buffer, 1);
            }

            if (data) {
                data[0] = static_cast<uchar*>(CVPixelBufferGetBaseAddressOfPlane(m_buffer, 0));
                data[1] = static_cast<uchar*>(CVPixelBufferGetBaseAddressOfPlane(m_buffer, 1));
            }

            m_mode = mode;
        }

        return nPlanes;
    }

    uchar *map(MapMode mode, int *numBytes, int *bytesPerLine) {
        if (mode != NotMapped && m_mode == NotMapped) {
            CVPixelBufferLockBaseAddress(m_buffer, mode == QAbstractVideoBuffer::ReadOnly
                                                               ? kCVPixelBufferLock_ReadOnly
                                                               : 0);

            const size_t nPlanes = CVPixelBufferGetPlaneCount(m_buffer);

            if (numBytes) {
                *numBytes = CVPixelBufferGetDataSize(m_buffer);
            }

            if (bytesPerLine) {
                *bytesPerLine = CVPixelBufferGetBytesPerRow(m_buffer);
            }

            m_mode = mode;

            return (uchar*)CVPixelBufferGetBaseAddress(m_buffer);
        } else {
            return nullptr;
        }
    }

    void unmap() {
        if (m_mode != NotMapped) {
            CVPixelBufferUnlockBaseAddress(m_buffer, m_mode == QAbstractVideoBuffer::ReadOnly
                                                                   ? kCVPixelBufferLock_ReadOnly
                                                                   : 0);
            m_mode = NotMapped;
        }
    }

    QVariant handle() const {
#ifdef Q_OS_IOS
        // Called from the render thread, so there is a current OpenGL context

        if (!m_renderer->m_textureCache) {
            QOpenGLContext *c = QOpenGLContext::currentContext();

            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                        nullptr,
                                                        c,
                                                        nullptr,
                                                        &m_renderer->m_textureCache);

            if (err != kCVReturnSuccess)
                qWarning("Error creating texture cache");
        }

        if (m_renderer->m_textureCache && !m_texture) {
            CVOpenGLESTextureCacheFlush(m_renderer->m_textureCache, 0);

            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        m_renderer->m_textureCache,
                                                                        m_buffer,
                                                                        nullptr,
                                                                        GL_TEXTURE_2D,
                                                                        GL_RGBA,
                                                                        CVPixelBufferGetWidth(m_buffer),
                                                                        CVPixelBufferGetHeight(m_buffer),
                                                                        GL_RGBA,
                                                                        GL_UNSIGNED_BYTE,
                                                                        0,
                                                                        &m_texture);

            if (err != kCVReturnSuccess) {
                qWarning("Error creating texture from buffer");
            }
        }

        if (m_texture) {
            return CVOpenGLESTextureGetName(m_texture);
        } else {
            return 0;
        }
#else
        return QVariant();
#endif
    }

private:
#ifdef Q_OS_IOS
    mutable CVOpenGLESTextureRef m_texture;
#endif
    OpenHDRender *m_renderer = nullptr;
    CVPixelBufferRef m_buffer = nullptr;
    MapMode m_mode = NotMapped;
};
#endif


#if defined(__rasp_pi__)
#include "interface/mmal/mmal.h"

class MMALPixelBufferVideoBuffer : public QAbstractPlanarVideoBuffer
{
public:
    MMALPixelBufferVideoBuffer(MMAL_BUFFER_HEADER_T *buffer, int width, int height): QAbstractPlanarVideoBuffer(NoHandle), m_buffer(buffer), m_mode(NotMapped), m_width(width), m_height(height) {

    }

    ~MMALPixelBufferVideoBuffer() {
        mmal_buffer_header_release(m_buffer);
    }

    MapMode mapMode() const {
        return m_mode;
    }

    int map(QAbstractVideoBuffer::MapMode mode, int *numBytes, int bytesPerLine[4], uchar *data[4]) {
        const size_t nPlanes = m_buffer->type->video.planes;

        if (!nPlanes) {
            data[0] = map(mode, numBytes, bytesPerLine);
            return data[0] ? 1 : 0;
        }

        if (mode != QAbstractVideoBuffer::NotMapped && m_mode == QAbstractVideoBuffer::NotMapped) {
            if (numBytes)
                *numBytes = m_buffer->length;

            if (bytesPerLine) {
                bytesPerLine[0] = m_buffer->type->video.pitch[0];
                bytesPerLine[1] = m_buffer->type->video.pitch[1];
                bytesPerLine[2] = m_buffer->type->video.pitch[2];
            }

            if (data) {
                data[0] = static_cast<uchar*>(m_buffer->data + m_buffer->type->video.offset[0]);
                data[1] = static_cast<uchar*>(m_buffer->data + m_buffer->type->video.offset[1]);
                data[2] = static_cast<uchar*>(m_buffer->data + m_buffer->type->video.offset[2]);
            }

            m_mode = mode;
        }

        return nPlanes;
    }

    uchar *map(MapMode mode, int *numBytes, int *bytesPerLine) {
        if (mode != NotMapped && m_mode == NotMapped) {
            if (numBytes) {
                *numBytes = m_buffer->length;
            }

            if (bytesPerLine) {
                *bytesPerLine = m_buffer->length / m_height;
            }

            m_mode = mode;

            return (uchar*)m_buffer->data;
        } else {
            return nullptr;
        }
    }

    void unmap() {
        if (m_mode != NotMapped) {
            m_mode = NotMapped;
        }
    }

private:
    MMAL_BUFFER_HEADER_T *m_buffer = nullptr;
    MapMode m_mode = NotMapped;
    int m_width = 0;
    int m_height = 0;
};
#endif



OpenHDRender::OpenHDRender(QQuickItem *parent): QQuickItem(parent)
    , m_supportsTextures(false)
#ifdef Q_OS_IOS
    , m_textureCache(nullptr)
#endif
 {
    QObject::connect(this, &OpenHDRender::newFrameAvailable, this, &OpenHDRender::onNewVideoContentReceived, Qt::QueuedConnection);
}

void OpenHDRender::paintFrame(uint8_t *buffer_data, size_t buffer_length) {
    if (buffer_length < 1024) {
        return;
    }

    QSize s = m_format.frameSize();
    auto stride = s.width();

    QVideoFrame f(buffer_length, s, stride, m_format.pixelFormat());
    f.map(QAbstractVideoBuffer::MapMode::WriteOnly);
    memcpy(f.bits(), buffer_data, buffer_length);
    f.unmap();

    emit newFrameAvailable(f);
}

#if defined(__apple__)
void OpenHDRender::paintFrame(CVImageBufferRef imageBuffer) {
    int width = CVPixelBufferGetWidth(imageBuffer);
    int height = CVPixelBufferGetHeight(imageBuffer);

    QVideoFrame::PixelFormat format = QtPixelFormatFromCVFormat(CVPixelBufferGetPixelFormatType(imageBuffer));

    QAbstractVideoBuffer *buffer = new CVPixelBufferVideoBuffer(imageBuffer, this);
    QVideoFrame f(buffer, QSize(width, height), format);
    emit newFrameAvailable(f);
}
#endif

#if defined(__rasp_pi__)
void OpenHDRender::paintFrame(MMAL_BUFFER_HEADER_T *buffer) {
    int width = m_format.frameWidth();
    int height = m_format.frameHeight();

    QAbstractVideoBuffer *b = new MMALPixelBufferVideoBuffer(buffer, width, height);
    QVideoFrame f(b, QSize(width, height), QVideoFrame::PixelFormat::Format_YUV420P);
    emit newFrameAvailable(f);
}
#endif

OpenHDRender::~OpenHDRender() {

}

void OpenHDRender::setVideoSurface(QAbstractVideoSurface *surface) {
    if (m_surface && m_surface != surface && m_surface->isActive()) {
        m_surface->stop();
    }

    m_surface = surface;

    m_supportsTextures = m_surface ? !m_surface->supportedPixelFormats(QAbstractVideoBuffer::GLTextureHandle).isEmpty() : false;

}

void OpenHDRender::setFormat(int width, int heigth, QVideoFrame::PixelFormat i_format) {
    QSize size(width, heigth);
    QVideoSurfaceFormat format(size, i_format);

    if (m_surface)  {
        if (m_surface->isActive()) {
            m_surface->stop();
        }
        m_format = m_surface->nearestFormat(format);
        m_surface->start(m_format);
    }
}

void OpenHDRender::onNewVideoContentReceived(const QVideoFrame &frame) {
    if (m_surface) {
        m_surface->present(frame);
    }
}

#endif
