//
// Created by consti10 on 15.09.22.
//

#ifndef HELLO_DRMPRIME__GL_VIDEORENDERER_H_
#define HELLO_DRMPRIME__GL_VIDEORENDERER_H_

#include <memory>
#include "ffmpeg_workaround_api_version.hpp"
#include "gl_shaders.h"

struct EGLFrameTexture{
  // I think we need to keep the av frame reference around as long as we use the generated egl texture in opengl.
  AVFrame* av_frame= nullptr;
  // In contrast to "hwdectogl", created once, then re-used with each new egl image.
  // needs to be bound to the "EGL external image" target
  GLuint texture=0;
  // set to true if the texture currently has a egl image backing it.
  bool has_valid_image=false;
};

struct CUDAFrameTexture{
  // Since we memcpy with cuda, we do not need to keep the av_frame around
  //AVFrame* av_frame=nullptr;
  GLuint textures[2]={0,0};
  bool has_valid_image=false;
};

struct YUV420PSwFrameTexture{
  // Since we copy the data, we do not need to keep the av frame around
  //AVFrame* av_frame=nullptr;
  GLuint textures[3]={0,0,0};
  bool has_valid_image=false;
  // Allows us t use glTextSubImaage instead
  int last_width=-1;
  int last_height=-1;
};

class GL_VideoRenderer {
 public:
  // always called with the OpenGL context bound.
  void init_gl();
  void update_texture_gl(AVFrame* frame);
  // draw the latest updated video texture (or the alternating colors if no video texture is set)
  void draw_texture_gl();
 private:
  // Holds shaders for common video formats / upload techniques
  // Needs to be initialized on the GL thread.
  std::unique_ptr<GL_shaders> gl_shaders=nullptr;
 private:
  bool update_texture_egl_external(AVFrame* frame);
  void update_texture_cuda(AVFrame* frame);
  void update_texture_yuv420p(AVFrame* frame);
  void update_texture_vdpau(AVFrame* frame);
#ifdef X_HAS_LIB_CUDA
  std::unique_ptr<CUDAGLInteropHelper> m_cuda_gl_interop_helper=nullptr;
#endif
 public:
  // green/ blue RGB(A) textures, for testing. Uploaded once, then never modified.
  GLuint texture_rgb_green=0;
  GLuint texture_rgb_blue=0;
  int frameCount=0;
  //
  EGLFrameTexture egl_frame_texture{};
  CUDAFrameTexture cuda_frametexture{};
  YUV420PSwFrameTexture yuv_420_p_sw_frame_texture{};
};

#endif //HELLO_DRMPRIME__GL_VIDEORENDERER_H_
