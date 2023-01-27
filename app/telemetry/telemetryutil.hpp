#ifndef TELEMETRYUTIL_H
#define TELEMETRYUTIL_H

#include <QString>

#include "../telemetry/mavsdk_include.h"

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

static QString sub_mode_from_enum(SUB_MODE mode){
    switch (mode) {
       case SUB_MODE_MANUAL:
            return "Manual";
       case SUB_MODE_ACRO:
            return "Acro";
       case SUB_MODE_AUTO:
            return "Auto";
       case SUB_MODE_GUIDED:
            return "Guided";
       case SUB_MODE_STABILIZE:
            return "Stabilize";
       case SUB_MODE_ALT_HOLD:
            return "Alt Hold";
       case SUB_MODE_CIRCLE:
            return "Circle";
       case SUB_MODE_SURFACE:
            return "Surface";
       case SUB_MODE_POSHOLD:
            return "Position Hold";
    }
    return "Unknown";
}

static QString rover_mode_from_enum(ROVER_MODE mode){
    switch (mode) {
       case ROVER_MODE_HOLD:
            return "Hold";
       case ROVER_MODE_MANUAL:
            return "Manual";
       case ROVER_MODE_STEERING:
            return "Steering";
       case ROVER_MODE_INITIALIZING:
            return "Initializing";
       case ROVER_MODE_SMART_RTL:
            return "Smart RTL";
       case ROVER_MODE_ACRO:
            return "Acro";
       case ROVER_MODE_AUTO:
            return "Auto";
       case ROVER_MODE_RTL:
            return "RTL";
       case ROVER_MODE_LOITER:
            return "Loiter";
       case ROVER_MODE_GUIDED:
            return "Guided";
    }
    return "Unknown";
}

static QString copter_mode_from_enum(COPTER_MODE mode){
    switch (mode) {
        case COPTER_MODE_LAND:
             return "Landing";
       case COPTER_MODE_FLIP:
            return "Flip";
       case COPTER_MODE_BRAKE:
            return "Brake";
       case COPTER_MODE_DRIFT:
            return "Drift";
       case COPTER_MODE_SPORT:
            return "Sport";
       case COPTER_MODE_THROW:
            return "Throw";
       case COPTER_MODE_POSHOLD:
            return "Position Hold";
       case COPTER_MODE_ALT_HOLD:
            return "Altitude Hold";
       case COPTER_MODE_SMART_RTL:
            return "Smart RTL";
       case COPTER_MODE_GUIDED_NOGPS:
            return "Guided (NOGPS)";
       case COPTER_MODE_CIRCLE:
            return "Circle";
       case COPTER_MODE_STABILIZE:
            return "Stabilize";
       case COPTER_MODE_ACRO:
            return "Acro";
       case COPTER_MODE_AUTOTUNE:
            return "Autotune";
       case COPTER_MODE_AUTO:
            return "Auto";
       case COPTER_MODE_RTL:
            return "RTL";
       case COPTER_MODE_LOITER:
            return "Loiter";
       case COPTER_MODE_AVOID_ADSB:
            return "Avoid ADSB";
       case COPTER_MODE_GUIDED:
            return "Guided";
    }
    return "Unknown";
}

static QString plane_mode_from_enum(PLANE_MODE mode){
    switch (mode) {
       case PLANE_MODE_MANUAL:
            return "Manual";
       case PLANE_MODE_CIRCLE:
            return "Circle";
       case PLANE_MODE_STABILIZE:
            return "Stabilize";
       case PLANE_MODE_TRAINING:
            return "Training";
       case PLANE_MODE_ACRO:
            return "Acro";
       case PLANE_MODE_FLY_BY_WIRE_A:
            return "Fly By Wire A";
       case PLANE_MODE_FLY_BY_WIRE_B:
            return "Fly By Wire B";
       case PLANE_MODE_CRUISE:
            return "Cruise";
       case PLANE_MODE_AUTOTUNE:
            return "Autotune";
       case PLANE_MODE_AUTO:
            return "Auto";
       case PLANE_MODE_RTL:
            return "RTL";
       case PLANE_MODE_LOITER:
            return "Loiter";
       case PLANE_MODE_TAKEOFF:
            return "Takeoff";
       case PLANE_MODE_AVOID_ADSB:
            return "Avoid ADSB";
       case PLANE_MODE_GUIDED:
            return "Guided";
       case PLANE_MODE_INITIALIZING:
            return "Initializing";
       case PLANE_MODE_QSTABILIZE:
            return "QStabilize";
       case PLANE_MODE_QHOVER:
            return "QHover";
       case PLANE_MODE_QLOITER:
            return "QLoiter";
       case PLANE_MODE_QLAND:
            return "QLand";
       case PLANE_MODE_QRTL:
            return "QRTL";
       case PLANE_MODE_QAUTOTUNE:
            return "QAutotune";
    }
    return "Unknown";
}

static QString tracker_mode_from_enum(TRACKER_MODE mode){
    switch (mode) {
       case TRACKER_MODE_MANUAL:
            return "Manual";
       case TRACKER_MODE_STOP:
            return "Stop";
       case TRACKER_MODE_SCAN:
            return "Scan";
       case TRACKER_MODE_SERVO_TEST:
            return "Servo Test";
       case TRACKER_MODE_AUTO:
            return "Auto";
       case TRACKER_MODE_INITIALIZING:
            return "Initializing";
    }
    return "Unknown";
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

    auto main_mode = px4_mode.main_mode;

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

static constexpr auto  X_PIf=3.14159265358979323846f;
typedef struct pt1Filter_s {
    float state;
    float RC;
    float dT;
} pt1Filter_t;

static float pt1FilterApply4(Telemetryutil::pt1Filter_t *filter, float input, float f_cut, float dT){
    // Pre calculate and store RC
    if (!filter->RC) {
        filter->RC = 1.0f / ( 2.0f * X_PIf * f_cut );
    }

    filter->dT = dT;    // cache latest dT for possible use in pt1FilterApply
    filter->state = filter->state + dT / (filter->RC + dT) * (input - filter->state);
    return filter->state;
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

}

#endif // TELEMETRYUTIL_H
