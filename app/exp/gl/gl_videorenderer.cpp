//
// Created by consti10 on 15.09.22.
//

#include "gl_videorenderer.h"
#include "color_helper.h"
#include <chrono>

static EGLint texgen_attrs[] = {
	EGL_DMA_BUF_PLANE0_FD_EXT,
	EGL_DMA_BUF_PLANE0_OFFSET_EXT,
	EGL_DMA_BUF_PLANE0_PITCH_EXT,
	EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT,
	EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT,
	EGL_DMA_BUF_PLANE1_FD_EXT,
	EGL_DMA_BUF_PLANE1_OFFSET_EXT,
	EGL_DMA_BUF_PLANE1_PITCH_EXT,
	EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT,
	EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT,
	EGL_DMA_BUF_PLANE2_FD_EXT,
	EGL_DMA_BUF_PLANE2_OFFSET_EXT,
	EGL_DMA_BUF_PLANE2_PITCH_EXT,
	EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT,
	EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT,
};

static void create_rgba_texture(GLuint& tex_id,uint32_t color_rgba){
  assert(tex_id==0);
  glGenTextures(1,&tex_id);
  assert(tex_id>=0);
  glBindTexture(GL_TEXTURE_2D, tex_id);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  const int width=1280;
  const int height=720;
  uint8_t pixels[4*width*height];
  fillFrame(pixels,width,height,width*4, color_rgba);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  glBindTexture(GL_TEXTURE_2D,0);
}

void GL_VideoRenderer::init_gl() {
  create_rgba_texture(texture_rgb_green, create_pixel_rgba(0,255,0,255));
  create_rgba_texture(texture_rgb_blue, create_pixel_rgba(0,0,255,255));
  gl_shaders=std::make_unique<GL_shaders>();
  gl_shaders->initialize();
}

// https://stackoverflow.com/questions/9413845/ffmpeg-avframe-to-opengl-texture-without-yuv-to-rgb-soft-conversion
// https://bugfreeblog.duckdns.org/2022/01/yuv420p-opengl-shader-conversion.html
// https://stackoverflow.com/questions/30191911/is-it-possible-to-draw-yuv422-and-yuv420-texture-using-opengl
void GL_VideoRenderer::update_texture_yuv420p(AVFrame* frame) {
  assert(frame);
  assert(frame->format==AV_PIX_FMT_YUV420P);
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
  std::cout<<"Colorspace:"<<av_color_space_name(frame->colorspace)<<"\n";
  av_frame_free(&frame);
  GL_shaders::checkGlError("upload YUV420P");
}

void GL_VideoRenderer::update_texture_cuda(AVFrame *frame) {
#ifdef X_HAS_LIB_CUDA
  assert(frame);
  assert(frame->format==AV_PIX_FMT_CUDA);
  MLOGD<<"update_egl_texture_cuda\n";
  // We can now also give the frame back to av, since we are updating to a new one.
  /*if(cuda_frametexture.av_frame!= nullptr){
	av_frame_free(&cuda_frametexture.av_frame);
  }
  cuda_frametexture.av_frame=frame;*/
  if(m_cuda_gl_interop_helper== nullptr){
	AVHWDeviceContext* tmp=((AVHWFramesContext*)frame->hw_frames_ctx->data)->device_ctx;
	AVCUDADeviceContext* avcuda_device_context=(AVCUDADeviceContext*)tmp->hwctx;
	assert(avcuda_device_context);
	m_cuda_gl_interop_helper = std::make_unique<CUDAGLInteropHelper>(avcuda_device_context);
  }
  bool fresh=false;
  if(cuda_frametexture.textures[0]==0){
	std::cout<<"Creating cuda textures\n";
	glGenTextures(2, cuda_frametexture.textures);
	fresh= true;
  }
  if(fresh){
	for(int i=0;i<2;i++){
	  glBindTexture(GL_TEXTURE_2D,cuda_frametexture.textures[i]);
	  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	  // The first plane (Y) is full width and therefore needs 8 bits * width * height
	  // The second plane is U,V interleaved and therefre needs 8 bits * width * height, too.
	  glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, frame->width,frame->height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, nullptr);
	  glBindTexture(GL_TEXTURE_2D,0);
	}
  }
  if(fresh){
	m_cuda_gl_interop_helper->registerTextures(cuda_frametexture.textures[0],cuda_frametexture.textures[1]);
  }
  Chronometer cuda_memcpy_time{"CUDA memcpy"};
  cuda_memcpy_time.start();
  if(m_cuda_gl_interop_helper->copyCudaFrameToTextures(frame)){
	cuda_frametexture.has_valid_image= true;
  }else{
	cuda_frametexture.has_valid_image=false;
  }
  cuda_memcpy_time.stop();
  // I don't think we can measure CUDA memcpy time
  //MLOGD<<"CUDA memcpy:"<<cuda_memcpy_time.getAvgReadable()<<"\n";
  av_frame_free(&frame);
#else
  std::cerr<<"Compile with CUDA\n";
  av_frame_free(&frame);
#endif
}

