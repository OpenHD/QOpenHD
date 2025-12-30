#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstring>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include "mavlink/v2.0/openhd/mavlink.h"

namespace {

struct Endpoint {
    std::string host = "127.0.0.1";
    uint16_t port = 14550;  // Default OpenHD client out port
};

struct Target {
    uint8_t system_id;
    uint8_t component_id;
};

class MavlinkSender {
   public:
    explicit MavlinkSender(const Endpoint &ep) {
        socket_fd_ = ::socket(AF_INET, SOCK_DGRAM, 0);
        if (socket_fd_ < 0) {
            throw std::runtime_error("Failed to create UDP socket");
        }
        std::memset(&addr_, 0, sizeof(addr_));
        addr_.sin_family = AF_INET;
        addr_.sin_port = htons(ep.port);
        if (inet_pton(AF_INET, ep.host.c_str(), &addr_.sin_addr) != 1) {
            throw std::runtime_error("Invalid host address");
        }
    }

    ~MavlinkSender() { close(socket_fd_); }

    bool send(const mavlink_message_t &msg) const {
        uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
        const auto len = mavlink_msg_to_send_buffer(buffer, &msg);
        return sendto(socket_fd_, buffer, len, 0, reinterpret_cast<const sockaddr *>(&addr_), sizeof(addr_)) == len;
    }

   private:
    int socket_fd_{};
    sockaddr_in addr_{};
};

void print_usage() {
    std::cout << "Usage: openhd_mavlink_tool [--host ip] [--port udp_port] <command> [options]\n"
                 "Commands:\n"
                 "  scan --bands <mask> [--widths <mask>] [--search]\n"
                 "  set-link [--frequency MHz] [--bandwidth MHz] [--mcs index] [--tx-power mw] [--tx-power-armed mw]\n"
                 "  set-video [--mode 1280x720@60] [--codec h264|h265] [--bitrate mbit] [--keyframe frames] [--rotation 0|180] [--flip on|off]\n"
                 "  set-camera [--iso value] [--awb mode] [--contrast value] [--sharpness value] [--saturation value]\n"
                 "  set-recording --mode disable|enable|auto\n"
                 "  set-wifi --target air|ground --mode off|hotspot|client [--hotspot auto|off|on] [--hs-iface name]\n"
                 "          [--cl-iface name] [--cl-ssid ssid] [--cl-pw password]\n"
                 "Use --air-only to avoid mirroring link changes to the ground station.\n";
}

std::optional<Endpoint> parse_endpoint(int &argc, char **&argv) {
    Endpoint ep;
    int shift = 0;
    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--host" && i + 1 < argc) {
            ep.host = argv[i + 1];
            shift += 2;
            ++i;
        } else if (arg == "--port" && i + 1 < argc) {
            ep.port = static_cast<uint16_t>(std::stoi(argv[i + 1]));
            shift += 2;
            ++i;
        } else {
            continue;
        }
    }
    argv += shift;
    argc -= shift;
    return ep;
}

mavlink_message_t build_param_ext_set(const Target &target, const std::string &name, const std::string &value,
                                      MAV_PARAM_EXT_TYPE type) {
    mavlink_message_t msg{};
    mavlink_param_ext_set_t payload{};
    payload.target_system = target.system_id;
    payload.target_component = target.component_id;
    std::strncpy(payload.param_id, name.c_str(), sizeof(payload.param_id));
    payload.param_id[sizeof(payload.param_id) - 1] = '\0';
    std::strncpy(payload.param_value, value.c_str(), sizeof(payload.param_value));
    payload.param_value[sizeof(payload.param_value) - 1] = '\0';
    payload.param_type = static_cast<uint8_t>(type);
    mavlink_msg_param_ext_set_encode_chan(255, MAV_COMP_ID_SYSTEM_CONTROL, MAVLINK_COMM_0, &msg, &payload);
    return msg;
}

bool send_param_set(const MavlinkSender &sender, const Target &target, const std::string &name, const std::string &value,
                    MAV_PARAM_EXT_TYPE type) {
    const auto msg = build_param_ext_set(target, name, value, type);
    return sender.send(msg);
}

