#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLTexture>
#include <memory>
#include <chrono>
#include <mutex>

#include "gl_shaders.h"

#include "helper_include_av.h"

struct YUV420PSwFrameTexture{
  // Since we copy the data, we do not need to keep the av frame around
  //AVFrame* av_frame=nullptr;
  GLuint textures[3]={0,0,0};
  bool has_valid_image=false;
  // Allows us to use glTextSubImaage instead
  int last_width=-1;
  int last_height=-1;
};

class TextureRenderer : public QObject
{
    Q_OBJECT
public:

    static TextureRenderer& instance(){
        static TextureRenderer renderer{};
        return renderer;
    }

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
    std::unique_ptr<GL_shaders> gl_shaders=nullptr;
    //
    bool initialized=false;
    int renderCount=0;
    //
private:
    YUV420PSwFrameTexture yuv_420_p_sw_frame_texture{};
    void update_texture_yuv420p(AVFrame* frame);
private:
    std::mutex latest_frame_mutex;
    AVFrame* m_latest_frame=nullptr;
    struct DisplayStats{
       int n_frames_rendered=0;
       int n_frames_dropped=0;
       // Delay between frame was given to the egl render <-> we uploaded it to the texture (if not dropped)
       //AvgCalculator delay_until_uploaded{"Delay until uploaded"};
       // Delay between frame was given to the egl renderer <-> swap operation returned (it is handed over to the hw composer)
       //AvgCalculator delay_until_swapped{"Delay until swapped"};
     };
     DisplayStats m_display_stats{};
     // Fetch the latest, decoded frame. Thread-safe.
     // This method can return null (in this case no new frame is available)
     // or return the AVFrame* - in which case the caller is then responsible to free the frame
     AVFrame* fetch_latest_decoded_frame();
     // always called with the OpenGL context bound.
     void update_texture_gl(AVFrame* frame);
};

#endif // TEXTURERENDERER_H
