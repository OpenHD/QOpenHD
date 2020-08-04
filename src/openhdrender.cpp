#if defined(ENABLE_VIDEO_RENDER)

#include "openhdrender.h"

#include <QQuickWindow>
#include <QApplication>
#include <QCoreApplication>
#include <QOpenGLContext>


#if defined(__android__)

static const GLfloat g_vertex_data[] = {
    -1.f, 1.f,
    1.f, 1.f,
    1.f, -1.f,
    -1.f, -1.f
};

static const GLfloat g_texture_data[] = {
    0.f, 0.f,
    1.f, 0.f,
    1.f, 1.f,
    0.f, 1.f
};

void OpenGLResourcesDeleter::deleteTextureHelper(quint32 id) {
    if (id != 0)
        glDeleteTextures(1, &id);
}

void OpenGLResourcesDeleter::deleteFboHelper(void *fbo) {
    delete reinterpret_cast<QOpenGLFramebufferObject *>(fbo);
}

void OpenGLResourcesDeleter::deleteShaderProgramHelper(void *prog) {
    delete reinterpret_cast<QOpenGLShaderProgram *>(prog);
}

void OpenGLResourcesDeleter::deleteThisHelper() {
    delete this;
}


class AndroidTextureVideoBuffer : public QAbstractVideoBuffer {
public:
    AndroidTextureVideoBuffer(OpenHDRender *renderer, const QSize &size)
        : QAbstractVideoBuffer(GLTextureHandle)
        , m_mapMode(NotMapped)
        , m_renderer(renderer)
        , m_size(size)
        , m_textureUpdated(false) {}


    virtual ~AndroidTextureVideoBuffer() {}

    MapMode mapMode() const {
        return m_mapMode;
    }

    uchar *map(MapMode mode, int *numBytes, int *bytesPerLine) {
        if (m_mapMode == NotMapped && mode == ReadOnly && updateFrame()) {
            m_mapMode = mode;
            m_image = m_renderer->m_fbo->toImage();
            if (numBytes) {
                *numBytes = m_image.sizeInBytes();
            }
            if (bytesPerLine) {
                *bytesPerLine = m_image.bytesPerLine();
            }
            return m_image.bits();
        } else {
            return 0;
        }
    }

    void unmap() {
        m_image = QImage();
        m_mapMode = NotMapped;
    }

    QVariant handle() const {
        AndroidTextureVideoBuffer *that = const_cast<AndroidTextureVideoBuffer*>(this);
        if (!that->updateFrame()) {
            return QVariant();
        }
        return m_renderer->m_fbo->texture();
    }
private:
    bool updateFrame() {
        // Even though the texture was updated in a previous call, we need to re-check
        // that this has not become a stale buffer, e.g., if the output size changed or
        // has since became invalid.
        if (!m_renderer->m_nativeSize.isValid()) {
            return false;
        }

        // Size changed
        if (m_renderer->m_nativeSize != m_size) {
            return false;
        }
        // In the unlikely event that we don't have a valid fbo, but have a valid size,
        // force an update.
        const bool forceUpdate = !m_renderer->m_fbo;
        if (m_textureUpdated && !forceUpdate) {
            return true;
        }
        // update the video texture (called from the render thread)
        return (m_textureUpdated = m_renderer->renderFrameToFbo());
    }
    MapMode m_mapMode;
    OpenHDRender *m_renderer = nullptr;
    QImage m_image;
    QSize m_size;
    bool m_textureUpdated;
};

#endif


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

#if defined(__android__)
    , m_surfaceTexture(0)
    , m_externalTex(0)
    , m_fbo(0)
    , m_program(0)
    , m_glDeleter(0)
    , m_surfaceTextureCanAttachToContext(true)
#endif
 {
    qDebug() << "OpenHDRender::OpenHDRender()";

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
#if defined(__android__)
    clearSurfaceTexture();

    if (m_glDeleter) { // Make sure all of these are deleted on the render thread.
        m_glDeleter->deleteFbo(m_fbo);
        m_glDeleter->deleteShaderProgram(m_program);
        m_glDeleter->deleteTexture(m_externalTex);
        m_glDeleter->deleteThis();
    }
#endif
}

