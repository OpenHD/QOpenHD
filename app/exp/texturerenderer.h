#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLTexture>
#include <memory>
#include <chrono>
#include <mutex>

#include "gl/gl_videorenderer.h"

#include "helper_include_av.h"


class TextureRenderer : public QObject
{
    Q_OBJECT
public:

    static TextureRenderer& instance();

    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setWindow(QQuickWindow *window) { m_window = window; }
    // create and link the shaders
    void initGL();
    // draw function
    void paint();
    //
    int queue_new_frame_for_display(AVFrame * src_frame);

private:
    QSize m_viewportSize;
    int m_index=0;
    QQuickWindow *m_window = nullptr;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    //
    std::unique_ptr<QOpenGLTexture> texture1=nullptr;
    std::unique_ptr<QOpenGLTexture> texture2=nullptr;
    //
    std::unique_ptr<GL_VideoRenderer> gl_video_renderer=nullptr;
    //
    bool initialized=false;
    int renderCount=0;
    //
private:

private:
    std::mutex latest_frame_mutex;
    AVFrame* m_latest_frame=nullptr;
    AVFrame* fetch_latest_decoded_frame();
};

#endif // TEXTURERENDERER_H
