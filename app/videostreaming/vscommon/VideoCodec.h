//
// Created by buldo on 1/22/26.
//

#ifndef QOPENHDPROJECT_VIDEOCODEC_H
#define QOPENHDPROJECT_VIDEOCODEC_H

#include <string>
#include <stdexcept>

enum class VideoCodec : int {
    H264 = 0,
    H265 = 1,
    MJPEG = 2
};

inline std::string videoCodecToString(VideoCodec codec) {
    switch (codec) {
        case VideoCodec::H264:
            return "h264";
        case VideoCodec::H265:
            return "h265";
        case VideoCodec::MJPEG:
            return "mjpeg";
        default:
            throw std::invalid_argument("Unknown VideoCodec");
    }
}

inline VideoCodec videoCodecFromInt(int value) {
    if (value < 0 || value > 2) {
        throw std::out_of_range("Invalid VideoCodec value");
    }
    return static_cast<VideoCodec>(value);
}

#endif //QOPENHDPROJECT_VIDEOCODEC_H