bool send_command_long(const MavlinkSender &sender, const Target &target, uint16_t command, float param1, float param2 = 0) {
    mavlink_message_t msg{};
    mavlink_command_long_t payload{};
    payload.target_system = target.system_id;
    payload.target_component = target.component_id;
    payload.command = command;
    payload.param1 = param1;
    payload.param2 = param2;
    mavlink_msg_command_long_encode_chan(255, MAV_COMP_ID_SYSTEM_CONTROL, MAVLINK_COMM_0, &msg, &payload);
    return sender.send(msg);
}

std::vector<Target> default_link_targets(bool mirror_ground) {
    if (mirror_ground) {
        return {{101, MAV_COMP_ID_ONBOARD_COMPUTER}, {100, MAV_COMP_ID_ONBOARD_COMPUTER}};
    }
    return {{101, MAV_COMP_ID_ONBOARD_COMPUTER}};
}

int handle_scan(const MavlinkSender &sender, int argc, char **argv) {
    int bands = -1;
    int widths = 0;
    bool search = false;
    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--bands" && i + 1 < argc) {
            bands = std::stoi(argv[++i]);
        } else if (arg == "--widths" && i + 1 < argc) {
            widths = std::stoi(argv[++i]);
        } else if (arg == "--search") {
            search = true;
        }
    }
    if (bands < 0) {
        std::cerr << "scan requires --bands <mask>" << std::endl;
        return 1;
    }
    const Target target{100, MAV_COMP_ID_ONBOARD_COMPUTER};
    const bool ok = search ? send_command_long(sender, target, OPENHD_CMD_INITIATE_CHANNEL_SEARCH, static_cast<float>(bands),
                                               static_cast<float>(widths))
                           : send_command_long(sender, target, OPENHD_CMD_INITIATE_CHANNEL_ANALYZE, static_cast<float>(bands));
    std::cout << (ok ? "Scan command sent" : "Failed to send scan command") << std::endl;
    return ok ? 0 : 1;
}

int handle_set_link(const MavlinkSender &sender, int argc, char **argv) {
    std::optional<std::string> frequency;
    std::optional<std::string> bandwidth;
    std::optional<std::string> mcs;
    std::optional<std::string> tx_power;
    std::optional<std::string> tx_power_armed;
    bool mirror_ground = true;

    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--frequency" && i + 1 < argc) {
            frequency = argv[++i];
        } else if (arg == "--bandwidth" && i + 1 < argc) {
            bandwidth = argv[++i];
        } else if (arg == "--mcs" && i + 1 < argc) {
            mcs = argv[++i];
        } else if (arg == "--tx-power" && i + 1 < argc) {
            tx_power = argv[++i];
        } else if (arg == "--tx-power-armed" && i + 1 < argc) {
            tx_power_armed = argv[++i];
        } else if (arg == "--air-only") {
            mirror_ground = false;
        }
    }

    auto targets = default_link_targets(mirror_ground);
    bool success = true;
    for (const auto &target : targets) {
        if (frequency) success &= send_param_set(sender, target, "WB_FREQUENCY", *frequency, MAV_PARAM_EXT_TYPE_REAL32);
        if (bandwidth) success &= send_param_set(sender, target, "WB_CHANNEL_W", *bandwidth, MAV_PARAM_EXT_TYPE_REAL32);
        if (mcs) success &= send_param_set(sender, target, "WB_MCS_INDEX", *mcs, MAV_PARAM_EXT_TYPE_INT32);
        if (tx_power) success &= send_param_set(sender, target, "TX_POWER_MW", *tx_power, MAV_PARAM_EXT_TYPE_INT32);
        if (tx_power_armed)
            success &= send_param_set(sender, target, "TX_POWER_MW_ARM", *tx_power_armed, MAV_PARAM_EXT_TYPE_INT32);
    }
    std::cout << (success ? "Link params sent" : "Failed to send some link params") << std::endl;
    return success ? 0 : 1;
}

