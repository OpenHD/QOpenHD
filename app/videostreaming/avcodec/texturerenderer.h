#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <memory>
#include <chrono>
#include <deque>
#include <mutex>
#include <QRect>
#include <QVector3D>

#include "gl/gl_videorenderer.h"

#include "common/TimeHelper.hpp"

class TextureRenderer : public QObject
{
    Q_OBJECT
public:
    // DIRTY, FIXME
    static TextureRenderer& instance();

    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setSecondaryViewport(const QRect &viewport);
    void setPreviewGain(const QVector3D& gain) { m_preview_gain={{gain.x(),gain.y(),gain.z()}}; }
    // create and link the shaders
    void initGL(QQuickWindow *window);
    // draw function
    // @param window: just needed to call the begin/end-externalCommands on it
    void paint(QQuickWindow *window,int rotation_degree);
    // adds a new frame to be picked up by the GL thread
    int queue_new_frame_for_display(AVFrame * src_frame, bool primaryStream=true);
    // Discard old frames now and release the GL texture on the render thread.
    void clear_video_texture(bool primaryStream);
private:
    std::array<float,3> m_preview_gain{{1.0f,1.0f,1.0f}};
    QSize m_viewportSize;
    QRect m_secondaryViewport;
    std::mutex m_secondary_viewport_mutex;
    int m_index=0;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    //
    std::unique_ptr<GL_VideoRenderer> gl_video_renderer=nullptr;
    std::unique_ptr<GL_VideoRenderer> m_secondary_gl_video_renderer=nullptr;
    //
    bool initialized=false;
    int renderCount=0;
private:
    struct FrameDeleter {
        void operator()(AVFrame* frame) const { av_frame_free(&frame); }
    };
    using QueuedFrame = std::unique_ptr<AVFrame, FrameDeleter>;
    std::mutex primary_frames_mutex;
    std::deque<QueuedFrame> primary_frames;
    std::mutex secondary_frames_mutex;
    std::deque<QueuedFrame> secondary_frames;
    bool primary_texture_needs_clear=false;
    bool secondary_texture_needs_clear=false;
    AVFrame* take_next_decoded_frame(bool primaryStream, bool& clear_texture);
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
};

#endif // TEXTURERENDERER_H
