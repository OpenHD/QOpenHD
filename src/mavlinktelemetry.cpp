#include "mavlinktelemetry.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#ifndef __windows__
#include <unistd.h>
#endif

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include <openhd/mavlink.h>

#include "util.h"
#include "constants.h"

#include "openhd.h"
#include "powermicroservice.h"

#include "localmessage.h"

static MavlinkTelemetry* _instance = nullptr;

MavlinkTelemetry* MavlinkTelemetry::instance() {
    if (_instance == nullptr) {
        _instance = new MavlinkTelemetry();
    }
    return _instance;
}

MavlinkTelemetry::MavlinkTelemetry(QObject *parent): MavlinkBase(parent) {
    qDebug() << "MavlinkTelemetry::MavlinkTelemetry()";
    targetSysID1 = 1;
    targetSysID2 = 0;
    targetCompID1 = MAV_COMP_ID_AUTOPILOT1;
    targetCompID2 = MAV_COMP_ID_SYSTEM_CONTROL;
    // betaflight
    targetCompID3 = 200;

    localPort = 14550;

    #if defined(__rasp_pi__)
    groundAddress = "127.0.0.1";
    #endif

    connect(this, &MavlinkTelemetry::setup, this, &MavlinkTelemetry::onSetup);

}

void MavlinkTelemetry::onSetup() {
    qDebug() << "MavlinkTelemetry::onSetup()";

    connect(this, &MavlinkTelemetry::processMavlinkMessage, this, &MavlinkTelemetry::onProcessMavlinkMessage);

    pause_telemetry=false;

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &MavlinkTelemetry::stateLoop);
    resetParamVars();
    timer->start(200);
}

void MavlinkTelemetry::pauseTelemetry(bool toggle) {
    pause_telemetry=toggle;
}

