// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef PLACEBO_RENDERER_H
#define PLACEBO_RENDERER_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include <libplacebo/log.h>
#include <libplacebo/opengl.h>
#include <libplacebo/renderer.h>
#include <libplacebo/gpu.h>
#include <libplacebo/shaders/colorspace.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include "placebo_frame_queue.h"

/**
 * @brief PlaceboRenderer - renders video frames using libplacebo with OpenGL ES backend.
 *
 * This renderer is designed for EGLFS environments and supports:
 * - DMA-BUF import for zero-copy rendering from V4L2 decoders
 * - Dynamic format configuration based on decoder capabilities
 * - Multiple pixel formats (NV12, NV21, YUV420P, P010, etc.)
 * - "Last frame wins" rendering strategy
 *
 * Thread safety: render_frame() must be called from Qt render thread only.
 * Frame format can be configured from any thread before first render.
 */
class PlaceboRenderer
{
public:
    PlaceboRenderer();
    ~PlaceboRenderer();

    // Non-copyable, non-movable
    PlaceboRenderer(const PlaceboRenderer&) = delete;
    PlaceboRenderer& operator=(const PlaceboRenderer&) = delete;

    /**
     * @brief Frame format information from decoder
     */
    struct FrameFormat {
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t pixel_format = 0;      // V4L2_PIX_FMT_* constant
        uint32_t plane_count = 0;

        // V4L2 colorspace metadata
        uint32_t colorspace = 0;        // V4L2_COLORSPACE_*
        uint32_t ycbcr_enc = 0;         // V4L2_YCBCR_ENC_*
        uint32_t quantization = 0;      // V4L2_QUANTIZATION_*
        uint32_t xfer_func = 0;         // V4L2_XFER_FUNC_*

        // Per-plane information
        struct PlaneInfo {
            uint32_t offset = 0;
            uint32_t pitch = 0;         // stride in bytes
        };
        PlaneInfo planes[4];

        uint64_t drm_modifier = 0;      // DRM format modifier (linear, tiled, etc.)

        bool is_valid() const { return width > 0 && height > 0 && pixel_format != 0; }
    };

    /**
     * @brief Initialize libplacebo with OpenGL ES context
     * Must be called from Qt render thread after GL context is current.
     * @return true on success
     */
    bool init_gl();

    /**
     * @brief Check if renderer is initialized
     */
    bool is_initialized() const { return m_initialized; }

    /**
     * @brief Configure expected frame format from decoder
     * Should be called when decoder reports its output format.
     * Can be called before init_gl().
     * @param format Frame format information
     */
    void set_frame_format(const FrameFormat& format);

    /**
     * @brief Get current frame format
     */
    const FrameFormat& get_frame_format() const { return m_frame_format; }

    /**
     * @brief Render a frame from DMA-BUF
     * Must be called from Qt render thread.
     * @param frame The frame to render (contains DMA-BUF fd)
     * @param target_width Target render width
     * @param target_height Target render height
     * @param rotation_degrees Rotation in degrees (0, 90, 180, 270)
     * @return true on success
     */
    bool render_frame(const PlaceboFrame& frame, int target_width, int target_height, int rotation_degrees = 0);

    /**
     * @brief Render last frame again (for continuous display when no new frames)
     * @param target_width Target render width
     * @param target_height Target render height
     * @param rotation_degrees Rotation in degrees
     * @return true on success
     */
    bool render_last_frame(int target_width, int target_height, int rotation_degrees = 0);

    /**
     * @brief Clear the render target to black
     */
    void clear_to_black();

    /**
     * @brief Release all GPU resources
     * Must be called from Qt render thread before GL context is destroyed.
     */
    void cleanup();

    /**
     * @brief Get debug information string
     */
    std::string debug_info() const;

private:
    // libplacebo context
    pl_log m_pl_log = nullptr;
    pl_opengl m_pl_opengl = nullptr;
    pl_gpu m_pl_gpu = nullptr;
    pl_renderer m_pl_renderer = nullptr;

    // Current frame textures (for re-rendering last frame)
    pl_tex m_current_tex[4] = {nullptr, nullptr, nullptr, nullptr};
    unsigned int m_current_gl_tex[4] = {0, 0, 0, 0};  // GL texture handles
    int m_current_tex_count = 0;

    // Target FBO texture
    pl_tex m_target_tex = nullptr;
    int m_target_width = 0;
    int m_target_height = 0;

    // Frame format
    FrameFormat m_frame_format;
    bool m_format_changed = false;

    // State
    bool m_initialized = false;
    bool m_has_frame = false;

    // EGL function pointers for DMA-BUF import
    PFNEGLCREATEIMAGEKHRPROC m_eglCreateImageKHR = nullptr;
    PFNEGLDESTROYIMAGEKHRPROC m_eglDestroyImageKHR = nullptr;

    // Internal helpers
    bool create_textures_from_dmabuf(const PlaceboFrame& frame);
    void destroy_current_textures();
    bool ensure_target_tex(int width, int height);
    pl_fmt find_format_for_pixel_format(uint32_t pixel_format, int plane_index);
    int get_gl_internal_format(uint32_t pixel_format, int plane_index);
    void setup_render_params(pl_render_params* params);

    // V4L2 pixel format info
    struct PixelFormatInfo {
        int num_planes;
        bool has_chroma;
        int chroma_w;  // chroma subsampling width (1 = no subsampling, 2 = half)
        int chroma_h;  // chroma subsampling height
        uint32_t drm_fourcc;  // Corresponding DRM format
    };
    PixelFormatInfo get_pixel_format_info(uint32_t pixel_format);
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // PLACEBO_RENDERER_H
