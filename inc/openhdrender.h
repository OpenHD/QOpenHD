#if defined(ENABLE_VIDEO_RENDER)

#ifndef OpenHDRender_H
#define OpenHDRender_H

#include <QQuickItem>
#include <QAbstractVideoSurface>
#include <QVideoSurfaceFormat>

#if defined(__android__)
#include "androidsurfacetexture.h"
#include <QMutex>
#include <QOpenGLFramebufferObject>
#include <QOpenGLShaderProgram>

class OpenGLResourcesDeleter : public QObject
{
    Q_OBJECT
public:
    void deleteTexture(quint32 id) { QMetaObject::invokeMethod(this, "deleteTextureHelper", Qt::AutoConnection, Q_ARG(quint32, id)); }
    void deleteFbo(QOpenGLFramebufferObject *fbo) { QMetaObject::invokeMethod(this, "deleteFboHelper", Qt::AutoConnection, Q_ARG(void *, fbo)); }
    void deleteShaderProgram(QOpenGLShaderProgram *prog) { QMetaObject::invokeMethod(this, "deleteShaderProgramHelper", Qt::AutoConnection, Q_ARG(void *, prog)); }
    void deleteThis() { QMetaObject::invokeMethod(this, "deleteThisHelper"); }
private:
    Q_INVOKABLE void deleteTextureHelper(quint32 id);
    Q_INVOKABLE void deleteFboHelper(void *fbo);
    Q_INVOKABLE void deleteShaderProgramHelper(void *prog);
    Q_INVOKABLE void deleteThisHelper();
};

#endif

#if defined(__apple__)
#include <VideoToolbox/VideoToolbox.h>
#endif

#if defined(__rasp_pi__)
#include "interface/mmal/mmal.h"
#endif

class OpenHDRender : public QQuickItem {
    Q_OBJECT
public:
    OpenHDRender(QQuickItem *parent = nullptr);
    ~OpenHDRender() override;

    Q_PROPERTY(QAbstractVideoSurface *videoSurface READ videoSurface WRITE setVideoSurface)

    void paintFrame(uint8_t *buffer_data, size_t buffer_length);
    #if defined(__apple__)
    void paintFrame(CVImageBufferRef imageBuffer);
    #endif

    #if defined(__android__)
    void paintFrame();
    #endif

    #if defined(__rasp_pi__)
    void paintFrame(MMAL_BUFFER_HEADER_T *buffer);
    #endif

    bool supportsTextures() const { return m_supportsTextures; }

    QAbstractVideoSurface* videoSurface() const { return m_surface; }

#if defined(__android__)
    AndroidSurfaceTexture *surfaceTexture();
    bool isReady();
    void setVideoSize(const QSize &);
    void stop();
    void reset();
    void customEvent(QEvent *) override;
#endif

signals:
    void newFrameAvailable(const QVideoFrame &frame);

    #if defined(__android__)
    void surfaceTextureChanged(OpenHDRender *surfaceTexture);
    void readyChanged(bool);
    #endif

private:
    QAbstractVideoSurface *m_surface = nullptr;
    QVideoSurfaceFormat m_format;

    bool m_supportsTextures;

#ifdef Q_OS_IOS
    CVOpenGLESTextureCacheRef m_textureCache = nullptr;
#endif

    friend class CVPixelBufferVideoBuffer;


public:
    void setVideoSurface(QAbstractVideoSurface *surface);

    void setFormat(int width, int heigth, QVideoFrame::PixelFormat format);



    bool initSurfaceTexture();
    bool renderFrameToFbo();
    void createGLResources();

    #if defined(__android__)
    QMutex m_mutex;

    void clearSurfaceTexture();

    QSize m_nativeSize;

    AndroidSurfaceTexture *m_surfaceTexture;
    quint32 m_externalTex;
    QOpenGLFramebufferObject *m_fbo;
    QOpenGLShaderProgram *m_program;
    OpenGLResourcesDeleter *m_glDeleter;
    bool m_surfaceTextureCanAttachToContext;
    #endif


public slots:
    void onNewVideoContentReceived(const QVideoFrame &frame);

    #if defined(__android__)
    void onFrameAvailable();
    #endif
};

#endif // OpenHDRender_H

#endif
