// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "placebo_renderer.h"

#include <QDebug>
#include <cstring>
#include <sstream>
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>

// V4L2 pixel format definitions
#include <linux/videodev2.h>

// DRM fourcc definitions (from drm_fourcc.h)
#ifndef DRM_FORMAT_NV12
#define DRM_FORMAT_NV12 0x3231564E
#endif
#ifndef DRM_FORMAT_NV21
#define DRM_FORMAT_NV21 0x3132564E
#endif
#ifndef DRM_FORMAT_YUV420
#define DRM_FORMAT_YUV420 0x32315559
#endif
#ifndef DRM_FORMAT_YVU420
#define DRM_FORMAT_YVU420 0x32315659
#endif
#ifndef DRM_FORMAT_P010
#define DRM_FORMAT_P010 0x30313050
#endif
#ifndef DRM_FORMAT_ARGB8888
#define DRM_FORMAT_ARGB8888 0x34325241
#endif
#ifndef DRM_FORMAT_XRGB8888
#define DRM_FORMAT_XRGB8888 0x34325258
#endif
#ifndef DRM_FORMAT_MOD_LINEAR
#define DRM_FORMAT_MOD_LINEAR 0ULL
#endif
#ifndef DRM_FORMAT_MOD_INVALID
#define DRM_FORMAT_MOD_INVALID ((1ULL << 56) - 1)
#endif

// Per-plane DRM formats for EGL import
#define DRM_FORMAT_R8     0x20203852
#define DRM_FORMAT_GR88   0x38385247
#define DRM_FORMAT_RG88   0x38384752
#define DRM_FORMAT_R16    0x20363152
#define DRM_FORMAT_GR1616 0x36314752

// EGL DMA-BUF extension constants
#ifndef EGL_LINUX_DMA_BUF_EXT
#define EGL_LINUX_DMA_BUF_EXT 0x3270
#endif
#ifndef EGL_LINUX_DRM_FOURCC_EXT
#define EGL_LINUX_DRM_FOURCC_EXT 0x3271
#endif
#ifndef EGL_DMA_BUF_PLANE0_FD_EXT
#define EGL_DMA_BUF_PLANE0_FD_EXT 0x3272
#endif
#ifndef EGL_DMA_BUF_PLANE0_OFFSET_EXT
#define EGL_DMA_BUF_PLANE0_OFFSET_EXT 0x3273
#endif
#ifndef EGL_DMA_BUF_PLANE0_PITCH_EXT
#define EGL_DMA_BUF_PLANE0_PITCH_EXT 0x3274
#endif
#ifndef EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT
#define EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT 0x3443
#endif
#ifndef EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT
#define EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT 0x3444
#endif
#ifndef EGL_DMA_BUF_PLANE1_FD_EXT
#define EGL_DMA_BUF_PLANE1_FD_EXT 0x3275
#endif
#ifndef EGL_DMA_BUF_PLANE1_OFFSET_EXT
#define EGL_DMA_BUF_PLANE1_OFFSET_EXT 0x3276
#endif
#ifndef EGL_DMA_BUF_PLANE1_PITCH_EXT
#define EGL_DMA_BUF_PLANE1_PITCH_EXT 0x3277
#endif
#ifndef EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT
#define EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT 0x3445
#endif
#ifndef EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT
#define EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT 0x3446
#endif
#ifndef EGL_DMA_BUF_PLANE2_FD_EXT
#define EGL_DMA_BUF_PLANE2_FD_EXT 0x3278
#endif
#ifndef EGL_DMA_BUF_PLANE2_OFFSET_EXT
#define EGL_DMA_BUF_PLANE2_OFFSET_EXT 0x3279
#endif
#ifndef EGL_DMA_BUF_PLANE2_PITCH_EXT
#define EGL_DMA_BUF_PLANE2_PITCH_EXT 0x327A
#endif
#ifndef EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT
#define EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT 0x3447
#endif
#ifndef EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT
#define EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT 0x3448
#endif

#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif

// GL_R16 and GL_RG16 are not in GLES3 core but may be supported via extension
// or we use float variants as fallback
#ifndef GL_R16
#define GL_R16 0x822A
#endif
#ifndef GL_RG16
#define GL_RG16 0x822C
#endif

// GL OES EGL image extension
typedef void (*PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)(GLenum target, void* image);
static PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = nullptr;


