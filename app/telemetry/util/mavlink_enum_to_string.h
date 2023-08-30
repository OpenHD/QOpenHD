#ifndef MAVLINK_ENUM_TO_STRING_H
#define MAVLINK_ENUM_TO_STRING_H

// A lot of bloat code

#include "mavlink_include.h"
#include <QString>

#include <sstream>

namespace qopenhd {

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
    case SUB_MODE_ENUM_END:
    default:
        break;
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
    default:
        break;
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
    case COPTER_MODE_ZIGZAG:
        return "ZIGZAG";
    default:
        break;
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
    case PLANE_MODE_QACRO:
        return "QAcro";
    case PLANE_MODE_THERMAL:
        return "Thermal";
    default:
        break;
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
    default:
        break;
    }
    return "Unknown";
}

static QString mav_type_to_string(MAV_TYPE type){
    switch(type){
    case MAV_TYPE_DECAROTOR:
        return "DECAROTOR";
    case MAV_TYPE_GENERIC:
        return "GENERIC";
    case MAV_TYPE_FIXED_WING:
        return "FIXED WING";
    case MAV_TYPE_QUADROTOR:
        return "QUADROTOR";
    case MAV_TYPE_COAXIAL:
        return "COAXIAL";
    case MAV_TYPE_HELICOPTER:
        return "HELICOPTER";
    case MAV_TYPE_ANTENNA_TRACKER:
        return "ANTENNA TRACKER";
    case MAV_TYPE_GCS:
        return "GCS";
    case MAV_TYPE_AIRSHIP:
        return "AIRSHIP";
    case MAV_TYPE_FREE_BALLOON:
        return "FREE BALLOON";
    case MAV_TYPE_ROCKET:
        return "ROCKET";
    case MAV_TYPE_GROUND_ROVER:
        return "GROUND ROVER";
    case MAV_TYPE_SURFACE_BOAT:
        return "BOAT";
    case MAV_TYPE_SUBMARINE:
        return "SUBMARINE";
    case MAV_TYPE_HEXAROTOR:
        return "HEXAROTOR";
    case MAV_TYPE_OCTOROTOR:
        return "OCTOROTOR";
    case MAV_TYPE_TRICOPTER:
        return "TRICOPTER";
    case MAV_TYPE_FLAPPING_WING:
        return "FLAPPING WING";
    case MAV_TYPE_KITE:
        return "KITE";
    case MAV_TYPE_ONBOARD_CONTROLLER:
        return "ONBOARD_CONTROLLER";
    case MAV_TYPE_VTOL_TAILSITTER_DUOROTOR:
        return "VTOL_TAILSITTER_DUOROTOR";
    case MAV_TYPE_VTOL_TAILSITTER_QUADROTOR:
        return "VTOL_TAILSITTER_QUADROTOR";
    case MAV_TYPE_VTOL_TILTROTOR:
        return "VTOL_TILTROTOR";
    case MAV_TYPE_VTOL_FIXEDROTOR:
        return "VTOL_FIXEDROTOR";
    case MAV_TYPE_VTOL_TAILSITTER:
        return "VTOL_TAILSITTER";
    //case MAV_TYPE_VTOL_RESERVED4:
    //    return "VTOL_RESERVED4";
    case MAV_TYPE_VTOL_RESERVED5:
        return "VTOL_RESERVED5";
    case MAV_TYPE_GIMBAL:
        return "GIMBAL";
    case MAV_TYPE_ADSB:
        return "ADSB";
    case MAV_TYPE_PARAFOIL:
        return "PARAFOIL";
    case MAV_TYPE_DODECAROTOR:
        return "DODECAROTOR";
    case MAV_TYPE_CAMERA:
        return "CAMERA";
    case MAV_TYPE_CHARGING_STATION:
        return "CHARGING_STATION";
    case MAV_TYPE_FLARM:
        return "FLARM";
    case MAV_TYPE_SERVO:
        return "SERVO";
    case MAV_TYPE_ODID:
        return "ODID";
    case MAV_TYPE_BATTERY:
        return "BATTERY";
    case MAV_TYPE_PARACHUTE:
        return "PARACHUTE";
    case MAV_TYPE_LOG:
        return "LOG";
    case MAV_TYPE_OSD:
        return "OSD";
    case MAV_TYPE_IMU:
        return "IMU";
    case MAV_TYPE_GPS:
        return "GPS";
    case MAV_TYPE_WINCH:
        return "WINCH";
    default:
        break;
    }
    return "Unknown";
}

