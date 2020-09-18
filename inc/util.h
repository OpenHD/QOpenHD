#ifndef UTIL_H
#define UTIL_H

#include <QObject>

#include <openhd/mavlink.h>

#define M_PIf       3.14159265358979323846f


class OpenHDUtil: public QObject {
    Q_OBJECT

public:
    explicit OpenHDUtil(QObject *parent = nullptr);

    Q_INVOKABLE int lipo_battery_voltage_to_percent(int cells, double voltage);
    Q_INVOKABLE int lifepo4_battery_voltage_to_percent(int cells, double voltage);
    Q_INVOKABLE QString battery_gauge_glyph_from_percentage(int percent);

    Q_INVOKABLE QString sub_mode_from_enum(SUB_MODE mode);
    Q_INVOKABLE QString rover_mode_from_enum(ROVER_MODE mode);
    Q_INVOKABLE QString copter_mode_from_enum(COPTER_MODE mode);
    Q_INVOKABLE QString plane_mode_from_enum(PLANE_MODE mode);
    Q_INVOKABLE QString tracker_mode_from_enum(TRACKER_MODE mode);

    Q_INVOKABLE QString vot_mode_from_telemetry(uint8_t mode);

    Q_INVOKABLE QString ltm_mode_from_telem(int mode);

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

    Q_INVOKABLE QString px4_mode_from_custom_mode(int custom_mode);

    Q_INVOKABLE uint map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end);

    typedef struct pt1Filter_s {
        float state;
        float RC;
        float dT;
    } pt1Filter_t;

    Q_INVOKABLE static float pt1FilterApply4(OpenHDUtil::pt1Filter_t *filter, float input, float f_cut, float dT);

    #if defined(__android__)
    Q_INVOKABLE void keep_screen_on(bool on);
    #endif

    Q_INVOKABLE int default_mavlink_sysid();
};

#endif // UTIL_H