// Helper to get per-plane DRM format for EGL import
static uint32_t get_plane_drm_format(uint32_t v4l2_fmt, int plane_index)
{
    switch (v4l2_fmt) {
    case V4L2_PIX_FMT_NV12:
        return (plane_index == 0) ? DRM_FORMAT_R8 : DRM_FORMAT_GR88;
    case V4L2_PIX_FMT_NV21:
        return (plane_index == 0) ? DRM_FORMAT_R8 : DRM_FORMAT_RG88;
    case V4L2_PIX_FMT_YUV420:
    case V4L2_PIX_FMT_YVU420:
        return DRM_FORMAT_R8;
    default:
        // For unknown formats, try R8 for first plane
        return (plane_index == 0) ? DRM_FORMAT_R8 : DRM_FORMAT_GR88;
    }
}

// V4L2_XFER_FUNC_ARIB_STD_B67 may not be defined on older kernels (added in 4.12)
#ifndef V4L2_XFER_FUNC_ARIB_STD_B67
#define V4L2_XFER_FUNC_ARIB_STD_B67 8
#endif

// Map V4L2 colorspace/transfer function to libplacebo color space
static pl_color_space get_pl_color_space(uint32_t v4l2_colorspace, uint32_t v4l2_xfer_func)
{
    pl_color_space cs = pl_color_space_unknown;

    // Map colorspace to primaries
    switch (v4l2_colorspace) {
    case V4L2_COLORSPACE_SMPTE170M:
    case V4L2_COLORSPACE_470_SYSTEM_M:
        cs.primaries = PL_COLOR_PRIM_BT_601_525;
        break;
    case V4L2_COLORSPACE_470_SYSTEM_BG:
        cs.primaries = PL_COLOR_PRIM_BT_601_625;
        break;
    case V4L2_COLORSPACE_REC709:
    case V4L2_COLORSPACE_SRGB:
    case V4L2_COLORSPACE_DEFAULT:
        cs.primaries = PL_COLOR_PRIM_BT_709;
        break;
    case V4L2_COLORSPACE_BT2020:
        cs.primaries = PL_COLOR_PRIM_BT_2020;
        break;
    default:
        cs.primaries = PL_COLOR_PRIM_BT_709;
        break;
    }

    // Map transfer function
    switch (v4l2_xfer_func) {
    case V4L2_XFER_FUNC_709:
    case V4L2_XFER_FUNC_DEFAULT:
        cs.transfer = PL_COLOR_TRC_BT_1886;
        break;
    case V4L2_XFER_FUNC_SRGB:
        cs.transfer = PL_COLOR_TRC_SRGB;
        break;
    case V4L2_XFER_FUNC_SMPTE2084:
        cs.transfer = PL_COLOR_TRC_PQ;
        break;
    case V4L2_XFER_FUNC_ARIB_STD_B67:
        cs.transfer = PL_COLOR_TRC_HLG;
        break;
    default:
        cs.transfer = PL_COLOR_TRC_BT_1886;
        break;
    }

    return cs;
}

// Map V4L2 ycbcr_enc/quantization to libplacebo color representation
static pl_color_repr get_pl_color_repr(uint32_t v4l2_ycbcr_enc, uint32_t v4l2_quantization)
{
    pl_color_repr repr = pl_color_repr_sdtv;

    // Map YCbCr encoding
    switch (v4l2_ycbcr_enc) {
    case V4L2_YCBCR_ENC_601:
    case V4L2_YCBCR_ENC_XV601:
        repr.sys = PL_COLOR_SYSTEM_BT_601;
        break;
    case V4L2_YCBCR_ENC_709:
    case V4L2_YCBCR_ENC_XV709:
    case V4L2_YCBCR_ENC_DEFAULT:
        repr.sys = PL_COLOR_SYSTEM_BT_709;
        break;
    case V4L2_YCBCR_ENC_BT2020:
        repr.sys = PL_COLOR_SYSTEM_BT_2020_NC;
        break;
    case V4L2_YCBCR_ENC_BT2020_CONST_LUM:
        repr.sys = PL_COLOR_SYSTEM_BT_2020_C;
        break;
    default:
        repr.sys = PL_COLOR_SYSTEM_BT_709;
        break;
    }

    // Map quantization (limited vs full range)
    switch (v4l2_quantization) {
    case V4L2_QUANTIZATION_FULL_RANGE:
        repr.levels = PL_COLOR_LEVELS_FULL;
        break;
    case V4L2_QUANTIZATION_LIM_RANGE:
    case V4L2_QUANTIZATION_DEFAULT:
    default:
        repr.levels = PL_COLOR_LEVELS_LIMITED;
        break;
    }

    repr.alpha = PL_ALPHA_UNKNOWN;

    // Set bit depth for 8-bit content
    repr.bits.sample_depth = 8;
    repr.bits.color_depth = 8;
    repr.bits.bit_shift = 0;

    return repr;
}