int handle_set_video(const MavlinkSender &sender, int argc, char **argv) {
    std::optional<std::string> mode;
    std::optional<std::string> codec;
    std::optional<std::string> bitrate;
    std::optional<std::string> keyframe;
    std::optional<std::string> rotation;
    std::optional<std::string> flip;
    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--mode" && i + 1 < argc) {
            mode = argv[++i];
        } else if (arg == "--codec" && i + 1 < argc) {
            codec = argv[++i];
        } else if (arg == "--bitrate" && i + 1 < argc) {
            bitrate = argv[++i];
        } else if (arg == "--keyframe" && i + 1 < argc) {
            keyframe = argv[++i];
        } else if (arg == "--rotation" && i + 1 < argc) {
            rotation = argv[++i];
        } else if (arg == "--flip" && i + 1 < argc) {
            flip = argv[++i];
        }
    }

    const Target target{101, MAV_COMP_ID_CAMERA};
    bool success = true;
    if (mode) success &= send_param_set(sender, target, "RESOLUTION_FPS", *mode, MAV_PARAM_EXT_TYPE_CUSTOM);
    if (codec) success &= send_param_set(sender, target, "VIDEO_CODEC", *codec, MAV_PARAM_EXT_TYPE_CUSTOM);
    if (bitrate) success &= send_param_set(sender, target, "BITRATE_MBITS", *bitrate, MAV_PARAM_EXT_TYPE_REAL32);
    if (keyframe) success &= send_param_set(sender, target, "KEYFRAME_I", *keyframe, MAV_PARAM_EXT_TYPE_INT32);
    if (rotation) success &= send_param_set(sender, target, "ROTATION_DEG", *rotation, MAV_PARAM_EXT_TYPE_INT32);
    if (flip) success &= send_param_set(sender, target, "ROTATION_FLIP", *flip, MAV_PARAM_EXT_TYPE_INT32);

    std::cout << (success ? "Video params sent" : "Failed to send some video params") << std::endl;
    return success ? 0 : 1;
}

int handle_set_camera(const MavlinkSender &sender, int argc, char **argv) {
    std::optional<std::string> iso;
    std::optional<std::string> awb;
    std::optional<std::string> contrast;
    std::optional<std::string> sharpness;
    std::optional<std::string> saturation;

    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--iso" && i + 1 < argc) {
            iso = argv[++i];
        } else if (arg == "--awb" && i + 1 < argc) {
            awb = argv[++i];
        } else if (arg == "--contrast" && i + 1 < argc) {
            contrast = argv[++i];
        } else if (arg == "--sharpness" && i + 1 < argc) {
            sharpness = argv[++i];
        } else if (arg == "--saturation" && i + 1 < argc) {
            saturation = argv[++i];
        }
    }

    const Target target{101, MAV_COMP_ID_CAMERA};
    bool success = true;
    if (iso) success &= send_param_set(sender, target, "ISO", *iso, MAV_PARAM_EXT_TYPE_INT32);
    if (awb) success &= send_param_set(sender, target, "AWB_MODE", *awb, MAV_PARAM_EXT_TYPE_CUSTOM);
    if (contrast) success &= send_param_set(sender, target, "CONTRAST_LC", *contrast, MAV_PARAM_EXT_TYPE_INT32);
    if (sharpness) success &= send_param_set(sender, target, "SHARPNESS_LC", *sharpness, MAV_PARAM_EXT_TYPE_INT32);
    if (saturation) success &= send_param_set(sender, target, "SATURATION_LC", *saturation, MAV_PARAM_EXT_TYPE_INT32);

    std::cout << (success ? "Camera params sent" : "Failed to send some camera params") << std::endl;
    return success ? 0 : 1;
}

int handle_set_recording(const MavlinkSender &sender, int argc, char **argv) {
    std::optional<std::string> mode;
    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--mode" && i + 1 < argc) {
            mode = argv[++i];
        }
    }
    if (!mode) {
        std::cerr << "set-recording requires --mode disable|enable|auto" << std::endl;
        return 1;
    }
    static const std::unordered_map<std::string, std::string> kModes{{"disable", "DISABLE"}, {"enable", "ENABLE"},
                                                                     {"auto", "AUTO"}};
    auto it = kModes.find(*mode);
    if (it == kModes.end()) {
        std::cerr << "Unknown recording mode: " << *mode << std::endl;
        return 1;
    }
    const Target target{101, MAV_COMP_ID_ONBOARD_COMPUTER};
    const bool success = send_param_set(sender, target, "AIR_RECORDING_E", it->second, MAV_PARAM_EXT_TYPE_CUSTOM);
    std::cout << (success ? "Recording mode sent" : "Failed to send recording mode") << std::endl;
    return success ? 0 : 1;
}

Target parse_target(const std::string &target_name) {
    if (target_name == "air") {
        return Target{101, MAV_COMP_ID_ONBOARD_COMPUTER};
    }
    if (target_name == "ground") {
        return Target{100, MAV_COMP_ID_ONBOARD_COMPUTER};
    }
    throw std::runtime_error("target must be air or ground");
}

