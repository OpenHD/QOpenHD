#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <memory>
#include <chrono>
#include <mutex>

#include "gl/gl_videorenderer.h"

#include "common/TimeHelper.hpp"

class TextureRenderer : public QObject
{
    Q_OBJECT
public:
    // DIRTY, FIXME
    static TextureRenderer& instance();

    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    // create and link the shaders
    void initGL(QQuickWindow *window);
    // draw function
    // @param window: just needed to call the begin/end-externalCommands on it
    void paint(QQuickWindow *window,int rotation_degree);
    // adds a new frame to be picked up by the GL thread
    int queue_new_frame_for_display(AVFrame * src_frame);
    // remoe the currently queued frame if there is one (be carefull to not forget that the
    // GL thread can pick up a queued frame at any time).
    void remove_queued_frame_if_avalable();
    // If we switch from a decode method that requires OpenGL to a decode method
    // that uses the HW composer, we need to become "transparent" again - or rather
    // not draw any video with OpenGL, which will have the same effect
    void clear_all_video_textures_next_frame(){
        m_clear_all_video_textures_next_frame=true;
    }
private:
    QSize m_viewportSize;
    int m_index=0;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    //
    std::unique_ptr<GL_VideoRenderer> gl_video_renderer=nullptr;
    //
    bool initialized=false;
    int renderCount=0;
private:
    std::mutex latest_frame_mutex;
    AVFrame* m_latest_frame=nullptr;
    AVFrame* fetch_latest_decoded_frame();
private:
    struct DisplayStats{
        int n_frames_rendered=0;
        int n_frames_dropped=0;
        // Delay between frame was given to the egl render <-> we uploaded it to the texture (if not dropped)
        //AvgCalculator delay_until_uploaded{"Delay until uploaded"};
        // Delay between frame was given to the egl renderer <-> swap operation returned (it is handed over to the hw composer)
        //AvgCalculator delay_until_swapped{"Delay until swapped"};
        AvgCalculator decode_and_render{"Decode and render"}; //Time picked up by GL Thread
      };
    DisplayStats m_display_stats;
    bool dev_draw_alternating_rgb_dummy_frames=false;
    bool m_clear_all_video_textures_next_frame=false;
};

#endif // TEXTURERENDERER_H
