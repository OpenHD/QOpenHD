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

uint map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end);

#if defined(__android__)
void keep_screen_on(bool on);
#endif

int default_mavlink_sysid();

#endif // UTIL_H
