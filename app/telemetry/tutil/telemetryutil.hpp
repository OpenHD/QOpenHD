#ifndef TELEMETRYUTIL_H
#define TELEMETRYUTIL_H

#include <QString>
#include <QDebug>

#include "mavlink_include.h"
#include "../../common/TimeHelper.hpp"
#include "../../common/StringHelper.hpp"
#include "mavlink_enum_to_string.h"
#include <cstring>
#include <optional>
#include <array>

// Various utility methods for telemetry that are static and take simple imputs.
namespace Telemetryutil{

static int lipo_battery_voltage_to_percent(int cells, double voltage){
    const double cell_voltage = voltage / static_cast<double>(cells);
    if (cell_voltage >= 4.2) {
        return 100;
    } else if (cell_voltage >= 4.15) {
        return 95;
    } else if (cell_voltage >= 4.11) {
        return 90;
    } else if (cell_voltage >= 4.08) {
        return 85;
    } else if (cell_voltage >= 4.02) {
        return 80;
    } else if (cell_voltage >= 3.98) {
        return 75;
    } else if (cell_voltage >= 3.95) {
        return 70;
    } else if (cell_voltage >= 3.91) {
        return 65;
    } else if (cell_voltage >= 3.87) {
        return 60;
    } else if (cell_voltage >= 3.85) {
        return 55;
    } else if (cell_voltage >= 3.84) {
        return 50;
    } else if (cell_voltage >= 3.82) {
        return 45;
    } else if (cell_voltage >= 3.80) {
        return 40;
    } else if (cell_voltage >= 3.79) {
        return 35;
    } else if (cell_voltage >= 3.77) {
        return 30;
    } else if (cell_voltage >= 3.75) {
        return 25;
    } else if (cell_voltage >= 3.73) {
        return 20;
    } else if (cell_voltage >= 3.71) {
        return 15;
    } else if (cell_voltage >= 3.69) {
        return 10;
    } else if (cell_voltage >= 3.61) {
        return 5;
    } else {
        return 0;
    }
}
static int lifepo4_battery_voltage_to_percent(int cells, double voltage){
    const double cell_voltage = voltage / static_cast<double>(cells);
    if (cell_voltage >= 3.40) {
        return 100;
    } else if (cell_voltage >= 3.20) {
        return 95;
    } else if (cell_voltage >= 3.19) {
        return 90;
    } else if (cell_voltage >= 3.18) {
        return 85;
    } else if (cell_voltage >= 3.17) {
        return 80;
    } else if (cell_voltage >= 3.16) {
        return 75;
    } else if (cell_voltage >= 3.15) {
        return 70;
    } else if (cell_voltage >= 3.14) {
        return 65;
    } else if (cell_voltage >= 3.13) {
        return 60;
    } else if (cell_voltage >= 3.12) {
        return 55;
    } else if (cell_voltage >= 3.11) {
        return 50;
    } else if (cell_voltage >= 3.10) {
        return 45;
    } else if (cell_voltage >= 3.09) {
        return 40;
    } else if (cell_voltage >= 3.08) {
        return 35;
    } else if (cell_voltage >= 3.07) {
        return 30;
    } else if (cell_voltage >= 3.06) {
        return 25;
    } else if (cell_voltage >= 3.05) {
        return 20;
    } else if (cell_voltage >= 3.04) {
        return 15;
    } else if (cell_voltage >= 3.03) {
        return 10;
    } else if (cell_voltage >= 3.02) {
        return 5;
    } else {
        return 0;
    }
}

static QString battery_gauge_glyph_from_percentage(int percent){
    percent = (percent / 5) * 5;
    // these are Material Design Icon codepoints from the battery gauge icon set
    switch (percent) {
        case 100:return "\uf079";
        case 95: return "\uf082";
        case 90: return "\uf082";
        case 85: return "\uf081";
        case 80: return "\uf081";
        case 75: return "\uf080";
        case 70: return "\uf080";
        case 65: return "\uf07f";
        case 60: return "\uf07f";
        case 55: return "\uf07e";
        case 50: return "\uf07e";
        case 45: return "\uf07d";
        case 40: return "\uf07d";
        case 35: return "\uf07c";
        case 30: return "\uf07c";
        case 25: return "\uf07b";
        case 20: return "\uf07b";
        case 15: return "\uf07a";
        case 10: return "\uf083";
        case 5:  return "\uf083";
        case 0:  return "\uf083";
        default: return "\uf091";
    }
}


enum PX4_CUSTOM_MAIN_MODE {
    PX4_CUSTOM_MAIN_MODE_MANUAL = 1,
    PX4_CUSTOM_MAIN_MODE_ALTCTL,
    PX4_CUSTOM_MAIN_MODE_POSCTL,
    PX4_CUSTOM_MAIN_MODE_AUTO,
    PX4_CUSTOM_MAIN_MODE_ACRO,
    PX4_CUSTOM_MAIN_MODE_OFFBOARD,
    PX4_CUSTOM_MAIN_MODE_STABILIZED,
    PX4_CUSTOM_MAIN_MODE_RATTITUDE,
    PX4_CUSTOM_MAIN_MODE_SIMPLE
};

enum PX4_CUSTOM_SUB_MODE_AUTO {
    PX4_CUSTOM_SUB_MODE_AUTO_READY = 1,
    PX4_CUSTOM_SUB_MODE_AUTO_TAKEOFF,
    PX4_CUSTOM_SUB_MODE_AUTO_LOITER,
    PX4_CUSTOM_SUB_MODE_AUTO_MISSION,
    PX4_CUSTOM_SUB_MODE_AUTO_RTL,
    PX4_CUSTOM_SUB_MODE_AUTO_LAND,
    PX4_CUSTOM_SUB_MODE_AUTO_RESERVED_DO_NOT_USE,
    PX4_CUSTOM_SUB_MODE_AUTO_FOLLOW_TARGET,
    PX4_CUSTOM_SUB_MODE_AUTO_PRECLAND
};

enum PX4_CUSTOM_SUB_MODE_POSCTL {
    PX4_CUSTOM_SUB_MODE_POSCTL_POSCTL = 0,
    PX4_CUSTOM_SUB_MODE_POSCTL_ORBIT
};

union px4_custom_mode {
    struct {
        uint16_t reserved;
        uint8_t main_mode;
        uint8_t sub_mode;
    };
    uint32_t data;
    float data_float;
    struct {
        uint16_t reserved_hl;
        uint16_t custom_mode_hl;
    };
};
static QString px4_mode_from_custom_mode(int custom_mode){
    union px4_custom_mode px4_mode;
    px4_mode.data = custom_mode;
    const auto main_mode = px4_mode.main_mode;
    switch (main_mode) {
        case PX4_CUSTOM_MAIN_MODE_MANUAL: {
            return "Manual";
        }
        case PX4_CUSTOM_MAIN_MODE_ALTCTL: {
            return "Altitude Control";
        }
        case PX4_CUSTOM_MAIN_MODE_POSCTL: {
            switch (px4_mode.sub_mode) {
                case PX4_CUSTOM_SUB_MODE_POSCTL_POSCTL: {
                    return "Position Control";
                }
                case PX4_CUSTOM_SUB_MODE_POSCTL_ORBIT: {
                    return "Position Control Orbit";
                }
                default: {
                    break;
                }
            }

            break;
        }
        case PX4_CUSTOM_MAIN_MODE_AUTO: {
            switch (px4_mode.sub_mode) {
                case PX4_CUSTOM_SUB_MODE_AUTO_READY: {
                    return "Auto Ready";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_TAKEOFF: {
                    return "Takeoff";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_LOITER: {
                    return "Auto Loiter";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_MISSION: {
                    return "Auto Mission";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_RTL: {
                    return "Auto RTL";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_LAND: {
                    return "Auto Land";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_RESERVED_DO_NOT_USE: {
                    break;
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_FOLLOW_TARGET: {
                    return "Auto Follow Tgt";
                }
                case PX4_CUSTOM_SUB_MODE_AUTO_PRECLAND: {
                    return "Auto Precision Land";
                }
                default: {
                    break;
                }
            }
            break;
        }
        case PX4_CUSTOM_MAIN_MODE_ACRO: {
            return "Acro";
        }
        case PX4_CUSTOM_MAIN_MODE_OFFBOARD: {
            return "Offboard";
        }
        case PX4_CUSTOM_MAIN_MODE_STABILIZED: {
            return "Stabilized";
        }
        case PX4_CUSTOM_MAIN_MODE_RATTITUDE: {
            return "Rattitude";
        }
        case PX4_CUSTOM_MAIN_MODE_SIMPLE: {
            return "Simple";
        }
        default: {
            break;
        }
    }
    return "Unknown";
}

struct XLogMessage{
    std::string message;
    int level;
};
static XLogMessage statustext_convert(const mavlink_statustext_t& parsedMsg){
    QByteArray tmp_msg(parsedMsg.text,50);
    if (!tmp_msg.contains('\0')) {
       tmp_msg.append('\0');
    }
    std::string s(tmp_msg.data());
    return XLogMessage{s,parsedMsg.severity};
}

static std::array<int,18> mavlink_msg_rc_channels_override_to_array(const mavlink_rc_channels_override_t& parsedMsg){
    std::array<int,18> ret{};
    ret[0]=parsedMsg.chan1_raw;
    ret[1]=parsedMsg.chan2_raw;
    ret[2]=parsedMsg.chan3_raw;
    ret[3]=parsedMsg.chan4_raw;
    ret[4]=parsedMsg.chan5_raw;
    ret[5]=parsedMsg.chan6_raw;
    ret[6]=parsedMsg.chan7_raw;
    ret[7]=parsedMsg.chan8_raw;
    ret[8]=parsedMsg.chan9_raw;
    ret[9]=parsedMsg.chan10_raw;
    ret[10]=parsedMsg.chan11_raw;
    ret[11]=parsedMsg.chan12_raw;
    ret[12]=parsedMsg.chan13_raw;
    ret[13]=parsedMsg.chan14_raw;
    ret[14]=parsedMsg.chan15_raw;
    ret[15]=parsedMsg.chan16_raw;
    ret[16]=parsedMsg.chan17_raw;
    ret[17]=parsedMsg.chan18_raw;
    return ret;
}

static std::array<int,18> mavlink_msg_rc_channels_to_array(const mavlink_rc_channels_t& parsedMsg){
    std::array<int,18> ret{};
    ret[0]=parsedMsg.chan1_raw;
    ret[1]=parsedMsg.chan2_raw;
    ret[2]=parsedMsg.chan3_raw;
    ret[3]=parsedMsg.chan4_raw;
    ret[4]=parsedMsg.chan5_raw;
    ret[5]=parsedMsg.chan6_raw;
    ret[6]=parsedMsg.chan7_raw;
    ret[7]=parsedMsg.chan8_raw;
    ret[8]=parsedMsg.chan9_raw;
    ret[9]=parsedMsg.chan10_raw;
    ret[10]=parsedMsg.chan11_raw;
    ret[11]=parsedMsg.chan12_raw;
    ret[12]=parsedMsg.chan13_raw;
    ret[13]=parsedMsg.chan14_raw;
    ret[14]=parsedMsg.chan15_raw;
    ret[15]=parsedMsg.chan16_raw;
    ret[16]=parsedMsg.chan17_raw;
    ret[17]=parsedMsg.chan18_raw;
    return ret;
}

static std::array<int,18> mavlink_msg_rc_channels_raw_to_array(const mavlink_rc_channels_raw_t& parsedMsg){
    std::array<int,18> ret{};
    ret[0]=parsedMsg.chan1_raw;
    ret[1]=parsedMsg.chan2_raw;
    ret[2]=parsedMsg.chan3_raw;
    ret[3]=parsedMsg.chan4_raw;
    ret[4]=parsedMsg.chan5_raw;
    ret[5]=parsedMsg.chan6_raw;
    ret[6]=parsedMsg.chan7_raw;
    ret[7]=parsedMsg.chan8_raw;
    // Has only 8 channels
    return ret;
}

// Taken from mavsdk
static constexpr double MAVSDK_PI = 3.14159265358979323846;
static double to_deg_from_rad(double rad)
{
    return static_cast<double>(180.0) / static_cast<double>(MAVSDK_PI) * rad;
}

// For MAVLINK_MSG_ID_ATTITUDE
// aka example Roll angle (-pi..+pi)
static float angle_mavlink_rad_to_degree(float angle_rad){
    auto degree=to_deg_from_rad(angle_rad);
    return static_cast<float>(degree);
}

// mavlink defines the rc rssi value commonly the following way:
// Receive signal strength indicator in device-dependent units/scale. Values: [0-254], UINT8_MAX: invalid/unknown.
// We use percent in the osd, with -1 for N/A
static int mavlink_rc_rssi_to_percent(uint8_t rssi){
    if(rssi==UINT8_MAX)return -1;
    const auto rssi_perc =static_cast<int>(static_cast<double>(rssi) / 254.0 * 100.0);
    return rssi_perc;
}


// Humungus switch case, mostly legacy code. Annoying, but at least broken out of fcmavlinksystem now.
struct HeartBeatInfo{
    QString autopilot="Unknown";
    QString flight_mode="Unknown";
    // Used to figure out ardupilot flight mode(s)
    int ardupilot_mav_type=-1;
    QString mav_type="Unknown";
    // These are for sending the right flight mode commands
    // Weather it is any type of "copter,plane or vtol"
    bool is_arducopter=false;
    bool is_arduplane=false;
    bool is_arduvtol=false;
};
static std::optional<HeartBeatInfo> parse_heartbeat(const mavlink_heartbeat_t& heartbeat){
    HeartBeatInfo info{};
    const auto custom_mode = heartbeat.custom_mode;
    const auto autopilot = (MAV_AUTOPILOT)heartbeat.autopilot;
    switch (autopilot) {
    case MAV_AUTOPILOT_PX4: {
       info.autopilot="Pixhawk";
       // Pixhawk does their own thing
       if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                    auto px4_mode = Telemetryutil::px4_mode_from_custom_mode(custom_mode);
                    info.flight_mode=px4_mode;
       }
       info.mav_type=QString("PX4?");
       break;
    }
    case MAV_AUTOPILOT_GENERIC: // inav for example
    case MAV_AUTOPILOT_ARDUPILOTMEGA: // This is ardu - something regardless of the board (not only ardupilotmega)
    {
       if(autopilot==MAV_AUTOPILOT_GENERIC){
            info.autopilot="Generic";
       }else{
            info.autopilot="ARDU";
       }
       if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
            auto uav_type = heartbeat.type;
            auto type_and_flight_mode=qopenhd::type_and_flight_mode_as_string((MAV_TYPE)uav_type,custom_mode);
            info.flight_mode=type_and_flight_mode.flight_mode;
            info.mav_type=type_and_flight_mode.mav_type;
            if(autopilot==MAV_AUTOPILOT_ARDUPILOTMEGA){
                if(type_and_flight_mode.is_copter){
                    info.is_arducopter=true;
                }else if(type_and_flight_mode.is_plane){
                    info.is_arduplane=true;
                }else if(type_and_flight_mode.is_vtol){
                    info.is_arduvtol=true;
                }
                info.ardupilot_mav_type=uav_type;
            }
       }
       break;
    }
    default: {
       // this returns to prevent heartbeats from devices other than an autopilot from setting
       // the armed/disarmed flag or resetting the last heartbeat timestamp
       return std::nullopt;
    }
    }
    return info;
}

// See https://mavlink.io/en/messages/common.html#GPS_FIX_TYPE
static QString mavlink_gps_fix_type_to_string(const uint8_t fix_type){
    switch(fix_type){
        case GPS_FIX_TYPE_NO_GPS: return "No GPS";
        case GPS_FIX_TYPE_NO_FIX: return "No Fix";
        case GPS_FIX_TYPE_2D_FIX: return "2D Fix";
        case GPS_FIX_TYPE_3D_FIX: return "3D Fix";
        case GPS_FIX_TYPE_DGPS: return "DGPS";
        case GPS_FIX_TYPE_RTK_FLOAT: return "RTK f";
        case GPS_FIX_TYPE_RTK_FIXED: return "RTK F";
        case GPS_FIX_TYPE_STATIC: return "Static";
        case GPS_FIX_TYPE_PPP: return "PPP";
    default:break;
    }
    return "Unknown";
}

// See https://mavlink.io/en/messages/common.html#MAV_MISSION_TYPE
static QString mavlink_mission_type_to_string(const uint8_t mission_type){
    switch(mission_type){
        case MAV_MISSION_TYPE_MISSION: return "Primary mission";
        case MAV_MISSION_TYPE_FENCE: return "Fence";
        case MAV_MISSION_TYPE_RALLY: return "Rally";
        case MAV_MISSION_TYPE_ALL: return "ALL";
    default:break;
    }
    return "MT_Unknown";
}

static QString mavlink_frame_to_string(const uint8_t frame){
    switch(frame){
    case MAV_FRAME_GLOBAL: return "FRAME_GLOBAL";
    case MAV_FRAME_GLOBAL_RELATIVE_ALT: return "FRAME_GLOBAL_RELATIVE_ALT";
    default: break;
    }
    std::stringstream ss;
    ss<<"FRAME_UNKNOWN("<<(int)frame<<")";
    return ss.str().c_str();
}

static bool get_arm_mode_from_heartbeat(const mavlink_heartbeat_t& heartbeat){
    const MAV_MODE_FLAG mode = (MAV_MODE_FLAG)heartbeat.base_mode;
    if (mode & MAV_MODE_FLAG_SAFETY_ARMED) {
        // armed
        return true;
    }
    return false;
}

static int calculate_efficiency_in_mah_per_km(const double delta_mah,const double delta_km){
    //qDebug()<<"delta_mah:"<<delta_mah<<" delta_km:"<<delta_km;
    if(delta_km<=0)return 0;
    double ret=delta_mah/delta_km;
    return std::round(ret);
}

// Brings the given angle into the [0,360[ range
static float normalize_degree(float degree){
    degree = std::fmod(degree,360);
    if (degree < 0) degree += 360;
    if (degree >= 360) degree -=360;
    return degree;
}

static QString bitrate_bps_to_qstring(int64_t bitrate_bits_per_second){
    return QString{StringHelper::bitrate_to_string(bitrate_bits_per_second).c_str()};
}
static QString bitrate_kbits_to_qstring(int64_t bitrate_kbits_per_second){
    return QString{StringHelper::bitrate_to_string(bitrate_kbits_per_second*1000).c_str()};
}

static QString pps_to_string(int64_t packets_per_second){
    return QString((std::to_string(packets_per_second)+" pps").c_str());
}
static QString us_min_max_avg_to_string(int32_t min_us,int32_t max_us,int32_t avg_us){
    std::stringstream ss;
    ss<<"Min:"<<MyTimeHelper::R(std::chrono::microseconds(min_us))<<", ";
    ss<<"Max:"<<MyTimeHelper::R(std::chrono::microseconds(max_us));
    ss<<"Avg:"<<MyTimeHelper::R(std::chrono::microseconds(avg_us))<<", ";
    return QString(ss.str().c_str());
}
static QString min_max_avg_to_string(int32_t min,int32_t max,int32_t avg){
    std::stringstream ss;
    ss<<"min:"<<min<<", ";
    ss<<"max:"<<max<<", ";
    ss<<"avg:"<<avg;
    return QString(ss.str().c_str());
}

}

#endif // TELEMETRYUTIL_H