void OpenHDRender::setVideoSurface(QAbstractVideoSurface *surface) {
    qDebug() << "OpenHDRender::setVideoSurface()";

    if (m_surface && m_surface != surface && m_surface->isActive()) {
        m_surface->stop();
    }

    #if defined(__android__)
    if (m_surface) {
        if (!m_surfaceTextureCanAttachToContext) {
            m_surface->setProperty("_q_GLThreadCallback", QVariant());
        }
    }
    #endif


    m_surface = surface;

    m_supportsTextures = m_surface ? !m_surface->supportedPixelFormats(QAbstractVideoBuffer::GLTextureHandle).isEmpty() : false;

    #if defined(__android__)
    if (m_surface && !m_surfaceTextureCanAttachToContext) {
        m_surface->setProperty("_q_GLThreadCallback",
                               QVariant::fromValue<QObject*>(this));
    }
    #endif
}


#if defined(__android__)
bool OpenHDRender::isReady() {
    qDebug() << "OpenHDRender::isReady()";

    return m_surfaceTextureCanAttachToContext || QOpenGLContext::currentContext() || m_externalTex;
}


AndroidSurfaceTexture *OpenHDRender::surfaceTexture() {
    qDebug() << "OpenHDRender::surfaceTexture()";
    if (!initSurfaceTexture()) {
        return 0;
    }
    return m_surfaceTexture;
}


bool OpenHDRender::initSurfaceTexture() {
    qDebug() << "OpenHDRender::initSurfaceTexture()";

    if (m_surfaceTexture) {
        return true;
    }

    if (!m_surface) {
        return false;
    }

    if (!m_surfaceTextureCanAttachToContext) {
        // if we have an OpenGL context in the current thread, create a texture. Otherwise, wait
        // for the GL render thread to call us back to do it.
        if (QOpenGLContext::currentContext()) {
            glGenTextures(1, &m_externalTex);

            if (!m_glDeleter) {
                m_glDeleter = new OpenGLResourcesDeleter;
            }
        } else if (!m_externalTex) {
            return false;
        }
    }

    QMutexLocker locker(&m_mutex);

    m_surfaceTexture = new AndroidSurfaceTexture(m_externalTex);

    if (m_surfaceTexture->surfaceTexture() != 0) {
        connect(m_surfaceTexture, &AndroidSurfaceTexture::frameAvailable, this, &OpenHDRender::onFrameAvailable);
    } else {
        delete m_surfaceTexture;
        m_surfaceTexture = 0;

        if (m_glDeleter) {
            m_glDeleter->deleteTexture(m_externalTex);
        }

        m_externalTex = 0;
    }

    return m_surfaceTexture != 0;
}


void OpenHDRender::clearSurfaceTexture() {
    qDebug() << "OpenHDRender::clearSurfaceTexture()";

    QMutexLocker locker(&m_mutex);

    if (m_surfaceTexture) {
        delete m_surfaceTexture;

        m_surfaceTexture = 0;
    }

    // Also reset the attached OpenGL texture
    // Note: The Android SurfaceTexture class does not release the texture on deletion,
    // only if detachFromGLContext() called (API level >= 16), so we'll do it manually,
    // on the render thread.
    if (m_surfaceTextureCanAttachToContext) {
        if (m_glDeleter) {
            m_glDeleter->deleteTexture(m_externalTex);
        }

        m_externalTex = 0;
    }
}


void OpenHDRender::setVideoSize(const QSize &size) {
    qDebug() << "OpenHDRender::setVideoSize()";

    QMutexLocker locker(&m_mutex);

    if (m_nativeSize == size) {
        return;
    }

    stop();

    m_nativeSize = size;
}

void OpenHDRender::stop() {
    qDebug() << "OpenHDRender::stop()";

    if (m_surface && m_surface->isActive()) {
        m_surface->stop();
    }

    m_nativeSize = QSize();
}



void OpenHDRender::reset() {
    qDebug() << "OpenHDRender::reset()";

    // flush pending frame

    if (m_surface) {
        m_surface->present(QVideoFrame());
    }

    clearSurfaceTexture();
}


void OpenHDRender::onFrameAvailable() {
    if (!m_nativeSize.isValid() || !m_surface) {
        return;
    }

    QAbstractVideoBuffer *buffer = new AndroidTextureVideoBuffer(this, m_nativeSize);

    QVideoFrame frame(buffer, m_nativeSize, QVideoFrame::Format_ABGR32);

    if (m_surface->isActive() && (m_surface->surfaceFormat().pixelFormat() != frame.pixelFormat()
                                  || m_surface->surfaceFormat().frameSize() != frame.size())) {
        m_surface->stop();
    }

    if (!m_surface->isActive()) {
        QVideoSurfaceFormat format(frame.size(), frame.pixelFormat(),
                                   QAbstractVideoBuffer::GLTextureHandle);
        m_surface->start(format);
    }

    if (m_surface->isActive())
        m_surface->present(frame);
}


