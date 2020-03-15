#if defined(ENABLE_VIDEO_RENDER)

#ifndef OpenHDMMALRender_H
#define OpenHDMMALRender_H

#include <QQuickItem>
#include <QAbstractVideoSurface>
#include <QVideoSurfaceFormat>

#if defined(__apple__)
#include <VideoToolbox/VideoToolbox.h>
#endif

#if defined(__rasp_pi__)
#include "interface/mmal/mmal.h"
#endif

class OpenHDMMALRender : public QQuickItem {
    Q_OBJECT
public:
    OpenHDMMALRender(QQuickItem *parent = nullptr);
    ~OpenHDMMALRender() override;

    Q_PROPERTY(QAbstractVideoSurface *videoSurface READ videoSurface WRITE setVideoSurface)

    void paintFrame(uint8_t *buffer_data, size_t buffer_length);
    #if defined(__apple__)
    void paintFrame(CVImageBufferRef imageBuffer);
    #endif

    #if defined(__rasp_pi__)
    void paintFrame(MMAL_BUFFER_HEADER_T *buffer);
    #endif

    QAbstractVideoSurface* videoSurface() const { return m_surface; }

signals:
    void newFrameAvailable(const QVideoFrame &frame);

private:
    QAbstractVideoSurface *m_surface = nullptr;
    QVideoSurfaceFormat m_format;

public:
    void setVideoSurface(QAbstractVideoSurface *surface);

    void setFormat(int width, int heigth, QVideoFrame::PixelFormat format);

public slots:
    void onNewVideoContentReceived(const QVideoFrame &frame);
};

#endif // OpenHDMMALRender_H

#endif
