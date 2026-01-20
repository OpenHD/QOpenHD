// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef V4L2_DECODER_DETECTOR_H
#define V4L2_DECODER_DETECTOR_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_decoder.h"

#include <cstdint>
#include <string>
#include <vector>

/**
 * @brief V4L2 decoder detection utility.
 *
 * Scans the system for available V4L2 M2M video decoders and returns
 * information about their capabilities, including codec support and
 * whether they are stateful or stateless decoders.
 *
 * For stateless decoders, the associated media device path is also
 * provided, which is required for request API operations.
 */
class V4L2DecoderDetector
{
public:
    /**
     * @brief Decoder type (stateful vs stateless).
     *
     * Stateful decoders handle all parsing and state management internally.
     * Stateless decoders require the application to manage decoder state
     * and use the media request API.
     */
    enum class DecoderType {
        Stateful,
        Stateless
    };

    /**
     * @brief Information about a detected decoder.
     */
    struct DecoderInfo {
        V4L2Decoder::Codec codec;           ///< Supported codec (H264 or H265)
        DecoderType type;                   ///< Stateful or stateless
        std::string device_path;            ///< Path to V4L2 device (e.g., /dev/video0)
        std::string media_device_path;      ///< Path to media device (only for stateless)
        std::string driver_name;            ///< Driver name (e.g., "hantro-vpu")
        std::string card_name;              ///< Card/device description
    };

    /**
     * @brief Detect all available V4L2 decoders in the system.
     *
     * Scans /dev/video* devices, probes their capabilities using V4L2 ioctls,
     * and returns information about each decoder found. Each supported codec
     * on a device is reported as a separate DecoderInfo entry.
     *
     * @return Vector of detected decoders (may be empty if none found)
     */
    static std::vector<DecoderInfo> detect_decoders();

private:
    /**
     * @brief Probe a single video device for decoder capabilities.
     * @param device_path Path to the video device
     * @param out_decoders Vector to append detected decoders to
     * @return true if device was successfully probed (even if not a decoder)
     */
    static bool probe_device(const std::string& device_path,
                             std::vector<DecoderInfo>& out_decoders);

    /**
     * @brief Check if a device supports a specific codec on OUTPUT queue.
     * @param fd Open file descriptor for the video device
     * @param v4l2_format V4L2 pixel format to check (e.g., V4L2_PIX_FMT_H264)
     * @return true if codec is supported
     */
    static bool supports_codec(int fd, uint32_t v4l2_format);

    /**
     * @brief Determine if a decoder is stateless.
     *
     * Checks for stateless decoder indicators:
     * - Known stateless driver names (hantro, rkvdec, cedrus, etc.)
     * - Presence of V4L2_BUF_CAP_SUPPORTS_REQUESTS capability
     *
     * @param fd Open file descriptor for the video device
     * @param driver_name Driver name from VIDIOC_QUERYCAP
     * @return true if decoder is stateless
     */
    static bool is_stateless_decoder(int fd, const std::string& driver_name);

    /**
     * @brief Find the media device associated with a video device.
     *
     * Traverses sysfs to find the media controller device that manages
     * the given video device. This is required for stateless decoders.
     *
     * @param video_device_path Path to the video device (e.g., /dev/video0)
     * @return Path to media device (e.g., /dev/media0), or empty string if not found
     */
    static std::string find_media_device(const std::string& video_device_path);

    /**
     * @brief Get the device name from path (e.g., "video0" from "/dev/video0").
     * @param device_path Full device path
     * @return Device name only
     */
    static std::string get_device_name(const std::string& device_path);
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // V4L2_DECODER_DETECTOR_H
