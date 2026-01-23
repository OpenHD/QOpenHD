#ifndef QOPENHDPROJECT_DECODERINFO_H
#define QOPENHDPROJECT_DECODERINFO_H

#include "../vscommon/VideoCodec.h"
#include "V4L2DecoderType.h"

/**
 * @brief Information about a detected decoder.
 */
struct DecoderInfo {
    VideoCodec codec;           ///< Supported codec (H264 or H265)
    V4L2DecoderType type;                   ///< Stateful or stateless
    std::string device_path;            ///< Path to V4L2 device (e.g., /dev/video0)
    std::string media_device_path;      ///< Path to media device (only for stateless)
    std::string driver_name;            ///< Driver name (e.g., "hantro-vpu")
    std::string card_name;              ///< Card/device description
};
#endif //QOPENHDPROJECT_DECODERINFO_H
