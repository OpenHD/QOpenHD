#include "texturerenderer.h"
#include "avcodec_helper.hpp"

#include <cmath>
#include <qsettings.h>
#include <algorithm>

#include "decodingstatistcs.h"
#include "../vscommon/QOpenHDVideoHelper.hpp"
#include "../vscommon/video_ratio_helper.hpp"

static bool get_dev_draw_alternating_rgb_dummy_frames(){
    QSettings settings;
    return settings.value("dev_draw_alternating_rgb_dummy_frames", false).toBool();
}


TextureRenderer &TextureRenderer::instance(){
    static TextureRenderer renderer{};
    return renderer;
}

void TextureRenderer::setSecondaryViewport(const QRect &viewport)
{
    std::lock_guard<std::mutex> lock(m_secondary_viewport_mutex);
    m_secondaryViewport=viewport;
}

void TextureRenderer::initGL(QQuickWindow *window)
{
    if (!initialized) {
        initialized=true;
        QSGRendererInterface *rif = window->rendererInterface();
        Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL);

        gl_video_renderer=std::make_unique<GL_VideoRenderer>();
        qDebug()<<gl_video_renderer->debug_info().c_str();
        gl_video_renderer->init_gl();
        m_secondary_gl_video_renderer=std::make_unique<GL_VideoRenderer>();
        m_secondary_gl_video_renderer->init_gl();
        dev_draw_alternating_rgb_dummy_frames=get_dev_draw_alternating_rgb_dummy_frames();
    }
}

void TextureRenderer::paint(QQuickWindow *window,int rotation_degree)
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
   if(window){
       window->beginExternalCommands();
   }
   if(m_clear_all_video_textures_next_frame){
       remove_queued_frame_if_avalable(true);
       gl_video_renderer->clean_video_textures_gl();
       DecodingStatistcs::instance().set_n_renderer_dropped_frames(-1);
       DecodingStatistcs::instance().set_n_rendered_frames(-1);
       DecodingStatistcs::instance().set_decode_and_render_time("-1");
       m_clear_all_video_textures_next_frame=false;
   }
   //glClear(GL_COLOR_BUFFER_BIT |GL_DEPTH_BUFFER_BIT| GL_STENCIL_BUFFER_BIT);
   AVFrame* new_frame=take_next_decoded_frame();
   if(new_frame!= nullptr){
     // Note : the update might free the frame, so we gotta store the timestamp before !
     const auto frame_pts=new_frame->pts;
     // update the texture with this frame
     gl_video_renderer->update_texture_gl(new_frame);
     m_display_stats.n_frames_rendered++;
     DecodingStatistcs::instance().set_n_rendered_frames(m_display_stats.n_frames_rendered);
     const auto now_us=getTimeUs();
     const auto delay_us=now_us-frame_pts;
     m_display_stats.decode_and_render.add(std::chrono::microseconds(delay_us));
     if(m_display_stats.decode_and_render.time_since_last_log()>std::chrono::seconds(3)){
         DecodingStatistcs::instance().set_decode_and_render_time(m_display_stats.decode_and_render.getAvgReadable().c_str());
         m_display_stats.decode_and_render.set_last_log();
         m_display_stats.decode_and_render.reset();
     }
   }
   auto video_tex_width=gl_video_renderer->curr_video_width;
   auto video_tex_height=gl_video_renderer->curr_video_height;
   if(rotation_degree==90 || rotation_degree==270){
     // just swap them around when rotated to get the right viewport
     std::swap(video_tex_width,video_tex_height);
   }
   if(video_tex_width >0 && video_tex_height>0){
       const auto viewport=helper::ratio::calculate_viewport(m_viewportSize.width(), m_viewportSize.height(),video_tex_width,video_tex_height,QOpenHDVideoHelper::get_primary_video_scale_to_fit());
       glViewport(viewport.x,viewport.y,viewport.width,viewport.height);
   }
   glDisable(GL_DEPTH_TEST);

   gl_video_renderer->set_preview_gain(m_preview_gain);
   gl_video_renderer->draw_texture_gl(dev_draw_alternating_rgb_dummy_frames,rotation_degree);

   // Composite secondary video in the same external-command block. Keeping one
   // scene-graph hook avoids the GL-state corruption caused by two renderers.
   QRect secondary_viewport;
   {
       std::lock_guard<std::mutex> lock(m_secondary_viewport_mutex);
       secondary_viewport=m_secondaryViewport;
   }
   if(secondary_viewport.width()>0 && secondary_viewport.height()>0){
       AVFrame* secondary_frame=take_next_decoded_frame(false);
       if(secondary_frame!=nullptr){
           m_secondary_gl_video_renderer->update_texture_gl(secondary_frame);
       }
       auto secondary_width=m_secondary_gl_video_renderer->curr_video_width;
       auto secondary_height=m_secondary_gl_video_renderer->curr_video_height;
       if(rotation_degree==90 || rotation_degree==270){
           std::swap(secondary_width,secondary_height);
       }
       if(secondary_width>0 && secondary_height>0){
           const auto relative_viewport=helper::ratio::calculate_viewport(
               secondary_viewport.width(),secondary_viewport.height(),
               secondary_width,secondary_height,false);
           glViewport(secondary_viewport.x()+relative_viewport.x,
                      secondary_viewport.y()+relative_viewport.y,
                      relative_viewport.width,relative_viewport.height);
           m_secondary_gl_video_renderer->draw_texture_gl(dev_draw_alternating_rgb_dummy_frames,rotation_degree);
       }
   }
   // make sure we leave how we started / such that Qt rendering works normally
   glEnable(GL_DEPTH_TEST);
   glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

   if(window){
       window->endExternalCommands();
   }
}

int TextureRenderer::queue_new_frame_for_display(AVFrame* src_frame, bool primaryStream)
{
    QueuedFrame frame(av_frame_clone(src_frame));
    if (!frame) return AVERROR(ENOMEM);

    // A second desktop slot absorbs two frames arriving in one display interval.
    // Keep the queue bounded so a slow display does not accumulate latency.
#ifdef QOPENHD_DESKTOP_HW_DECODE
    constexpr std::size_t capacity = 2;
#else
    constexpr std::size_t capacity = 1;
#endif
    auto& mutex = primaryStream ? primary_frames_mutex : secondary_frames_mutex;
    auto& frames = primaryStream ? primary_frames : secondary_frames;
    std::lock_guard<std::mutex> lock(mutex);
    if (frames.size() == capacity) {
        frames.pop_front();
        if (primaryStream) {
            DecodingStatistcs::instance().set_n_renderer_dropped_frames(++m_display_stats.n_frames_dropped);
        }
    }
    frames.push_back(std::move(frame));
    return 0;
}

void TextureRenderer::remove_queued_frame_if_avalable(bool primaryStream)
{
    auto& mutex = primaryStream ? primary_frames_mutex : secondary_frames_mutex;
    auto& frames = primaryStream ? primary_frames : secondary_frames;
    std::lock_guard<std::mutex> lock(mutex);
    frames.clear();
}

AVFrame* TextureRenderer::take_next_decoded_frame(bool primaryStream)
{
    auto& mutex = primaryStream ? primary_frames_mutex : secondary_frames_mutex;
    auto& frames = primaryStream ? primary_frames : secondary_frames;
    std::lock_guard<std::mutex> lock(mutex);
    if (frames.empty()) return nullptr;

    auto frame = std::move(frames.front());
    frames.pop_front();
    return frame.release();
}
