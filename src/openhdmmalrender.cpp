#if defined(ENABLE_VIDEO_RENDER)

#include "openhdmmalrender.h"

#include <QQuickWindow>
#include <QApplication>
#include <QCoreApplication>

OpenHDMMALRender::OpenHDMMALRender(QQuickItem *parent): QQuickItem(parent) {
    QObject::connect(this, &OpenHDMMALRender::newFrameAvailable, this, &OpenHDMMALRender::onNewVideoContentReceived, Qt::QueuedConnection);
}

void OpenHDMMALRender::paintFrame(uint8_t *buffer_data, size_t buffer_length) {
    if (buffer_length < 1024) {
        return;
    }

    QSize s = m_format.frameSize();
    auto stride = s.width();

    QVideoFrame f(buffer_length, s, stride, QVideoFrame::PixelFormat::Format_YUV420P);
    f.map(QAbstractVideoBuffer::MapMode::WriteOnly);
    memcpy(f.bits(), buffer_data, buffer_length);
    f.unmap();

    emit newFrameAvailable(f);
}

OpenHDMMALRender::~OpenHDMMALRender() {

}

void OpenHDMMALRender::setVideoSurface(QAbstractVideoSurface *surface) {
    if (m_surface && m_surface != surface && m_surface->isActive()) {
        m_surface->stop();
    }

    m_surface = surface;
}

void OpenHDMMALRender::setFormat(int width, int heigth, QVideoFrame::PixelFormat i_format) {
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

void OpenHDMMALRender::onNewVideoContentReceived(const QVideoFrame &frame) {
    if (m_surface) {
        m_surface->present(frame);
    }
}

#endif
