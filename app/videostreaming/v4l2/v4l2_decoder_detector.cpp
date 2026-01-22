#ifdef ENABLE_V4L2_GL_PLAYER

#include "v4l2_decoder_detector.h"

#include <QDebug>

#include <algorithm>
#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <fstream>
#include <sstream>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/stat.h>

// Include sysmacros before linux headers to avoid conflicts
#include <sys/sysmacros.h>

#include <linux/videodev2.h>
#include <linux/media.h>

// Stateless codec pixel formats (slice-based) - defined if not present in headers
#ifndef V4L2_PIX_FMT_H264_SLICE
#define V4L2_PIX_FMT_H264_SLICE v4l2_fourcc('S', '2', '6', '4')
#endif
#ifndef V4L2_PIX_FMT_HEVC_SLICE
#define V4L2_PIX_FMT_HEVC_SLICE v4l2_fourcc('S', '2', '6', '5')
#endif


std::vector<V4L2DecoderDetector::DecoderInfo> V4L2DecoderDetector::detect_decoders()
{
    std::vector<DecoderInfo> decoders;

    DIR* dir = opendir("/dev");
    if (!dir) {
        qWarning() << "V4L2DecoderDetector: Failed to open /dev directory";
        return decoders;
    }

    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        std::string name = entry->d_name;

        // Filter for video devices
        if (name.rfind("video", 0) != 0) {
            continue;
        }

        std::string device_path = "/dev/" + name;
        probe_device(device_path, decoders);
    }

    closedir(dir);

    // Sort by device path for consistent ordering
    std::sort(decoders.begin(), decoders.end(),
              [](const DecoderInfo& a, const DecoderInfo& b) {
                  if (a.device_path != b.device_path) {
                      return a.device_path < b.device_path;
                  }
                  return static_cast<int>(a.codec) < static_cast<int>(b.codec);
              });

    return decoders;
}


bool V4L2DecoderDetector::probe_device(const std::string& device_path,
                                        std::vector<DecoderInfo>& out_decoders)
{
    int fd = open(device_path.c_str(), O_RDWR | O_NONBLOCK);
    if (fd < 0) {
        return false;
    }

    // Query device capabilities
    struct v4l2_capability cap = {};
    if (ioctl(fd, VIDIOC_QUERYCAP, &cap) < 0) {
        close(fd);
        return false;
    }

    // Check for M2M capability (required for decoder)
    uint32_t caps = cap.capabilities;
    if (caps & V4L2_CAP_DEVICE_CAPS) {
        caps = cap.device_caps;
    }

    bool is_m2m = (caps & V4L2_CAP_VIDEO_M2M_MPLANE) ||
                  (caps & V4L2_CAP_VIDEO_M2M);

    if (!is_m2m) {
        close(fd);
        return true; // Successfully probed, just not a decoder
    }

    std::string driver_name(reinterpret_cast<const char*>(cap.driver));
    std::string card_name(reinterpret_cast<const char*>(cap.card));

    // Determine if stateless
    bool stateless = is_stateless_decoder(fd, driver_name);

    // Find media device for stateless decoders
    std::string media_device;
    if (stateless) {
        media_device = find_media_device(device_path);
    }

    // Check for supported codecs
    // For stateless decoders, check slice formats; for stateful, check stream formats
    bool supports_h264 = false;
    bool supports_h265 = false;

    if (stateless) {
        supports_h264 = supports_codec(fd, V4L2_PIX_FMT_H264_SLICE);
        supports_h265 = supports_codec(fd, V4L2_PIX_FMT_HEVC_SLICE);
    }

    // Also check stateful formats (some drivers support both)
    if (!supports_h264) {
        supports_h264 = supports_codec(fd, V4L2_PIX_FMT_H264);
    }
    if (!supports_h265) {
        supports_h265 = supports_codec(fd, V4L2_PIX_FMT_HEVC);
    }

    close(fd);

    // Create decoder info entries for each supported codec
    if (supports_h264) {
        DecoderInfo info;
        info.codec = V4L2H264StatefulDecoder::Codec::H264;
        info.type = stateless ? DecoderType::Stateless : DecoderType::Stateful;
        info.device_path = device_path;
        info.media_device_path = media_device;
        info.driver_name = driver_name;
        info.card_name = card_name;
        out_decoders.push_back(info);
    }

    if (supports_h265) {
        DecoderInfo info;
        info.codec = V4L2H264StatefulDecoder::Codec::H265;
        info.type = stateless ? DecoderType::Stateless : DecoderType::Stateful;
        info.device_path = device_path;
        info.media_device_path = media_device;
        info.driver_name = driver_name;
        info.card_name = card_name;
        out_decoders.push_back(info);
    }

    return true;
}


bool V4L2DecoderDetector::supports_codec(int fd, uint32_t v4l2_format)
{
    struct v4l2_fmtdesc fmt = {};
    fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    fmt.index = 0;

    while (ioctl(fd, VIDIOC_ENUM_FMT, &fmt) == 0) {
        if (fmt.pixelformat == v4l2_format) {
            return true;
        }
        fmt.index++;
    }

    // Also try single-plane OUTPUT type
    fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    fmt.index = 0;

    while (ioctl(fd, VIDIOC_ENUM_FMT, &fmt) == 0) {
        if (fmt.pixelformat == v4l2_format) {
            return true;
        }
        fmt.index++;
    }

    return false;
}


