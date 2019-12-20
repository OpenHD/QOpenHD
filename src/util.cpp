#ifndef UTIL_CPP
#define UTIL_CPP

#include "util.h"

#if defined(__android__)
#include <QtAndroidExtras/QtAndroid>
#include <QAndroidJniEnvironment>
#endif

int lipo_battery_voltage_to_percent(int cells, double voltage) {
    double cell_voltage = voltage / static_cast<double>(cells);

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

QString battery_gauge_glyph_from_percentage(int percent) {
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

QString sub_mode_from_enum(SUB_MODE mode) {
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
            break;
    }
    return "Unknown";
}

QString rover_mode_from_enum(ROVER_MODE mode) {
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
       case ROVER_MODE_ENUM_END:
            break;
    }
    return "Unknown";
}

QString copter_mode_from_enum(COPTER_MODE mode) {
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
       case COPTER_MODE_ENUM_END:
            break;
    }
    return "Unknown";
}

QString plane_mode_from_enum(PLANE_MODE mode) {
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
       case PLANE_MODE_ENUM_END:
            break;
    }
    return "Unknown";
}


QString tracker_mode_from_enum(TRACKER_MODE mode) {
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
       case TRACKER_MODE_ENUM_END:
            break;
    }
    return "Unknown";
}

uint map(double input, double input_start, double input_end, uint16_t output_start, uint16_t output_end) {
    double input_range = input_end - input_start;
    int output_range = output_end - output_start;

    return (input - input_start)*output_range / input_range + output_start;
}

#if defined(__android__)
void keep_screen_on(bool on) {
    QtAndroid::runOnAndroidThread([on] {
        QAndroidJniObject activity = QtAndroid::androidActivity();
        if (activity.isValid()) {
            QAndroidJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");

            if (window.isValid()) {
                const int FLAG_KEEP_SCREEN_ON = 128;
                if (on) {
                    window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                } else {
                    window.callMethod<void>("clearFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
                }
            }
        }
        QAndroidJniEnvironment env;
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        }
    });
}
#endif

#endif // UTIL_CPP
