#include "texturerenderer.h"
#include "avcodec_helper.hpp"

#include <cmath>

struct MGLViewptort{
    int x,y,width,height;
};

static MGLViewptort calculate_viewport_video_fullscreen(int surface_width,int surface_height,int texture_width,int texture_height){
    MGLViewptort ret;
    // We setup the viewport surch that we preserve the original ratio of the teture ( width / height).
    // One could also just transform the vertex coordinates, but setting the vieport accordingly is easier.
    const double surface_aspect_ratio=(double)surface_width / (double)surface_height;
    const double texture_aspect_ratio=(double)texture_width / (double)texture_height;
    //qDebug()<<"Surface "<< surface_width<<"x"<<surface_height<<" ratio:"<<surface_aspect_ratio;
    //qDebug()<<"Texture "<<texture_width<<"x"<<texture_height<<" ratio:"<<texture_aspect_ratio;
    int x_viewport_width=0;
    int x_viewport_height=0;
    if(surface_aspect_ratio>texture_aspect_ratio){
        // we use the full height, and andjust the width.
        // Example case: 16/9 (1.7) surface  and 4:3 (1.3) (video) texture
        x_viewport_height=surface_height;
        auto tmp= surface_height * texture_aspect_ratio;
        x_viewport_width=std::lround(tmp);
        int x_offset=(surface_width-x_viewport_width)/2;
        //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
        ret.x=x_offset;
        ret.y=0;
        ret.width=x_viewport_width;
        ret.height=x_viewport_height;
    }else{
         // we use the full width, and adjust the height
        x_viewport_width=surface_width;
        auto tmp= surface_width * (1.0/texture_aspect_ratio);
        x_viewport_height=std::lround(tmp);
        int y_offset=(surface_height-x_viewport_height)/2;
        //qDebug()<<"Viewport <<"<<x_viewport_width<<"x"<<x_viewport_height;
        ret.x=0;
        ret.y=y_offset;
        ret.width=x_viewport_width;
        ret.height=x_viewport_height;
    }
    return ret;
}


TextureRenderer &TextureRenderer::instance(){
    static TextureRenderer renderer{};
    return renderer;
}

void TextureRenderer::initGL()
{
    if (!initialized) {
        initialized=true;
        QSGRendererInterface *rif = m_window->rendererInterface();
        Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL);

        //initializeOpenGLFunctions();
        gl_video_renderer=std::make_unique<GL_VideoRenderer>();
        qDebug()<<gl_video_renderer->debug_info().c_str();
        gl_video_renderer->init_gl();
    }
}

//! [4] //! [5]
void TextureRenderer::paint()
{
    const auto delta=std::chrono::steady_clock::now()-last_frame;
    last_frame=std::chrono::steady_clock::now();
    const auto frame_time_us=std::chrono::duration_cast<std::chrono::microseconds>(delta).count();
    const float frame_time_ms=((float)frame_time_us)/1000.0f;
    //qDebug()<<" TextureRenderer::paint() frame time:"<<frame_time_ms<<"ms";
    renderCount++;

   // Play nice with the RHI. Not strictly needed when the scenegraph uses
   // OpenGL directly.
    // Consti10: comp error, seems to work without, too
   m_window->beginExternalCommands();
   //glClear(GL_COLOR_BUFFER_BIT |GL_DEPTH_BUFFER_BIT| GL_STENCIL_BUFFER_BIT);
   AVFrame* new_frame=fetch_latest_decoded_frame();
   if(new_frame!= nullptr){
     // update the texture with this frame
     gl_video_renderer->update_texture_gl(new_frame);
   }
   const auto video_tex_width=gl_video_renderer->curr_video_width;
   const auto video_tex_height=gl_video_renderer->curr_video_height;
   if(video_tex_width >0 && video_tex_height>0){
       const auto viewport=calculate_viewport_video_fullscreen(m_viewportSize.width(), m_viewportSize.height(),video_tex_width,video_tex_height);
       glViewport(viewport.x,viewport.y,viewport.width,viewport.height);
   }
   glDisable(GL_DEPTH_TEST);

   gl_video_renderer->draw_texture_gl();
   // make sure we leave how we started / such that Qt rendering works normally
   glEnable(GL_DEPTH_TEST);
   glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    m_window->endExternalCommands();
}

int TextureRenderer::queue_new_frame_for_display(AVFrame *src_frame)
{
    assert(src_frame);
    //std::cout<<"DRMPrimeOut::drmprime_out_display "<<src_frame->width<<"x"<<src_frame->height<<"\n";
    if ((src_frame->flags & AV_FRAME_FLAG_CORRUPT) != 0) {
      fprintf(stderr, "Discard corrupt frame: fmt=%d, ts=%" PRId64 "\n", src_frame->format, src_frame->pts);
      return 0;
    }
    latest_frame_mutex.lock();
    // We drop a frame that has (not yet) been consumed by the render thread to whatever is the newest available.
    if(m_latest_frame!= nullptr){
      av_frame_free(&m_latest_frame);
      qDebug()<<"Dropping frame";
      //m_display_stats.n_frames_dropped++;
    }
    AVFrame *frame=frame = av_frame_alloc();
    assert(frame);
    if(av_frame_ref(frame, src_frame)!=0){
      fprintf(stderr, "av_frame_ref error\n");
      av_frame_free(&frame);
      // don't forget to give up the lock
      latest_frame_mutex.unlock();
      return AVERROR(EINVAL);
    }
    m_latest_frame=frame;
    latest_frame_mutex.unlock();
    return 0;
}


AVFrame *TextureRenderer::fetch_latest_decoded_frame()
{
    std::lock_guard<std::mutex> lock(latest_frame_mutex);
    if(m_latest_frame!= nullptr) {
      // Make a copy and write nullptr to the thread-shared variable such that
      // it is not freed by the providing thread.
      AVFrame* new_frame = m_latest_frame;
      m_latest_frame = nullptr;
      return new_frame;
    }
    return nullptr;
}




