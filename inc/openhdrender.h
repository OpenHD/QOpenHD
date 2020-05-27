#if defined(ENABLE_VIDEO_RENDER)

#ifndef OpenHDRender_H
#define OpenHDRender_H

#include <QQuickItem>
#include <QAbstractVideoSurface>
#include <QVideoSurfaceFormat>

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

    #if defined(__rasp_pi__)
    void paintFrame(MMAL_BUFFER_HEADER_T *buffer);
    #endif

    bool supportsTextures() const { return m_supportsTextures; }

    QAbstractVideoSurface* videoSurface() const { return m_surface; }

signals:
    void newFrameAvailable(const QVideoFrame &frame);

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

public slots:
    void onNewVideoContentReceived(const QVideoFrame &frame);
};

#endif // OpenHDRender_H

#endif
