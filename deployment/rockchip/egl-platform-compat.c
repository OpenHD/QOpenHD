/* Bullseye Qt Wayland uses EGL 1.5 platform entry points. The matching g6p0
 * Mali BSP implements EGL_EXT_platform_base instead. Adapt only these entry
 * points; all rendering and DMA-BUF imports remain in the vendor driver. */
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <limits.h>
#include <stddef.h>

static int attributes(const EGLAttrib* input, EGLint* output, size_t capacity) {
    if (!input) { output[0] = EGL_NONE; return 1; }
    for (size_t i = 0; i + 2 < capacity; i += 2) {
        if (input[i] == EGL_NONE) { output[i] = EGL_NONE; return 1; }
        if (input[i] < INT_MIN || input[i] > INT_MAX || input[i+1] < INT_MIN || input[i+1] > INT_MAX) return 0;
        output[i] = input[i]; output[i+1] = input[i+1];
    }
    return 0;
}
EGLDisplay eglGetPlatformDisplay(EGLenum platform, void* native, const EGLAttrib* attrs) {
    PFNEGLGETPLATFORMDISPLAYEXTPROC get = (void*)eglGetProcAddress("eglGetPlatformDisplayEXT");
    EGLint converted[129];
    if (!get || !attributes(attrs, converted, 129)) return EGL_NO_DISPLAY;
    return get(platform, native, attrs ? converted : NULL);
}
EGLSurface eglCreatePlatformWindowSurface(EGLDisplay display, EGLConfig config, void* native, const EGLAttrib* attrs) {
    PFNEGLCREATEPLATFORMWINDOWSURFACEEXTPROC create = (void*)eglGetProcAddress("eglCreatePlatformWindowSurfaceEXT");
    EGLint converted[129];
    if (!create || !attributes(attrs, converted, 129)) return EGL_NO_SURFACE;
    return create(display, config, native, attrs ? converted : NULL);
}
