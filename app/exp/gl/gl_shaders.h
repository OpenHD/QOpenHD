//
// Created by consti10 on 08.09.22.
//

#ifndef HELLO_DRMPRIME__GL_SHADERS_H_
#define HELLO_DRMPRIME__GL_SHADERS_H_

extern "C" {
#include <GLES2/gl2.h>
#include "glhelp.h"
}
#include <string>

// Holds multiple GL programs that render different types of (Video) textures
// All textures fill up the full gl viewport, adjust it accordingly to preserve video ratio.
// Note that the dependency on ffmpeg / av_codec* is avoidable here and therefore please keep it this way
// (Ony depend on OpenGL (ES) )
class GL_shaders {
 private:
  // Single RGB(A) texture
  struct RGBAShader{
	GLuint program=0;
	GLint pos=-1;
	GLint uvs=-1;
	GLint sampler=-1;
  };
  // Single EGL external texture (We do not have to write our own YUV conversion(s), egl does it for us.
  // Any platform where we can get the (HW) - decoded frame to EGL (e.g. rpi) this is the easiest and best way.
  struct EGLShader{
	GLuint program=0;
	GLint pos=-1;
	GLint uvs=-1;
  };
  // NV12
  // 2 separate planes (textures) : Y and U,V
  struct NV12Shader{
	GLuint program=0;
	GLint pos=-1;
	GLint uvs=-1;
	GLint s_texture_y=-1;
	GLint s_texture_uv=-1;
  };
  // YUV 420P (As defined in AV_PIX_FMT_YUV420P)
  // Y,U,V are in 3 separate planes (textures)
  struct YUV420PShader{
	GLuint program=0;
	GLint pos=-1;
	GLint uvs=-1;
	GLint s_texture_y=-1;
	GLint s_texture_u=-1;
	GLint s_texture_v=-1;
  };
  EGLShader egl_shader;
  RGBAShader rgba_shader;
  YUV420PShader yuv_420P_shader;
  NV12Shader nv12_shader;
  // All shaders use the same VBO for vertex / uv coordinates
  GLuint vbo=0;
  void beforeDrawVboSetup(GLint pos,GLint uvs) const;
  static void afterDrawVboCleanup(GLint pos,GLint uvs);
 public:
  static void checkGlError(const std::string& caller);
  // needs to be called on the OpenGL thread and before the first use of any draw_XXX calls
  void initialize();
  // "normal" RGB(A) texture
  void draw_rgb(GLuint texture);
  // gl oes egl external texture
  void draw_egl(GLuint texture);
  // each plane (Y,U,V) has its own texture
  void draw_YUV420P(GLuint textureY,GLuint textureU,GLuint textureV);
  // Y has its own texture, UV are interleaved in the same texture.
  void draw_NV12(GLuint textureY,GLuint textureUV);
  //
  static void debug_set_swap_interval(int interval);
};

#endif //HELLO_DRMPRIME__GL_SHADERS_H_
