#include "texturerenderer.h"

#include <cmath>


/// negative x,y is bottom left and first vertex
//Consti10: Video was flipped horizontally (at least big buck bunny)
static const GLfloat vertices[][4][3] =
    {
        { {-1.0, -1.0, 0.0}, { 1.0, -1.0, 0.0}, {-1.0, 1.0, 0.0}, {1.0, 1.0, 0.0} }
    };
static const GLfloat uv_coords[][4][2] =
    {
        //{ {0.0, 0.0}, {1.0, 0.0}, {0.0, 1.0}, {1.0, 1.0} }
        { {1.0, 1.0}, {0.0, 1.0}, {1.0, 0.0}, {0.0, 0.0} }
    };

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
        gl_shaders=std::make_unique<GL_shaders>();
        gl_shaders->initialize();

        //
        const int test_w=1280;
        const int test_h=900;
        QImage image1{test_w,test_h, QImage::Format_RGB888};
        QImage image2{test_w,test_h, QImage::Format_RGB888};
        image1.fill(QColor(0, 255, 0));
        image2.fill(QColor(0, 0, 255));

        /*QImage image1{QString(":/resources/ic128.png")};
        image1=image1.mirrored();
        QImage image2{QString(":/resources/ic128.png")};*/

        texture1=std::make_unique<QOpenGLTexture>(image1);
        texture2=std::make_unique<QOpenGLTexture>(image2);
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
     m_display_stats.n_frames_rendered++;
     update_texture_gl(new_frame);
   }
   glDisable(GL_DEPTH_TEST);
   if(yuv_420_p_sw_frame_texture.has_valid_image){
       gl_shaders->draw_YUV420P(yuv_420_p_sw_frame_texture.textures[0],
                                yuv_420_p_sw_frame_texture.textures[1],
                                yuv_420_p_sw_frame_texture.textures[2]);
   }else{
    // r.n we just swap between 2 textures
     QOpenGLTexture *texture;
     if((renderCount/1) % 2==0){
         texture=texture1.get();
     }else{
         texture=texture2.get();
     }
      // We setup the viewport surch that we preserve the original ratio of the teture ( width / height).
      // One could also just transform the vertex coordinates, but setting the vieport accordingly is easier.
      const auto viewport=calculate_viewport_video_fullscreen(m_viewportSize.width(),m_viewportSize.height(),texture->width(),texture->height());
      glViewport(viewport.x,viewport.y,viewport.width,viewport.height);
      gl_shaders->draw_rgb(texture->textureId());
    }

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
        qDebug()<<"Dropping frame\n";
        m_display_stats.n_frames_dropped++;
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

void TextureRenderer::update_texture_yuv420p(AVFrame *frame)
{
    assert(frame);
    assert(frame->format==AV_PIX_FMT_YUV420P);
    qDebug()<<"update_texture_yuv420p\n";
    for(int i=0;i<3;i++){
      if(yuv_420_p_sw_frame_texture.textures[i]==0){
        glGenTextures(1,&yuv_420_p_sw_frame_texture.textures[i]);
        assert(yuv_420_p_sw_frame_texture.textures[i]>0);
      }
      GL_shaders::checkGlError("Xupload YUV420P");
      glBindTexture(GL_TEXTURE_2D, yuv_420_p_sw_frame_texture.textures[i]);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
      bool use_tex_sub_image= false;
      if(yuv_420_p_sw_frame_texture.last_width==frame->width &&
          yuv_420_p_sw_frame_texture.last_height==frame->height){
          //use_tex_sub_image= true;
      }else{
        yuv_420_p_sw_frame_texture.last_width=frame->width;
        yuv_420_p_sw_frame_texture.last_height=frame->height;
      }
      if(i==0){
        // Full Y plane
        if(use_tex_sub_image){
          glTexSubImage2D(GL_TEXTURE_2D,0,0,0,frame->width,frame->height,GL_LUMINANCE,GL_UNSIGNED_BYTE,frame->data[0]);
        }else{
          glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame->width, frame->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame->data[0]);
        }
      }else{
        // half size U,V planes
        if(use_tex_sub_image){
          glTexSubImage2D(GL_TEXTURE_2D, 0,0,0, frame->width/2, frame->height/2, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame->data[i]);
        } else{
          glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame->width/2, frame->height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, frame->data[i]);
        }
      }
      glBindTexture(GL_TEXTURE_2D,0);
    }
    yuv_420_p_sw_frame_texture.has_valid_image= true;
    qDebug()<<"Colorspace:"<<av_color_space_name(frame->colorspace)<<"\n";
    av_frame_free(&frame);
    GL_shaders::checkGlError("upload YUV420P");
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

void TextureRenderer::update_texture_gl(AVFrame *frame)
{
    if(frame->format == AV_PIX_FMT_DRM_PRIME){
        //EGLDisplay egl_display=eglGetCurrentDisplay();
        //update_drm_prime_to_egl_texture(&egl_display, egl_frame_texture, frame);
      }else if(frame->format==AV_PIX_FMT_CUDA){
        //update_texture_cuda(frame);
      }else if(frame->format==AV_PIX_FMT_YUV420P){
        update_texture_yuv420p(frame);
      }else if(frame->format==AV_PIX_FMT_VDPAU){
        //update_texture_vdpau(frame);
      }
      else{
        /*std::cerr << "Unimplemented to texture:" << safe_av_get_pix_fmt_name((AVPixelFormat)frame->format) << "\n";
        print_hwframe_transfer_formats(frame->hw_frames_ctx);
        av_frame_free(&frame);*/
      }
}

