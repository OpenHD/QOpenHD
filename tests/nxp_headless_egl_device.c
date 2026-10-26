/* Test-only adapter for Weston's Mesa headless platform request. The Vivante
 * driver has EGLDevice + surfaceless contexts, but no Mesa surfaceless platform.
 * Never use this library with a real DRM/HDMI compositor. */
#define _GNU_SOURCE
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

static __eglMustCastToProperFunctionPointerType (*real_proc)(const char*);
static void* egl_library;
static void load_proc(void) {
    if (!egl_library) egl_library = dlopen("libEGL.so.1", RTLD_NOW | RTLD_LOCAL);
    if (!real_proc) real_proc = dlsym(egl_library, "eglGetProcAddress");
}
static EGLDisplay device_display(EGLenum platform, void* native, const EGLint* attrs) {
    load_proc();
    PFNEGLGETPLATFORMDISPLAYEXTPROC get_display = (void*)real_proc("eglGetPlatformDisplayEXT");
    if (platform == 0x31DD && native == NULL) {
        PFNEGLQUERYDEVICESEXTPROC query = (void*)real_proc("eglQueryDevicesEXT");
        EGLDeviceEXT device; EGLint count = 0;
        if (query && query(1, &device, &count) && count) {
            fprintf(stderr, "NXP headless test: using EGLDevice for offscreen compositor\n");
            return get_display(EGL_PLATFORM_DEVICE_EXT, device, attrs);
        }
    }
    return get_display(platform, native, attrs);
}
const char* eglQueryString(EGLDisplay display, EGLint name) {
    static const char* (*query_string)(EGLDisplay, EGLint);
    load_proc();
    if (!query_string) query_string = dlsym(egl_library, "eglQueryString");
    const char* result = query_string(display, name);
    if (display == EGL_NO_DISPLAY && name == EGL_EXTENSIONS && result) {
        static char extensions[8192];
        snprintf(extensions, sizeof(extensions), "%s EGL_MESA_platform_surfaceless", result);
        return extensions;
    }
    return result;
}
__eglMustCastToProperFunctionPointerType eglGetProcAddress(const char* name) {
    load_proc();
    if (!strcmp(name, "eglGetPlatformDisplayEXT")) return (__eglMustCastToProperFunctionPointerType)device_display;
    return real_proc(name);
}