int handle_set_wifi(const MavlinkSender &sender, int argc, char **argv) {
    std::optional<std::string> target_name;
    std::optional<std::string> mode;
    std::optional<std::string> hotspot_mode;
    std::optional<std::string> hs_iface;
    std::optional<std::string> cl_iface;
    std::optional<std::string> cl_ssid;
    std::optional<std::string> cl_pw;

    for (int i = 1; i < argc; ++i) {
        std::string arg{argv[i]};
        if (arg == "--target" && i + 1 < argc) {
            target_name = argv[++i];
        } else if (arg == "--mode" && i + 1 < argc) {
            mode = argv[++i];
        } else if (arg == "--hotspot" && i + 1 < argc) {
            hotspot_mode = argv[++i];
        } else if (arg == "--hs-iface" && i + 1 < argc) {
            hs_iface = argv[++i];
        } else if (arg == "--cl-iface" && i + 1 < argc) {
            cl_iface = argv[++i];
        } else if (arg == "--cl-ssid" && i + 1 < argc) {
            cl_ssid = argv[++i];
        } else if (arg == "--cl-pw" && i + 1 < argc) {
            cl_pw = argv[++i];
        }
    }

    if (!target_name) {
        std::cerr << "set-wifi requires --target air|ground" << std::endl;
        return 1;
    }

    Target target{};
    try {
        target = parse_target(*target_name);
    } catch (const std::exception &e) {
        std::cerr << e.what() << std::endl;
        return 1;
    }

    static const std::unordered_map<std::string, int> kMode{
        {"off", 0}, {"hotspot", 1}, {"client", 2},
    };
    static const std::unordered_map<std::string, int> kHotspot{
        {"auto", 0}, {"off", 1}, {"on", 2},
    };

    bool success = true;
    if (mode) {
        auto it = kMode.find(*mode);
        if (it == kMode.end()) {
            std::cerr << "Unknown WiFi mode: " << *mode << std::endl;
            return 1;
        }
        success &= send_param_set(sender, target, "WIFI_MODE", std::to_string(it->second), MAV_PARAM_EXT_TYPE_INT32);
    }
    if (hotspot_mode) {
        auto it = kHotspot.find(*hotspot_mode);
        if (it == kHotspot.end()) {
            std::cerr << "Unknown hotspot mode: " << *hotspot_mode << std::endl;
            return 1;
        }
        success &= send_param_set(sender, target, "WIFI_HOTSPOT_E", std::to_string(it->second), MAV_PARAM_EXT_TYPE_INT32);
    }
    if (hs_iface) {
        success &= send_param_set(sender, target, "WIFI_HS_IFACE", *hs_iface, MAV_PARAM_EXT_TYPE_CUSTOM);
    }
    if (cl_iface) {
        success &= send_param_set(sender, target, "WIFI_CL_IFACE", *cl_iface, MAV_PARAM_EXT_TYPE_CUSTOM);
    }
    if (cl_ssid) {
        success &= send_param_set(sender, target, "WIFI_CL_SSID", *cl_ssid, MAV_PARAM_EXT_TYPE_CUSTOM);
    }
    if (cl_pw) {
        success &= send_param_set(sender, target, "WIFI_CL_PW", *cl_pw, MAV_PARAM_EXT_TYPE_CUSTOM);
    }

    if (!success) {
        std::cerr << "Failed to send some WiFi parameters" << std::endl;
        return 1;
    }
    std::cout << "WiFi parameters sent" << std::endl;
    return 0;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc < 2) {
        print_usage();
        return 1;
    }

    auto ep = parse_endpoint(argc, argv);
    if (!ep) {
        std::cerr << "Failed to parse endpoint" << std::endl;
        return 1;
    }

    const std::string command = argv[1];
    MavlinkSender sender(*ep);

    if (command == "scan") {
        return handle_scan(sender, argc - 1, argv + 1);
    }
    if (command == "set-link") {
        return handle_set_link(sender, argc - 1, argv + 1);
    }
    if (command == "set-video") {
        return handle_set_video(sender, argc - 1, argv + 1);
    }
    if (command == "set-camera") {
        return handle_set_camera(sender, argc - 1, argv + 1);
    }
    if (command == "set-recording") {
        return handle_set_recording(sender, argc - 1, argv + 1);
    }
    if (command == "set-wifi") {
        return handle_set_wifi(sender, argc - 1, argv + 1);
    }

    print_usage();
    return 1;
}