static void placebo_log_cb(void *user, pl_log_level level, const char *msg)
{
    Q_UNUSED(user);
    switch (level) {
    case PL_LOG_FATAL:
    case PL_LOG_ERR:
        qCritical() << "[libplacebo]" << msg;
        break;
    case PL_LOG_WARN:
        qWarning() << "[libplacebo]" << msg;
        break;
    case PL_LOG_INFO:
        qInfo() << "[libplacebo]" << msg;
        break;
    case PL_LOG_DEBUG:
    case PL_LOG_TRACE:
        qDebug() << "[libplacebo]" << msg;
        break;
    default:
        break;
    }
}

PlaceboRenderer::PlaceboRenderer()
{
    qDebug() << "PlaceboRenderer: constructor";
}

PlaceboRenderer::~PlaceboRenderer()
{
    cleanup();
    qDebug() << "PlaceboRenderer: destructor";
}

bool PlaceboRenderer::init_gl()
{
    if (m_initialized) {
        qWarning() << "PlaceboRenderer: already initialized";
        return true;
    }

    qDebug() << "PlaceboRenderer: initializing with OpenGL ES";

    // Load EGL extension functions
    m_eglCreateImageKHR = (PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");
    m_eglDestroyImageKHR = (PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");
    glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)
        eglGetProcAddress("glEGLImageTargetTexture2DOES");

    if (!m_eglCreateImageKHR || !m_eglDestroyImageKHR || !glEGLImageTargetTexture2DOES) {
        qWarning() << "PlaceboRenderer: EGL DMA-BUF extensions not available";
        // Continue anyway - might work with other import methods
    }

    // Create libplacebo log
    struct pl_log_params log_params = {
        .log_cb = placebo_log_cb,
        .log_level = PL_LOG_INFO,
    };
    m_pl_log = pl_log_create(PL_API_VER, &log_params);

    if (!m_pl_log) {
        qCritical() << "PlaceboRenderer: failed to create pl_log";
        return false;
    }

    // Create OpenGL context wrapper
    // Field order must match struct definition: debug, allow_software, ..., egl_display, egl_context
    struct pl_opengl_params opengl_params = {0};
    opengl_params.debug = false;
    opengl_params.allow_software = false;
    opengl_params.egl_display = eglGetCurrentDisplay();
    opengl_params.egl_context = eglGetCurrentContext();
    m_pl_opengl = pl_opengl_create(m_pl_log, &opengl_params);

    if (!m_pl_opengl) {
        qCritical() << "PlaceboRenderer: failed to create pl_opengl";
        pl_log_destroy(&m_pl_log);
        return false;
    }

    m_pl_gpu = m_pl_opengl->gpu;
    if (!m_pl_gpu) {
        qCritical() << "PlaceboRenderer: failed to get pl_gpu";
        pl_opengl_destroy(&m_pl_opengl);
        pl_log_destroy(&m_pl_log);
        return false;
    }

    // Create renderer
    m_pl_renderer = pl_renderer_create(m_pl_log, m_pl_gpu);
    if (!m_pl_renderer) {
        qCritical() << "PlaceboRenderer: failed to create pl_renderer";
        pl_opengl_destroy(&m_pl_opengl);
        pl_log_destroy(&m_pl_log);
        return false;
    }

    m_initialized = true;
    qInfo() << "PlaceboRenderer: initialized successfully";
    qInfo() << debug_info().c_str();

    return true;
}

void PlaceboRenderer::set_frame_format(const FrameFormat& format)
{
    if (format.width != m_frame_format.width ||
        format.height != m_frame_format.height ||
        format.pixel_format != m_frame_format.pixel_format ||
        format.plane_count != m_frame_format.plane_count) {

        char fourcc[5] = {0};
        memcpy(fourcc, &format.pixel_format, 4);
        qInfo() << "PlaceboRenderer: frame format changed to"
                << format.width << "x" << format.height
                << "format:" << fourcc
                << "planes:" << format.plane_count;

        m_frame_format = format;
        m_format_changed = true;
    }
}

bool PlaceboRenderer::render_frame(const PlaceboFrame& frame, int target_width, int target_height, int rotation_degrees)
{
    if (!m_initialized) {
        qWarning() << "PlaceboRenderer: not initialized";
        return false;
    }

    if (!frame.is_valid()) {
        qWarning() << "PlaceboRenderer: invalid frame";
        return false;
    }

    // Import DMA-BUF to textures
    if (!create_textures_from_dmabuf(frame)) {
        qWarning() << "PlaceboRenderer: failed to create textures from DMA-BUF";
        return false;
    }

    m_has_frame = true;

    // Render
    return render_last_frame(target_width, target_height, rotation_degrees);
}

bool PlaceboRenderer::render_last_frame(int target_width, int target_height, int rotation_degrees)
{
    if (!m_initialized || !m_has_frame || m_current_tex_count == 0) {
        // No frame to render - just clear
        clear_to_black();
        return true;
    }

    // Ensure we have a target texture
    if (!ensure_target_tex(target_width, target_height)) {
        qWarning() << "PlaceboRenderer: failed to ensure target texture";
        return false;
    }

    // Build pl_frame for source
    pl_frame src_frame = {0};
    src_frame.num_planes = m_current_tex_count;

    PixelFormatInfo fmt_info = get_pixel_format_info(m_frame_format.pixel_format);

    for (int i = 0; i < m_current_tex_count; i++) {
        src_frame.planes[i].texture = m_current_tex[i];
        src_frame.planes[i].components = (i == 0) ? 1 : 2;  // Y plane has 1, UV has 2
        src_frame.planes[i].component_mapping[0] = (i == 0) ? PL_CHANNEL_Y : PL_CHANNEL_CB;
        src_frame.planes[i].component_mapping[1] = (i == 0) ? 0 : PL_CHANNEL_CR;
        src_frame.planes[i].component_mapping[2] = 0;
        src_frame.planes[i].component_mapping[3] = 0;
    }

    // Set color representation and space from V4L2 metadata
    src_frame.repr = get_pl_color_repr(m_frame_format.ycbcr_enc, m_frame_format.quantization);
    src_frame.color = get_pl_color_space(m_frame_format.colorspace, m_frame_format.xfer_func);

    // Handle rotation
    src_frame.rotation = PL_ROTATION_0;
    switch (rotation_degrees) {
    case 90:
        src_frame.rotation = PL_ROTATION_90;
        break;
    case 180:
        src_frame.rotation = PL_ROTATION_180;
        break;
    case 270:
        src_frame.rotation = PL_ROTATION_270;
        break;
    }

    // Build pl_frame for target (render to default framebuffer)
    pl_frame dst_frame = {0};
    dst_frame.num_planes = 1;
    dst_frame.planes[0].texture = m_target_tex;
    dst_frame.planes[0].components = 4;
    dst_frame.planes[0].component_mapping[0] = PL_CHANNEL_R;
    dst_frame.planes[0].component_mapping[1] = PL_CHANNEL_G;
    dst_frame.planes[0].component_mapping[2] = PL_CHANNEL_B;
    dst_frame.planes[0].component_mapping[3] = PL_CHANNEL_A;
    dst_frame.repr = pl_color_repr_rgb;
    dst_frame.color = pl_color_space_srgb;

    // Render
    pl_render_params params = pl_render_default_params;
    params.upscaler = &pl_filter_bilinear;
    params.downscaler = &pl_filter_bilinear;

    if (!pl_render_image(m_pl_renderer, &src_frame, &dst_frame, &params)) {
        qWarning() << "PlaceboRenderer: pl_render_image failed";
        return false;
    }

    // Now blit from our target texture to the default framebuffer
    struct pl_tex_blit_params blit_params = {
        .src = m_target_tex,
        .dst = NULL,  // NULL = default framebuffer
        .src_rc = {0, 0, target_width, target_height},
        .dst_rc = {0, 0, target_width, target_height},
    };
    pl_tex_blit(m_pl_gpu, &blit_params);

    return true;
}

void PlaceboRenderer::clear_to_black()
{
    if (!m_initialized) return;

    // Clear default framebuffer
    float clear_color[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    pl_tex_clear(m_pl_gpu, NULL, clear_color);
}

void PlaceboRenderer::cleanup()
{
    if (!m_initialized) return;

    qDebug() << "PlaceboRenderer: cleaning up";

    destroy_current_textures();

    if (m_target_tex) {
        pl_tex_destroy(m_pl_gpu, &m_target_tex);
        m_target_tex = nullptr;
    }

    if (m_pl_renderer) {
        pl_renderer_destroy(&m_pl_renderer);
    }

    if (m_pl_opengl) {
        pl_opengl_destroy(&m_pl_opengl);
        m_pl_gpu = nullptr;
    }

    if (m_pl_log) {
        pl_log_destroy(&m_pl_log);
    }

    m_initialized = false;
    m_has_frame = false;
}

std::string PlaceboRenderer::debug_info() const
{
    std::ostringstream ss;
    ss << "PlaceboRenderer debug info:\n";
    ss << "  Initialized: " << (m_initialized ? "yes" : "no") << "\n";

    if (m_pl_gpu) {
        ss << "  GPU: " << m_pl_gpu->glsl.version << " GLSL\n";
        ss << "  Limits: max_tex_2d_dim=" << m_pl_gpu->limits.max_tex_2d_dim << "\n";
    }

    if (m_frame_format.is_valid()) {
        ss << "  Frame format: " << m_frame_format.width << "x" << m_frame_format.height;
        ss << " fourcc=0x" << std::hex << m_frame_format.pixel_format;
        ss << " planes=" << std::dec << m_frame_format.plane_count << "\n";
    }

    return ss.str();
}

bool PlaceboRenderer::create_textures_from_dmabuf(const PlaceboFrame& frame)
{
    // Destroy old textures if format changed
    if (m_format_changed) {
        destroy_current_textures();
        m_format_changed = false;
    }

    EGLDisplay egl_display = eglGetCurrentDisplay();
    if (egl_display == EGL_NO_DISPLAY) {
        qWarning() << "PlaceboRenderer: no EGL display";
        return false;
    }

    PixelFormatInfo fmt_info = get_pixel_format_info(frame.pixel_format);

    // For NV12/NV21: plane 0 = Y (full res), plane 1 = UV (half res)
    // For YUV420P: plane 0 = Y, plane 1 = U, plane 2 = V

    destroy_current_textures();
    m_current_tex_count = 0;

    for (uint32_t i = 0; i < frame.plane_count && i < 4; i++) {
        int plane_width = frame.width;
        int plane_height = frame.height;

        // Chroma planes are subsampled
        if (i > 0 && fmt_info.has_chroma) {
            plane_width /= fmt_info.chroma_w;
            plane_height /= fmt_info.chroma_h;
        }

        // Create EGL image from DMA-BUF
        EGLint attribs[] = {
            EGL_WIDTH, (EGLint)plane_width,
            EGL_HEIGHT, (EGLint)plane_height,
            EGL_LINUX_DRM_FOURCC_EXT, (EGLint)get_plane_drm_format(frame.pixel_format, i),
            EGL_DMA_BUF_PLANE0_FD_EXT, frame.planes[i].fd,
            EGL_DMA_BUF_PLANE0_OFFSET_EXT, (EGLint)frame.planes[i].offset,
            EGL_DMA_BUF_PLANE0_PITCH_EXT, (EGLint)frame.planes[i].pitch,
            EGL_NONE
        };

        EGLImage egl_image = m_eglCreateImageKHR(
            egl_display,
            EGL_NO_CONTEXT,
            EGL_LINUX_DMA_BUF_EXT,
            nullptr,
            attribs
        );

        if (egl_image == EGL_NO_IMAGE_KHR) {
            qWarning() << "PlaceboRenderer: failed to create EGL image for plane" << i
                       << "error:" << Qt::hex << eglGetError();
            destroy_current_textures();
            return false;
        }

        // Create GL texture and bind EGL image to it
        GLuint gl_tex = 0;
        glGenTextures(1, &gl_tex);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, gl_tex);
        glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES, egl_image);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);

        // Destroy EGL image (GL texture keeps reference)
        m_eglDestroyImageKHR(egl_display, egl_image);

        // Get the appropriate internal format for libplacebo
        int iformat = get_gl_internal_format(frame.pixel_format, i);

        // Wrap GL texture with libplacebo
        // Field order: texture, framebuffer, width, height, depth, target, iformat
        struct pl_opengl_wrap_params wrap_params = {0};
        wrap_params.texture = gl_tex;
        wrap_params.width = plane_width;
        wrap_params.height = plane_height;
        wrap_params.target = GL_TEXTURE_EXTERNAL_OES;
        wrap_params.iformat = iformat;
        pl_tex tex = pl_opengl_wrap(m_pl_gpu, &wrap_params);

        if (!tex) {
            qWarning() << "PlaceboRenderer: failed to wrap GL texture for plane" << i;
            glDeleteTextures(1, &gl_tex);
            destroy_current_textures();
            return false;
        }

        m_current_tex[i] = tex;
        m_current_gl_tex[i] = gl_tex;
        m_current_tex_count++;
    }

    return m_current_tex_count > 0;
}

