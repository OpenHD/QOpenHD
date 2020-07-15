#ifndef UTIL_H
#define UTIL_H

#include <QObject>
#include <QMap>
#include <QVariant>

#include <openhd/mavlink.h>


int lipo_battery_voltage_to_percent(int cells, double voltage);
int lifepo4_battery_voltage_to_percent(int cells, double voltage);
QString battery_gauge_glyph_from_percentage(int percent);

QString sub_mode_from_enum(SUB_MODE mode);
QString rover_mode_from_enum(ROVER_MODE mode);
QString copter_mode_from_enum(COPTER_MODE mode);
QString plane_mode_from_enum(PLANE_MODE mode);
QString tracker_mode_from_enum(TRACKER_MODE mode);

QString vot_mode_from_telemetry(uint8_t mode);

QString ltm_mode_from_telem(int mode);

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

QString px4_mode_from_custom_mode(int custom_mode);

uint map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end);

#if defined(__android__)
void keep_screen_on(bool on);
#endif

int default_mavlink_sysid();

#endif // UTIL_H