void MavlinkTelemetry::onProcessMavlinkMessage(mavlink_message_t msg) {

    if(pause_telemetry==true){
        return;
    }

    switch (msg.msgid) {
            case MAVLINK_MSG_ID_HEARTBEAT: {
                    mavlink_heartbeat_t heartbeat;
                    mavlink_msg_heartbeat_decode(&msg, &heartbeat);
                    //MAV_STATE state = (MAV_STATE)heartbeat.system_status;
                    MAV_MODE_FLAG mode = (MAV_MODE_FLAG)heartbeat.base_mode;

                    if (mode & MAV_MODE_FLAG_SAFETY_ARMED) {
                        // armed
                        OpenHD::instance()->set_armed(true);
                    } else {
                        OpenHD::instance()->set_armed(false);
                    }

                    auto custom_mode = heartbeat.custom_mode;

                    auto autopilot = (MAV_AUTOPILOT)heartbeat.autopilot;

                    switch (autopilot) {
                        case MAV_AUTOPILOT_GENERIC: {
                            break;
                        }
                        case MAV_AUTOPILOT_PX4: {
                            if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                                auto px4_mode = px4_mode_from_custom_mode(custom_mode);
                                OpenHD::instance()->set_flight_mode(px4_mode);
                            }
                            break;
                        }
                        case MAV_AUTOPILOT_ARDUPILOTMEGA: {
                            if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                                auto uav_type = heartbeat.type;

                                switch (uav_type) {
                                    case MAV_TYPE_GENERIC: {
                                        break;
                                    }
                                    case MAV_TYPE_FIXED_WING: {
                                        auto plane_mode = plane_mode_from_enum((PLANE_MODE)custom_mode);
                                        OpenHD::instance()->set_flight_mode(plane_mode);
                                        //qDebug() << "Mavlink Mav Type= PLANE";
                                        break;
                                    }
                                    case MAV_TYPE_GROUND_ROVER: {
                                        auto rover_mode = rover_mode_from_enum((ROVER_MODE)custom_mode);
                                        OpenHD::instance()->set_flight_mode(rover_mode);
                                        break;
                                    }
                                    case MAV_TYPE_QUADROTOR: {
                                        auto copter_mode = copter_mode_from_enum((COPTER_MODE)custom_mode);
                                        OpenHD::instance()->set_flight_mode(copter_mode);
                                        //qDebug() << "Mavlink Mav Type= QUADROTOR";
                                        break;
                                    }
                                    case MAV_TYPE_SUBMARINE: {
                                        auto sub_mode = sub_mode_from_enum((SUB_MODE)custom_mode);
                                        OpenHD::instance()->set_flight_mode(sub_mode);
                                        break;
                                    }
                                    case MAV_TYPE_ANTENNA_TRACKER: {
                                        auto tracker_mode = tracker_mode_from_enum((TRACKER_MODE)custom_mode);
                                        //OpenHD::instance()->set_tracker_mode(tracker_mode);
                                        break;
                                    }
                                    default: {
                                        // do nothing
                                    }
                                }
                            }
                            break;
                        }
                        default: {
                            break;
                        }
                    }

                    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

                    last_heartbeat_timestamp = current_timestamp;
                    break;
                }

        case MAVLINK_MSG_ID_SYS_STATUS: {
            mavlink_sys_status_t sys_status;
            mavlink_msg_sys_status_decode(&msg, &sys_status);

            auto battery_voltage = (double)sys_status.voltage_battery / 1000.0;
            OpenHD::instance()->set_battery_voltage(battery_voltage);

            OpenHD::instance()->set_battery_current(sys_status.current_battery);

            OpenHD::instance()->updateAppMah();

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            OpenHD::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
            OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            mavlink_system_time_t sys_time;
            mavlink_msg_system_time_decode(&msg, &sys_time);
            uint32_t boot_time = sys_time.time_boot_ms;

            if (boot_time != m_last_boot) {
                m_last_boot = boot_time;
            }

            break;
        }
        case MAVLINK_MSG_ID_PARAM_VALUE:{
            mavlink_param_value_t param;
            mavlink_msg_param_value_decode(&msg, &param);

            parameterCount = param.param_count;
            parameterIndex = param.param_index;

            parameterLastReceivedTime = QDateTime::currentMSecsSinceEpoch();

            QByteArray param_id(param.param_id, 16);
            /*
             * If there's no null in the param_id array, the mavlink docs say it has to be exactly 16 characters,
             * so we add a null to the end and then continue. This guarantees that QString below will always find
             * a null terminator.
             *
             */
            if (!param_id.contains('\0')) {
               param_id.append('\0');
            }

            QString s(param_id.data());

            m_allParameters.insert(s, QVariant(param.param_value));
            break;
        }
        case MAVLINK_MSG_ID_GPS_RAW_INT:{
            mavlink_gps_raw_int_t gps_status;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
            OpenHD::instance()->set_satellites_visible(gps_status.satellites_visible);
            OpenHD::instance()->set_gps_hdop(gps_status.eph / 100.0);
            break;
        }
        case MAVLINK_MSG_ID_GPS_STATUS: {
            break;
        }
        case MAVLINK_MSG_ID_RAW_IMU:{
            break;
        }
        case MAVLINK_MSG_ID_SCALED_PRESSURE:{
        mavlink_scaled_pressure_t raw_imu;
        mavlink_msg_scaled_pressure_decode(&msg, &raw_imu);

        OpenHD::instance()->set_fc_temp((int)raw_imu.temperature/100);
        //qDebug() << "Temp:" <<  raw_imu.temperature;
            break;
        }
        case MAVLINK_MSG_ID_ATTITUDE:{
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode (&msg, &attitude);

            OpenHD::instance()->set_pitch((double)attitude.pitch *57.2958);
            //qDebug() << "Pitch:" <<  attitude.pitch*57.2958;

            OpenHD::instance()->set_roll((double)attitude.roll *57.2958);
            //qDebug() << "Roll:" <<  attitude.roll*57.2958;
            break;
        }
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
            break;
        }
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

            OpenHD::instance()->set_lat((double)global_position.lat / 10000000.0);
            OpenHD::instance()->set_lon((double)global_position.lon / 10000000.0);

            OpenHD::instance()->set_boot_time(global_position.time_boot_ms);

            OpenHD::instance()->set_alt_rel(global_position.relative_alt/1000.0);
            // qDebug() << "Altitude relative " << alt_rel;
            OpenHD::instance()->set_alt_msl(global_position.alt/1000.0);

            // FOR INAV heading does not /100
            QSettings settings;
            auto _heading_inav = settings.value("heading_inav", false).toBool();
            if(_heading_inav==true){
                OpenHD::instance()->set_hdg(global_position.hdg);
            }
            else{
                OpenHD::instance()->set_hdg(global_position.hdg / 100);
            }
            OpenHD::instance()->set_vx(global_position.vx/100.0);
            OpenHD::instance()->set_vy(global_position.vy/100.0);
            OpenHD::instance()->set_vz(global_position.vz/100.0);

            OpenHD::instance()->findGcsPosition();
            OpenHD::instance()->calculate_home_distance();
            OpenHD::instance()->calculate_home_course();

            OpenHD::instance()->updateFlightDistance();

            OpenHD::instance()->updateLateralSpeed();

            OpenHD::instance()->updateWind();

            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
            mavlink_rc_channels_raw_t rc_channels_raw;
            mavlink_msg_rc_channels_raw_decode(&msg, &rc_channels_raw);

            auto rssi = static_cast<int>(static_cast<double>(rc_channels_raw.rssi) / 255.0 * 100.0);
            OpenHD::instance()->set_rc_rssi(rssi);

            break;
        }
        case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:{
            break;
        }
        case MAVLINK_MSG_ID_MISSION_CURRENT:{
            break;
        }
        case MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN:{
            break;
        }
        case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:{
            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS:{
            mavlink_rc_channels_t rc_channels;
            mavlink_msg_rc_channels_decode(&msg, &rc_channels);

            OpenHD::instance()->set_control_pitch(rc_channels.chan2_raw);
            OpenHD::instance()->set_control_roll(rc_channels.chan1_raw);
            OpenHD::instance()->set_control_throttle(rc_channels.chan3_raw);
            OpenHD::instance()->set_control_yaw(rc_channels.chan4_raw);

            OpenHD::instance()->setRCChannel1(rc_channels.chan1_raw);
            OpenHD::instance()->setRCChannel2(rc_channels.chan2_raw);
            OpenHD::instance()->setRCChannel3(rc_channels.chan3_raw);
            OpenHD::instance()->setRCChannel4(rc_channels.chan4_raw);
            OpenHD::instance()->setRCChannel5(rc_channels.chan5_raw);
            OpenHD::instance()->setRCChannel6(rc_channels.chan6_raw);
            OpenHD::instance()->setRCChannel7(rc_channels.chan7_raw);
            OpenHD::instance()->setRCChannel8(rc_channels.chan8_raw);

            auto rssi = static_cast<int>(static_cast<double>(rc_channels.rssi) / 255.0 * 100.0);
            OpenHD::instance()->set_rc_rssi(rssi);

            /*qDebug() << "RC: " << rc_channels.chan1_raw
                                 << rc_channels.chan2_raw
                                 << rc_channels.chan3_raw
                                 << rc_channels.chan4_raw
                                 << rc_channels.chan5_raw
                                 << rc_channels.chan6_raw
                                 << rc_channels.chan7_raw
                                 << rc_channels.chan8_raw
                                 << rc_channels.chan9_raw
                                 << rc_channels.chan10_raw;*/
            break;
        }
        case MAVLINK_MSG_ID_VFR_HUD:{
            mavlink_vfr_hud_t vfr_hud;
            mavlink_msg_vfr_hud_decode (&msg, &vfr_hud);

            OpenHD::instance()->set_throttle(vfr_hud.throttle);

            auto airspeed = vfr_hud.airspeed*3.6;
            OpenHD::instance()->set_airspeed(airspeed);

            auto speed = vfr_hud.groundspeed*3.6;
            OpenHD::instance()->set_speed(speed);
            // qDebug() << "Speed- ground " << speed;

            auto vsi = vfr_hud.climb;
            OpenHD::instance()->set_vsi(vsi);
            // qDebug() << "VSI- " << vsi;

            break;
        }
        case MAVLINK_MSG_ID_TIMESYNC:{
            break;
        }
        case MAVLINK_MSG_ID_POWER_STATUS:{
            break;
        }
        case MAVLINK_MSG_ID_TERRAIN_REPORT:{
            break;
        }
    case MAVLINK_MSG_ID_WIND:{
        //slight change to naming convention due to prexisting "wind" that is calculated by us..
        mavlink_wind_t mav_wind;
        mavlink_msg_wind_decode(&msg, &mav_wind);

        OpenHD::instance()->set_mav_wind_direction(mav_wind.direction);
        OpenHD::instance()->set_mav_wind_speed(mav_wind.speed);


        /*qDebug() << "Windmavdir: " << mav_wind.direction;
        qDebug() << "Windmavspd: " << mav_wind.speed;*/


        break;
    }
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery_status;
            mavlink_msg_battery_status_decode(&msg, &battery_status);

            OpenHD::instance()->set_flight_mah(battery_status.current_consumed);

            int total_voltage = 0;
            for (int cell = 0; cell < 10; cell++) {
                int cell_voltage  = battery_status.voltages[cell];
                if (cell_voltage != UINT16_MAX) {
                    // qDebug() << "Battery cell voltage " << cell << " :" << cell_voltage;
                    total_voltage += cell_voltage;
                }
            }
            break;
        }
        case MAVLINK_MSG_ID_SENSOR_OFFSETS: {
            break;
        }
        case MAVLINK_MSG_ID_MEMINFO: {
            break;
        }
        case MAVLINK_MSG_ID_MOUNT_STATUS: {
            break;
        }
        case MAVLINK_MSG_ID_AHRS: {
            break;
        }
        case MAVLINK_MSG_ID_HWSTATUS: {
            break;
        }
        case MAVLINK_MSG_ID_AHRS2: {
            break;
        }
        case MAVLINK_MSG_ID_AHRS3: {
            break;
        }
        case MAVLINK_MSG_ID_MAG_CAL_REPORT: {
            break;
        }
        case MAVLINK_MSG_ID_EKF_STATUS_REPORT: {
            break;
        }
        case MAVLINK_MSG_ID_VIBRATION:{
        mavlink_vibration_t vibration;
        mavlink_msg_vibration_decode (&msg, &vibration);

        OpenHD::instance()->set_vibration_x(vibration.vibration_x);
        OpenHD::instance()->set_vibration_y(vibration.vibration_y);
        OpenHD::instance()->set_vibration_z(vibration.vibration_z);

        OpenHD::instance()->set_clipping_x(vibration.clipping_0);
        OpenHD::instance()->set_clipping_y(vibration.clipping_1);
        OpenHD::instance()->set_clipping_z(vibration.clipping_2);
            break;
        }
        case MAVLINK_MSG_ID_SCALED_IMU2:{
            break;
        }
        case MAVLINK_MSG_ID_SCALED_IMU3:{
            break;
        }
        case MAVLINK_MSG_ID_SIMSTATE:{
            break;
        }
        case MAVLINK_MSG_ID_HOME_POSITION:{
            mavlink_home_position_t home_position;
            mavlink_msg_home_position_decode(&msg, &home_position);
            OpenHD::instance()->set_homelat((double)home_position.latitude / 10000000.0);
            OpenHD::instance()->set_homelon((double)home_position.longitude / 10000000.0);
            LocalMessage::instance()->showMessage("Home Position set by OpenHD", 2);
            break;
        }
        case MAVLINK_MSG_ID_STATUSTEXT: {
            mavlink_statustext_t statustext;
            mavlink_msg_statustext_decode(&msg, &statustext);
            int level = 0;
            switch (statustext.severity) {
                case MAV_SEVERITY_EMERGENCY:
                    level = 7;
                    break;
                case MAV_SEVERITY_ALERT:
                    level = 6;
                    break;
                case MAV_SEVERITY_CRITICAL:
                    level = 5;
                    break;
                case MAV_SEVERITY_ERROR:
                    level = 4;
                    break;
                case MAV_SEVERITY_WARNING:
                    level = 3;
                    break;
                case MAV_SEVERITY_NOTICE:
                    level = 2;
                    break;
                case MAV_SEVERITY_INFO:
                    level = 1;
                    break;
                case MAV_SEVERITY_DEBUG:
                    level = 0;
                    break;
                default:
                    break;
            }

            QByteArray param_id(statustext.text, 50);
            /*
             * If there's no null in the text array, the mavlink docs say it has to be exactly 50 characters,
             * so we add a null to the end and then continue. This guarantees that QString below will always find
             * a null terminator.
             *
             */
            if (!param_id.contains('\0')) {
               param_id.append('\0');
            }

            QString s(param_id.data());

            OpenHD::instance()->messageReceived(s, level);
            break;
        }
        case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4: {
            break;
        }
        default: {
            printf("MavlinkTelemetry received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}

