#ifndef GLHELP_H
#define GLHELP_H

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <cassert>

/// Some gl extensions that don't seem to be part of raspberry gl. 
/// I think you could get these from other places like GLAD or libepoxy.
///
EGLImageKHR eglCreateImageKHR(EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, const EGLint *attrib_list) __attribute__((weak)); // May not be in libEGL symbol table, resolve manually :(
EGLImageKHR eglCreateImageKHR(EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, const EGLint *attrib_list)
{
	static PFNEGLCREATEIMAGEKHRPROC createImageProc = 0;
	if(!createImageProc) {
		createImageProc = (PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");
		assert(createImageProc);
	}
	return createImageProc(dpy, ctx, target, buffer, attrib_list);
}

EGLBoolean eglDestroyImageKHR(EGLDisplay dpy, EGLImageKHR image) __attribute__((weak)); // May not be in libEGL symbol table, resolve manually :(
EGLBoolean eglDestroyImageKHR(EGLDisplay dpy, EGLImageKHR image)
{
	static PFNEGLDESTROYIMAGEKHRPROC destroyImageProc = 0;
	if(!destroyImageProc) {
		destroyImageProc = (PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");
	  	assert(destroyImageProc);
	}
	return destroyImageProc(dpy, image);
}


void glEGLImageTargetTexture2DOES(GLenum target, GLeglImageOES image) __attribute__((weak)); // May not be in libEGL symbol table, resolve manually :(
void glEGLImageTargetTexture2DOES(GLenum target, GLeglImageOES image)
{
	static PFNGLEGLIMAGETARGETTEXTURE2DOESPROC imageTargetTexture2DOES = 0;
	if(!imageTargetTexture2DOES) {
		imageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
		assert(imageTargetTexture2DOES);
	}
	imageTargetTexture2DOES(target, image);
}
/// END Gl Extensions --------------------------------------------------




#endif