void PlaceboRenderer::destroy_current_textures()
{
    for (int i = 0; i < 4; i++) {
        if (m_current_tex[i]) {
            pl_tex_destroy(m_pl_gpu, &m_current_tex[i]);
            m_current_tex[i] = nullptr;
        }
        if (m_current_gl_tex[i]) {
            glDeleteTextures(1, &m_current_gl_tex[i]);
            m_current_gl_tex[i] = 0;
        }
    }
    m_current_tex_count = 0;
}

bool PlaceboRenderer::ensure_target_tex(int width, int height)
{
    if (m_target_tex && m_target_width == width && m_target_height == height) {
        return true;
    }

    if (m_target_tex) {
        pl_tex_destroy(m_pl_gpu, &m_target_tex);
        m_target_tex = nullptr;
    }

    pl_fmt fmt = pl_find_fmt(m_pl_gpu, PL_FMT_UNORM, 4, 8, 8, PL_FMT_CAP_RENDERABLE);
    if (!fmt) {
        qWarning() << "PlaceboRenderer: no suitable render target format";
        return false;
    }

    struct pl_tex_params tex_params = {
        .w = width,
        .h = height,
        .format = fmt,
        .renderable = true,
        .blit_src = true,
        .blit_dst = true,
    };
    m_target_tex = pl_tex_create(m_pl_gpu, &tex_params);

    if (!m_target_tex) {
        qWarning() << "PlaceboRenderer: failed to create target texture";
        return false;
    }

    m_target_width = width;
    m_target_height = height;
    return true;
}