struct MavTypeAndFlightMode{
    QString mav_type="Unknown"; // Copter, plane, rocket, whatever, specific, e.g. it says Hexacopter if the uav is a hexa (not copter)
    QString flight_mode="Unknown"; // Flight mode for this uav
    // These are for sending the right flight mode commands
    // Weather it is any generic type of "copter,plane or vtol"
    bool is_copter=false;
    bool is_plane=false;
    bool is_vtol=false;
};

static MavTypeAndFlightMode type_and_flight_mode_as_string(MAV_TYPE uav_type,uint32_t custom_mode){
    MavTypeAndFlightMode ret{};
    ret.mav_type=qopenhd::mav_type_to_string(uav_type);
    // We need to know the uav type to infer the flight mode
    ret.flight_mode="Unknown";
    switch (uav_type) {
    case MAV_TYPE_GENERIC: {
        break;
    }
    case MAV_TYPE_FIXED_WING:{
        auto plane_mode = qopenhd::plane_mode_from_enum((PLANE_MODE)custom_mode);
        ret.flight_mode=plane_mode;
        ret.is_plane=true;
        break;
    }
    case MAV_TYPE_QUADROTOR:
    case MAV_TYPE_HEXAROTOR:
    case MAV_TYPE_OCTOROTOR:
    case MAV_TYPE_TRICOPTER:
    case MAV_TYPE_DECAROTOR:
    case MAV_TYPE_DODECAROTOR:
    case MAV_TYPE_HELICOPTER: // Just have it with normal copters for now
    {
        auto copter_mode = qopenhd::copter_mode_from_enum((COPTER_MODE)custom_mode);
        ret.flight_mode=copter_mode;
        ret.is_copter=true;
        break;
    }
    // VTOL support is lacking
    case MAV_TYPE_VTOL_FIXEDROTOR:
    case MAV_TYPE_VTOL_TAILSITTER:
    case MAV_TYPE_VTOL_TILTROTOR:
    case MAV_TYPE_VTOL_TAILSITTER_DUOROTOR:
    case MAV_TYPE_VTOL_TAILSITTER_QUADROTOR:
    {
        auto plane_mode = qopenhd::plane_mode_from_enum((PLANE_MODE)custom_mode);
        ret.flight_mode=plane_mode;
        ret.is_vtol=true;
        break;
    }
    case MAV_TYPE_SUBMARINE: {
        auto sub_mode = qopenhd::sub_mode_from_enum((SUB_MODE)custom_mode);
        ret.flight_mode=sub_mode;
        break;
    }
    case MAV_TYPE_GROUND_ROVER: {
        auto rover_mode = qopenhd::rover_mode_from_enum((ROVER_MODE)custom_mode);
        ret.flight_mode=rover_mode;
        break;
    }
    default:
        break;
    }
    return ret;
}

static std::string battery_type_to_string(uint8_t batt_type){
    switch(batt_type){
    case MAV_BATTERY_TYPE_LIPO:
        return "LiPo";
    case MAV_BATTERY_TYPE_LIFE:
        return "LiFe";
    case  MAV_BATTERY_TYPE_LION:
        return "LiIo";
    case MAV_BATTERY_TYPE_NIMH:
        return "NiMh";
    default:
        break;
    }
    return "N/A";
}

static std::string detailed_battery_voltages_to_string(const uint16_t voltages[10]){
    std::stringstream ss;
    ss<<"Voltages[";
    for(int i=0;i<10;i++){
        const auto voltage=voltages[i];
        if(voltage!=UINT16_MAX){
            if(i!=0){
                ss<<",";
            }
            ss<<(int)voltage;
        }
    }
    ss<<"]";
    return ss.str();
}

static std::string mavlink_command_ack_to_string(const mavlink_command_ack_t& cmd_ack){
    std::stringstream ss;
    ss<<"CMD_ACK{"<<(int)cmd_ack.target_system<<":"<<(int)cmd_ack.target_component<<":"<<cmd_ack.command;
    ss<<",result:"<<(int)cmd_ack.result;
    ss<<":"<<cmd_ack.result_param2;
    ss<<"]";
    return ss.str();
}

static bool flight_mode_is_copter(const MAV_TYPE& type){
    return type==MAV_TYPE_TRICOPTER || type==MAV_TYPE_QUADROTOR || type==MAV_TYPE_HEXAROTOR || type==MAV_TYPE_OCTOROTOR
               || type==MAV_TYPE_DECAROTOR || type==MAV_TYPE_DODECAROTOR;
}
static bool flight_mode_is_plane(const MAV_TYPE& type){
    return type==MAV_TYPE_FIXED_WING;
}

}

#endif // MAVLINK_ENUM_TO_STRING_H