bool V4L2DecoderDetector::is_stateless_decoder(int fd, const std::string& /*driver_name*/)
{
    // Method 1: Check for V4L2_BUF_CAP_SUPPORTS_REQUESTS capability
    // This is the definitive way to identify stateless decoders
    struct v4l2_requestbuffers reqbufs = {};
    reqbufs.count = 0;
    reqbufs.type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
    reqbufs.memory = V4L2_MEMORY_MMAP;

    if (ioctl(fd, VIDIOC_REQBUFS, &reqbufs) == 0) {
#ifdef V4L2_BUF_CAP_SUPPORTS_REQUESTS
        if (reqbufs.capabilities & V4L2_BUF_CAP_SUPPORTS_REQUESTS) {
            return true;
        }
#endif
    }

    // Try single-plane type as well
    reqbufs.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    reqbufs.count = 0;
    if (ioctl(fd, VIDIOC_REQBUFS, &reqbufs) == 0) {
#ifdef V4L2_BUF_CAP_SUPPORTS_REQUESTS
        if (reqbufs.capabilities & V4L2_BUF_CAP_SUPPORTS_REQUESTS) {
            return true;
        }
#endif
    }

    // Method 2: Check if device supports slice-based formats (stateless indicator)
    // Stateless decoders use V4L2_PIX_FMT_H264_SLICE / V4L2_PIX_FMT_HEVC_SLICE
    if (supports_codec(fd, V4L2_PIX_FMT_H264_SLICE) ||
        supports_codec(fd, V4L2_PIX_FMT_HEVC_SLICE)) {
        return true;
    }

    return false;
}


static bool get_video_device_numbers(const std::string& video_device_path,
                                      unsigned int& out_major, unsigned int& out_minor)
{
    struct stat st;
    if (stat(video_device_path.c_str(), &st) < 0) {
        return false;
    }

    if (!S_ISCHR(st.st_mode)) {
        return false;
    }

    // Extract major/minor using GNU libc macros
    // Use function call syntax to avoid macro expansion issues
    out_major = gnu_dev_major(st.st_rdev);
    out_minor = gnu_dev_minor(st.st_rdev);
    return true;
}


static bool parse_dev_file(const std::string& dev_file_path,
                            unsigned int& out_major, unsigned int& out_minor)
{
    // Read sysfs dev file which contains "major:minor" format
    std::ifstream dev_file(dev_file_path);
    if (!dev_file.is_open()) {
        return false;
    }

    char colon;
    if (!(dev_file >> out_major >> colon >> out_minor) || colon != ':') {
        return false;
    }

    return true;
}


std::string V4L2DecoderDetector::find_media_device(const std::string& video_device_path)
{
    qDebug() << "V4L2DecoderDetector: Finding media device for" << video_device_path.c_str();

    // Extract device name: /dev/video19 -> video19
    std::string dev_name = get_device_name(video_device_path);

    // Use sysfs to find associated media device
    // Path: /sys/class/video4linux/videoX/device/mediaY
    std::string sysfs_device_path = "/sys/class/video4linux/" + dev_name + "/device";

    DIR* dir = opendir(sysfs_device_path.c_str());
    if (!dir) {
        qDebug() << "V4L2DecoderDetector: Failed to open sysfs path" << sysfs_device_path.c_str();
        return "";
    }

    std::string result;
    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        std::string name = entry->d_name;

        // Look for media* subdirectory
        if (name.rfind("media", 0) != 0) {
            continue;
        }

        // Read dev file to get major:minor numbers
        std::string dev_file_path = sysfs_device_path + "/" + name + "/dev";
        unsigned int sysfs_major, sysfs_minor;
        if (!parse_dev_file(dev_file_path, sysfs_major, sysfs_minor)) {
            qDebug() << "V4L2DecoderDetector: Failed to parse" << dev_file_path.c_str();
            continue;
        }

        qDebug() << "V4L2DecoderDetector: Found sysfs media entry" << name.c_str()
                 << "major:" << sysfs_major << "minor:" << sysfs_minor;

        // Find matching /dev/mediaX device by major:minor
        DIR* dev_dir = opendir("/dev");
        if (!dev_dir) {
            continue;
        }

        struct dirent* dev_entry;
        while ((dev_entry = readdir(dev_dir)) != nullptr) {
            std::string dev_name_candidate = dev_entry->d_name;
            if (dev_name_candidate.rfind("media", 0) != 0) {
                continue;
            }

            std::string media_path = "/dev/" + dev_name_candidate;
            unsigned int dev_major, dev_minor;
            if (get_video_device_numbers(media_path, dev_major, dev_minor)) {
                if (dev_major == sysfs_major && dev_minor == sysfs_minor) {
                    result = media_path;
                    qDebug() << "V4L2DecoderDetector: Found media device" << result.c_str()
                             << "for" << video_device_path.c_str();
                    break;
                }
            }
        }

        closedir(dev_dir);

        if (!result.empty()) {
            break;
        }
    }

    closedir(dir);

    if (result.empty()) {
        qDebug() << "V4L2DecoderDetector: No media device found for" << video_device_path.c_str();
    }

    return result;
}


std::string V4L2DecoderDetector::get_device_name(const std::string& device_path)
{
    size_t pos = device_path.rfind('/');
    if (pos == std::string::npos) {
        return device_path;
    }
    return device_path.substr(pos + 1);
}

#endif // ENABLE_V4L2_GL_PLAYER