// Also https://code.videolan.org/videolan/vlc/-/blob/master/modules/video_output/opengl/importer.c#L414-417
bool GL_VideoRenderer::update_texture_egl_external(AVFrame* frame) {
  assert(frame);
  assert(frame->format==AV_PIX_FMT_DRM_PRIME);
  EGLDisplay egl_display=eglGetCurrentDisplay();
  assert(egl_display);
  auto before=std::chrono::steady_clock::now();
  // We can now also give the frame back to av, since we are updating to a new one.
  if(egl_frame_texture.av_frame!= nullptr){
	av_frame_free(&egl_frame_texture.av_frame);
  }
  egl_frame_texture.av_frame=frame;
  const AVDRMFrameDescriptor *desc = (AVDRMFrameDescriptor*)frame->data[0];
  // Writing all the EGL attribs - I just copied and pasted it, and it works.
  EGLint attribs[50];
  EGLint * a = attribs;
  const EGLint * b = texgen_attrs;
  *a++ = EGL_WIDTH;
  *a++ = x_av_frame_cropped_width(frame);
  *a++ = EGL_HEIGHT;
  *a++ = x_av_frame_cropped_height(frame);
  *a++ = EGL_LINUX_DRM_FOURCC_EXT;
  *a++ = desc->layers[0].format;
  int i, j;
  for (i = 0; i < desc->nb_layers; ++i) {
	for (j = 0; j < desc->layers[i].nb_planes; ++j) {
	  const AVDRMPlaneDescriptor * const p = desc->layers[i].planes + j;
	  const AVDRMObjectDescriptor * const obj = desc->objects + p->object_index;
	  *a++ = *b++;
	  *a++ = obj->fd;
	  *a++ = *b++;
	  *a++ = p->offset;
	  *a++ = *b++;
	  *a++ = p->pitch;
	  if (obj->format_modifier == 0) {
		b += 2;
	  }
	  else {
		*a++ = *b++;
		*a++ = (EGLint)(obj->format_modifier & 0xFFFFFFFF);
		*a++ = *b++;
		*a++ = (EGLint)(obj->format_modifier >> 32);
	  }
	}
  }
  *a = EGL_NONE;
  const EGLImage image = eglCreateImageKHR(egl_display,
										   EGL_NO_CONTEXT,
										   EGL_LINUX_DMA_BUF_EXT,
										   NULL, attribs);
  if (!image) {
	printf("Failed to create EGLImage %s\n", strerror(errno));
	egl_frame_texture.has_valid_image= false;
	std::cout<<all_av_hwframe_transfer_formats(frame->hw_frames_ctx);
	return false;
  }
  // Note that we do not have to delete and generate the texture (ID) every time we update the egl image backing.
  if(egl_frame_texture.texture==0){
	glGenTextures(1, &egl_frame_texture.texture);
  }
  glEnable(GL_TEXTURE_EXTERNAL_OES);
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, egl_frame_texture.texture);
  glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES, image);
  // I do not know exactly how that works, but we seem to be able to immediately delete the EGL image, as long as we don't give the frame
  // back to the decoder I assume
  eglDestroyImageKHR(egl_display, image);
  auto delta=std::chrono::steady_clock::now()-before;
  std::cout<<"Creating texture took:"<<std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()<<"ms\n";
  egl_frame_texture.has_valid_image= true;
  return true;
}

// TODO r.n we have 2 CPU copies !
//https://registry.khronos.org/OpenGL/extensions/NV/NV_vdpau_interop.txt
void GL_VideoRenderer::update_texture_vdpau(AVFrame* hw_frame) {
  assert(hw_frame);
  std::cerr<<"Update_texture_vdpau:"<<safe_av_get_pix_fmt_name((AVPixelFormat)hw_frame->format)<<"slow\n";
  std::cout<<all_av_hwframe_transfer_formats(hw_frame->hw_frames_ctx);
  AVFrame* sw_frame=av_frame_alloc();
  assert(sw_frame);
  sw_frame->format=AV_PIX_FMT_YUV420P;
  if (av_hwframe_transfer_data(sw_frame, hw_frame, 0) !=0) {
	fprintf(stderr, "Error transferring the data to system memory\n");
	av_frame_free(&sw_frame);
	av_frame_free(&hw_frame);
	return;
  }
  update_texture_yuv420p(sw_frame);
  //av_frame_free(&sw_frame);
  av_frame_free(&hw_frame);
}

// "Consumes" the given hw_frame (makes sure it is freed at the apropriate time / the previous one
// is freed when updating to a new one.
void GL_VideoRenderer::update_texture_gl(AVFrame *frame) {
  if(frame->format == AV_PIX_FMT_DRM_PRIME){
	std::cout<<"update_texture_drm_prime\n";
	update_texture_egl_external(frame);
  }else if(frame->format==AV_PIX_FMT_CUDA){
	std::cout<<"update_texture_cuda\n";
	update_texture_cuda(frame);
  }else if(frame->format==AV_PIX_FMT_YUV420P){
	std::cout<<"update_texture_yuv420p\n";
	update_texture_yuv420p(frame);
  }else if(frame->format==AV_PIX_FMT_VDPAU){
	std::cout<<"update_texture_vdpau\n";
	update_texture_vdpau(frame);
  }
  else{
	std::cerr << "Unimplemented to texture:" << safe_av_get_pix_fmt_name((AVPixelFormat)frame->format) << "\n";
	std::cout<<all_av_hwframe_transfer_formats(frame->hw_frames_ctx);
	av_frame_free(&frame);
  }
}

void GL_VideoRenderer::draw_texture_gl() {
  if(egl_frame_texture.has_valid_image){
	gl_shaders->draw_egl(egl_frame_texture.texture);
  }else if(cuda_frametexture.has_valid_image) {
	gl_shaders->draw_NV12(cuda_frametexture.textures[0], cuda_frametexture.textures[1]);
  }else if(yuv_420_p_sw_frame_texture.has_valid_image){
	gl_shaders->draw_YUV420P(yuv_420_p_sw_frame_texture.textures[0],
							 yuv_420_p_sw_frame_texture.textures[1],
							 yuv_420_p_sw_frame_texture.textures[2]);
  }
  else{
	// no valid video texture yet, alternating draw the rgb textures.
	const auto rgb_texture=frameCount % 2==0? texture_rgb_blue:texture_rgb_green;
	gl_shaders->draw_rgb(rgb_texture);
	frameCount++;
  }
}