pl_fmt PlaceboRenderer::find_format_for_pixel_format(uint32_t pixel_format, int plane_index)
{
    // Based on the V4L2 pixel format and plane index, find the appropriate libplacebo format

    switch (pixel_format) {
    case V4L2_PIX_FMT_NV12:
    case V4L2_PIX_FMT_NV21:
        if (plane_index == 0) {
            // Y plane: 8-bit single channel
            return pl_find_fmt(m_pl_gpu, PL_FMT_UNORM, 1, 8, 8, PL_FMT_CAP_SAMPLEABLE);
        } else {
            // UV plane: 8-bit two channels
            return pl_find_fmt(m_pl_gpu, PL_FMT_UNORM, 2, 8, 8, PL_FMT_CAP_SAMPLEABLE);
        }

    case V4L2_PIX_FMT_YUV420:
    case V4L2_PIX_FMT_YVU420:
        // All planes are single channel 8-bit
        return pl_find_fmt(m_pl_gpu, PL_FMT_UNORM, 1, 8, 8, PL_FMT_CAP_SAMPLEABLE);

    default:
        qWarning() << "PlaceboRenderer: unknown pixel format:" << Qt::hex << pixel_format;
        return nullptr;
    }
}

int PlaceboRenderer::get_gl_internal_format(uint32_t pixel_format, int plane_index)
{
    // Return GL internal format for the given V4L2 pixel format and plane
    switch (pixel_format) {
    case V4L2_PIX_FMT_NV12:
    case V4L2_PIX_FMT_NV21:
        return (plane_index == 0) ? GL_R8 : GL_RG8;

    case V4L2_PIX_FMT_YUV420:
    case V4L2_PIX_FMT_YVU420:
        return GL_R8;

    default:
        return GL_R8;
    }
}

PlaceboRenderer::PixelFormatInfo PlaceboRenderer::get_pixel_format_info(uint32_t pixel_format)
{
    switch (pixel_format) {
    case V4L2_PIX_FMT_NV12:
        return {2, true, 2, 2, DRM_FORMAT_NV12};  // 2 planes, 4:2:0 subsampling

    case V4L2_PIX_FMT_NV21:
        return {2, true, 2, 2, DRM_FORMAT_NV21};  // 2 planes, 4:2:0 subsampling

    case V4L2_PIX_FMT_YUV420:
        return {3, true, 2, 2, DRM_FORMAT_YUV420};  // 3 planes, 4:2:0 subsampling

    case V4L2_PIX_FMT_YVU420:
        return {3, true, 2, 2, DRM_FORMAT_YVU420};  // 3 planes, 4:2:0 subsampling

    default:
        return {1, false, 1, 1, 0}; // Default: assume single plane
    }
}

#endif // ENABLE_V4L2_GL_PLAYER