bool OpenHDRender::renderFrameToFbo() {
    QMutexLocker locker(&m_mutex);

    if (!m_nativeSize.isValid() || !m_surfaceTexture) {
        return false;
    }

    createGLResources();

    m_surfaceTexture->updateTexImage();

    // save current render states
    GLboolean stencilTestEnabled;
    GLboolean depthTestEnabled;
    GLboolean scissorTestEnabled;
    GLboolean blendEnabled;
    glGetBooleanv(GL_STENCIL_TEST, &stencilTestEnabled);
    glGetBooleanv(GL_DEPTH_TEST, &depthTestEnabled);
    glGetBooleanv(GL_SCISSOR_TEST, &scissorTestEnabled);
    glGetBooleanv(GL_BLEND, &blendEnabled);
    if (stencilTestEnabled)
        glDisable(GL_STENCIL_TEST);
    if (depthTestEnabled)
        glDisable(GL_DEPTH_TEST);
    if (scissorTestEnabled)
        glDisable(GL_SCISSOR_TEST);
    if (blendEnabled)
        glDisable(GL_BLEND);
    m_fbo->bind();
    glViewport(0, 0, m_nativeSize.width(), m_nativeSize.height());
    m_program->bind();
    m_program->enableAttributeArray(0);
    m_program->enableAttributeArray(1);
    m_program->setUniformValue("frameTexture", GLuint(0));
    m_program->setUniformValue("texMatrix", m_surfaceTexture->getTransformMatrix());
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, g_vertex_data);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, g_texture_data);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    m_program->disableAttributeArray(0);
    m_program->disableAttributeArray(1);
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
    m_fbo->release();
    // restore render states
    if (stencilTestEnabled)
        glEnable(GL_STENCIL_TEST);
    if (depthTestEnabled)
        glEnable(GL_DEPTH_TEST);
    if (scissorTestEnabled)
        glEnable(GL_SCISSOR_TEST);
    if (blendEnabled)
        glEnable(GL_BLEND);
    return true;
}


void OpenHDRender::createGLResources() {
    Q_ASSERT(QOpenGLContext::currentContext() != NULL);

    if (!m_glDeleter) {
        m_glDeleter = new OpenGLResourcesDeleter;
    }

    if (m_surfaceTextureCanAttachToContext && !m_externalTex) {
        m_surfaceTexture->detachFromGLContext();
        glGenTextures(1, &m_externalTex);

        m_surfaceTexture->attachToGLContext(m_externalTex);
    }

    if (!m_fbo || m_fbo->size() != m_nativeSize) {
        delete m_fbo;
        m_fbo = new QOpenGLFramebufferObject(m_nativeSize);
    }

    if (!m_program) {
        m_program = new QOpenGLShaderProgram;
        QOpenGLShader *vertexShader = new QOpenGLShader(QOpenGLShader::Vertex, m_program);
        vertexShader->compileSourceCode("attribute highp vec4 vertexCoordsArray; \n" \
                                        "attribute highp vec2 textureCoordArray; \n" \
                                        "uniform   highp mat4 texMatrix; \n" \
                                        "varying   highp vec2 textureCoords; \n" \
                                        "void main(void) \n" \
                                        "{ \n" \
                                        "    gl_Position = vertexCoordsArray; \n" \
                                        "    textureCoords = (texMatrix * vec4(textureCoordArray, 0.0, 1.0)).xy; \n" \
                                        "}\n");

        m_program->addShader(vertexShader);

        QOpenGLShader *fragmentShader = new QOpenGLShader(QOpenGLShader::Fragment, m_program);

        fragmentShader->compileSourceCode("#extension GL_OES_EGL_image_external : require \n" \
                                          "varying highp vec2         textureCoords; \n" \
                                          "uniform samplerExternalOES frameTexture; \n" \
                                          "void main() \n" \
                                          "{ \n" \
                                          "    gl_FragColor = texture2D(frameTexture, textureCoords); \n" \
                                          "}\n");

        m_program->addShader(fragmentShader);

        m_program->bindAttributeLocation("vertexCoordsArray", 0);
        m_program->bindAttributeLocation("textureCoordArray", 1);

        m_program->link();
    }
}

void OpenHDRender::customEvent(QEvent *e) {
    if (e->type() == QEvent::User) {

        // This is running in the render thread (OpenGL enabled)
        if (!m_surfaceTextureCanAttachToContext && !m_externalTex) {
            glGenTextures(1, &m_externalTex);

            if (!m_glDeleter) {
                // We'll use this to cleanup GL resources in the correct thread
                m_glDeleter = new OpenGLResourcesDeleter;
            }

            emit readyChanged(true);
        }
    }
}
#endif


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
