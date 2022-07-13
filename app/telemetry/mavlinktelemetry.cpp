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

#include "../util/util.h"
#include "../logging/logmessagesmodel.h"
#include <sstream>

#include "openhd_defines.hpp"
#include "qopenhdmavlinkhelper.hpp"

#include "openhd.h"
#include "openhd_systems/ohdsystemair.h"
#include "openhd_systems/ohdsystemground.h"

MavlinkTelemetry* MavlinkTelemetry::instance() {
    static MavlinkTelemetry instance;
    return &instance;
}

MavlinkTelemetry::MavlinkTelemetry(QObject *parent){
    qDebug() << "MavlinkTelemetry::MavlinkTelemetry()";
    mOHDConnection=std::make_unique<OHDConnection>(nullptr,false);
    mOHDConnection->registerNewMessageCalback([this](mavlink_message_t msg){
        //qDebug()<<"this->onProcessMavlinkMessage";
        this->onProcessMavlinkMessage(msg);
    });
    targetCompID = MAV_COMP_ID_AUTOPILOT1;
    pause_telemetry=false;
}


void MavlinkTelemetry::sendCommand(MavlinkCommand command)
{
    qDebug()<<"TODO sendCommand";
}

void MavlinkTelemetry::sendRC()
{
    QSettings settings;
    bool enable_rc = settings.value("enable_rc", false).toBool();
    //temporarily dsabled
    if(true){
        return;
    }
    if (enable_rc == true){
        mavlink_message_t msg;
        mavlink_msg_rc_channels_override_pack(QOpenHDMavlinkHelper::getSysId(), MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID, targetCompID,
                                              m_rc_values[0],m_rc_values[1],m_rc_values[2],m_rc_values[3],m_rc_values[4],m_rc_values[5],m_rc_values[6],m_rc_values[7],
                m_rc_values[8],m_rc_values[9],m_rc_values[10],m_rc_values[11],m_rc_values[12],m_rc_values[13],m_rc_values[14],m_rc_values[15],
                m_rc_values[16],m_rc_values[17]);
            sendData(msg);
    }
    else {
        return;
    }
}

void MavlinkTelemetry::sendData(mavlink_message_t msg)
{
    mOHDConnection->sendMessage(msg);
}

void MavlinkTelemetry::pauseTelemetry(bool toggle) {
    pause_telemetry=toggle;
    //qDebug() << "PAUSE TELEMTRY CALLED";
}

void MavlinkTelemetry::requested_Flight_Mode_Changed(int mode) {
    m_mode=mode;
    qDebug() << "MavlinkTelemetry::requested_Flight_Mode_Changed="<< m_mode;
    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = MAV_CMD_DO_SET_MODE;
    command.long_param1 = MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    command.long_param2 = m_mode;
    sendCommand(command);

}

void MavlinkTelemetry::requested_ArmDisarm_Changed(int arm_disarm) {
    m_arm_disarm=arm_disarm;
    qDebug() << "MavlinkTelemetry::requested_ArmDisarm_Changed="<< m_arm_disarm;
    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = MAV_CMD_COMPONENT_ARM_DISARM ;
    command.long_param1 = m_arm_disarm;
    //command.long_param2 = m_arm_disarm;
    sendCommand(command);
}

void MavlinkTelemetry::FC_Reboot_Shutdown_Changed(int reboot_shutdown) {
    m_reboot_shutdown=reboot_shutdown;
    qDebug() << "MavlinkTelemetry::FC_Reboot_Shutdown_Changed="<< m_reboot_shutdown;

    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN ;
    command.long_param1 = m_reboot_shutdown;
    //command.long_param2 = m_arm_disarm;
    sendCommand(command);
}


void MavlinkTelemetry::rc_value_changed(int channelIdx,uint channelValue){
    if(channelIdx > 0 && channelIdx < m_rc_values.size()){
        m_rc_values.at(channelIdx)=channelValue;
        qDebug() << "MavlinkTelemetry::rc"<<channelIdx<<"="<< channelValue;
        emit update_RC_MavlinkBase (m_rc_values);
    }else{
        qDebug()<<"Error mavlink channel out of bounds"<<channelIdx;
    }
}



void MavlinkTelemetry::onProcessMavlinkMessage(mavlink_message_t msg) {
    //qDebug()<<"MavlinkTelemetry::onProcessMavlinkMessage"<<msg.msgid;
    //if(pause_telemetry==true){
    //    return;
    //}
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
            const auto time_millis=QOpenHDMavlinkHelper::getTimeMilliseconds();
            if(msg.sysid==OHD_SYS_ID_AIR){
                OHDSystemAir::instance().set_last_openhd_heartbeat(time_millis);
                return;
            }else if(msg.sysid==OHD_SYS_ID_GROUND){
                OHDSystemGround::instance().set_last_openhd_heartbeat(time_millis);
                return;
            }

            auto custom_mode = heartbeat.custom_mode;

            auto autopilot = (MAV_AUTOPILOT)heartbeat.autopilot;

            //upon first heartbeat find out if autopilot is ardupilot or "other"
            if (!sent_autopilot_request){
                requestAutopilotInfo();
                sent_autopilot_request=true;
            }

            switch (autopilot) {
                case MAV_AUTOPILOT_PX4: {
                    if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                        auto px4_mode = m_util.px4_mode_from_custom_mode(custom_mode);
                       OpenHD::instance().set_flight_mode(px4_mode);
                    }
                    break;
                }
                case MAV_AUTOPILOT_GENERIC:
                case MAV_AUTOPILOT_ARDUPILOTMEGA: {
                    if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                        auto uav_type = heartbeat.type;

                        switch (uav_type) {
                            case MAV_TYPE_GENERIC: {
                                break;
                            }
                            case MAV_TYPE_FIXED_WING: {
                                auto plane_mode = m_util.plane_mode_from_enum((PLANE_MODE)custom_mode);
                               OpenHD::instance().set_flight_mode(plane_mode);

                               OpenHD::instance().set_mav_type("ARDUPLANE");

                                /* autopilot detecton not reliable
                                if(ap_version>999){
                                   OpenHD::instance().set_mav_type("ARDUPLANE");
                                    //qDebug() << "Mavlink Mav Type= ARDUPLANE";
                                }
                                else{
                                   OpenHD::instance().set_mav_type("UKNOWN PLANE");
                                }
                                */
                                break;
                            }
                            case MAV_TYPE_GROUND_ROVER: {
                                auto rover_mode = m_util.rover_mode_from_enum((ROVER_MODE)custom_mode);
                               OpenHD::instance().set_flight_mode(rover_mode);
                                break;
                            }
                            case MAV_TYPE_QUADROTOR: {
                                auto copter_mode = m_util.copter_mode_from_enum((COPTER_MODE)custom_mode);
                               OpenHD::instance().set_flight_mode(copter_mode);

                               OpenHD::instance().set_mav_type("ARDUCOPTER");

                                /* autopilot detection not reliable
                                if(ap_version>999){
                                   OpenHD::instance().set_mav_type("ARDUCOPTER");
                                    //qDebug() << "Mavlink Mav Type= ARDUCOPTER";
                                }
                                else {
                                   OpenHD::instance().set_mav_type("UNKNOWN COPTER");
                                }
                                */
                                break;
                            }
                            case MAV_TYPE_SUBMARINE: {
                                auto sub_mode = m_util.sub_mode_from_enum((SUB_MODE)custom_mode);
                               OpenHD::instance().set_flight_mode(sub_mode);
                                break;
                            }
                            case MAV_TYPE_ANTENNA_TRACKER: {
                                auto tracker_mode = m_util.tracker_mode_from_enum((TRACKER_MODE)custom_mode);
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
                    // this returns to prevent heartbeats from devices other than an autopilot from setting
                    // the armed/disarmed flag or resetting the last heartbeat timestamp
                    return;
                }
            }

            //MAV_STATE state = (MAV_STATE)heartbeat.system_status;
            MAV_MODE_FLAG mode = (MAV_MODE_FLAG)heartbeat.base_mode;

            if (mode & MAV_MODE_FLAG_SAFETY_ARMED) {
                // armed
               OpenHD::instance().set_armed(true);
            } else {
               OpenHD::instance().set_armed(false);
            }

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            last_heartbeat_timestamp = current_timestamp;
            break;
        }

        case MAVLINK_MSG_ID_AUTOPILOT_VERSION: {
            mavlink_autopilot_version_t autopilot_version;
            mavlink_msg_autopilot_version_decode(&msg, &autopilot_version);

            ap_version = autopilot_version.flight_sw_version;
            auto ap_board_version = autopilot_version.board_version;
            auto ap_os_version = autopilot_version.os_sw_version;
            auto ap_product_id = autopilot_version.product_id;
            auto ap_uid = autopilot_version.uid;

            qDebug() << "MAVLINK AUTOPILOT VERSION=" <<  ap_version;
            qDebug() << "MAVLINK AUTOPILOT board_version=" <<  ap_board_version;
            qDebug() << "MAVLINK AUTOPILOT os_version=" <<  ap_os_version;
            qDebug() << "MAVLINK AUTOPILOT product_id=" <<  ap_product_id;
            qDebug() << "MAVLINK AUTOPILOT uid=" <<  ap_uid;
            break;
        }

        case MAVLINK_MSG_ID_SYS_STATUS: {
            mavlink_sys_status_t sys_status;
            mavlink_msg_sys_status_decode(&msg, &sys_status);

            auto battery_voltage = (double)sys_status.voltage_battery / 1000.0;
           OpenHD::instance().set_battery_voltage(battery_voltage);

           OpenHD::instance().set_battery_current(sys_status.current_battery);

           OpenHD::instance().updateAppMah();

           OpenHD::instance().updateAppMahKm();

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = m_util.lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            //OpenHD::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_percent);
            //OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            last_battery_timestamp = current_timestamp;
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            mavlink_system_time_t sys_time;
            mavlink_msg_system_time_decode(&msg, &sys_time);
            uint32_t boot_time = sys_time.time_boot_ms;

            if (boot_time < m_last_boot || m_last_boot == 0) {
                m_last_boot = boot_time;
                qDebug() << "setDataStreamRate and requestAutopilotInfo called";
                setDataStreamRate(MAV_DATA_STREAM_EXTENDED_STATUS, 2);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA1, 10);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA2, 5);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA3, 3);
                setDataStreamRate(MAV_DATA_STREAM_POSITION, 3);
                setDataStreamRate(MAV_DATA_STREAM_RAW_SENSORS, 2);
                setDataStreamRate(MAV_DATA_STREAM_RC_CHANNELS, 2);
            }

            break;
        }
        case MAVLINK_MSG_ID_PARAM_VALUE:{
            // handled by params mavsdk
            break;
        }
        case MAVLINK_MSG_ID_GPS_RAW_INT:{
            mavlink_gps_raw_int_t gps_status;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
           OpenHD::instance().set_satellites_visible(gps_status.satellites_visible);
           OpenHD::instance().set_gps_hdop(gps_status.eph / 100.0);
           OpenHD::instance().set_gps_fix_type((unsigned int)gps_status.fix_type);
            break;
        }
        case MAVLINK_MSG_ID_GPS_STATUS: {
            break;
        }
        case MAVLINK_MSG_ID_SCALED_IMU:{
            break;
        }
        case MAVLINK_MSG_ID_RAW_IMU:{
            mavlink_raw_imu_t raw_imu;
            mavlink_msg_raw_imu_decode(&msg, &raw_imu);
           OpenHD::instance().set_imu_temp((int)raw_imu.temperature/100);
            break;
        }
        case MAVLINK_MSG_ID_SCALED_PRESSURE:{
            mavlink_scaled_pressure_t scaled_pressure;
            mavlink_msg_scaled_pressure_decode(&msg, &scaled_pressure);

           OpenHD::instance().set_press_temp((int)scaled_pressure.temperature/100);
            //qDebug() << "Temp:" <<  scaled_pressure.temperature;
            break;
        }
        case MAVLINK_MSG_ID_ATTITUDE:{
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode (&msg, &attitude);

           OpenHD::instance().set_pitch((double)attitude.pitch *57.2958);
            //qDebug() << "Pitch:" <<  attitude.pitch*57.2958;

           OpenHD::instance().set_roll((double)attitude.roll *57.2958);
            //qDebug() << "Roll:" <<  attitude.roll*57.2958;

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            last_attitude_timestamp = current_timestamp;
            break;
        }
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
            break;
        }
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

           OpenHD::instance().set_lat((double)global_position.lat / 10000000.0);
           OpenHD::instance().set_lon((double)global_position.lon / 10000000.0);

           OpenHD::instance().set_boot_time(global_position.time_boot_ms);

           OpenHD::instance().set_alt_rel(global_position.relative_alt/1000.0);
            // qDebug() << "Altitude relative " << alt_rel;
           OpenHD::instance().set_alt_msl(global_position.alt/1000.0);

            // FOR INAV heading does not /100
            QSettings settings;
            auto _heading_inav = settings.value("heading_inav", false).toBool();
            if(_heading_inav==true){
               OpenHD::instance().set_hdg(global_position.hdg);
            }
            else{
               OpenHD::instance().set_hdg(global_position.hdg / 100);
            }
           OpenHD::instance().set_vx(global_position.vx/100.0);
           OpenHD::instance().set_vy(global_position.vy/100.0);
           OpenHD::instance().set_vz(global_position.vz/100.0);

           OpenHD::instance().findGcsPosition();
           OpenHD::instance().calculate_home_distance();
           OpenHD::instance().calculate_home_course();

           OpenHD::instance().updateFlightDistance();

           OpenHD::instance().updateVehicleAngles();

           OpenHD::instance().updateWind();

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            last_gps_timestamp = current_timestamp;

            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
            mavlink_rc_channels_raw_t rc_channels_raw;
            mavlink_msg_rc_channels_raw_decode(&msg, &rc_channels_raw);

            auto rssi = static_cast<int>(static_cast<double>(rc_channels_raw.rssi) / 255.0 * 100.0);
           OpenHD::instance().setRcRssi(rssi);

            break;
        }
        case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:{
            break;
        }
        case MAVLINK_MSG_ID_MISSION_CURRENT:{
            break;
        }
        case MAVLINK_MSG_ID_MISSION_COUNT:{
            break;
        }
        case MAVLINK_MSG_ID_MISSION_ITEM_INT:{
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

            // TODO
            /*OpenHD::instance()->set_control_pitch(rc_channels.chan2_raw);
           OpenHD::instance().set_control_roll(rc_channels.chan1_raw);
           OpenHD::instance().set_control_throttle(rc_channels.chan3_raw);
           OpenHD::instance().set_control_yaw(rc_channels.chan4_raw);*/

            auto rssi = static_cast<int>(static_cast<double>(rc_channels.rssi) / 255.0 * 100.0);
           OpenHD::instance().setRcRssi(rssi);

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

           OpenHD::instance().set_throttle(vfr_hud.throttle);

            auto airspeed = vfr_hud.airspeed*3.6;
           OpenHD::instance().set_airspeed(airspeed);

            auto speed = vfr_hud.groundspeed*3.6;
           OpenHD::instance().set_speed(speed);
            // qDebug() << "Speed- ground " << speed;

            auto vsi = vfr_hud.climb;
           OpenHD::instance().set_vsi(vsi);
            // qDebug() << "VSI- " << vsi;

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            last_vfr_timestamp = current_timestamp;

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

           OpenHD::instance().set_mav_wind_direction(mav_wind.direction);
           OpenHD::instance().set_mav_wind_speed(mav_wind.speed);


            /*qDebug() << "Windmavdir: " << mav_wind.direction;
            qDebug() << "Windmavspd: " << mav_wind.speed;*/


            break;
        }
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery_status;
            mavlink_msg_battery_status_decode(&msg, &battery_status);

           OpenHD::instance().set_flight_mah(battery_status.current_consumed);

            int total_voltage = 0;
            int cell_count;
            for (cell_count = 0; ( (cell_count < MAVLINK_MSG_BATTERY_STATUS_FIELD_VOLTAGES_LEN)
                                 && (battery_status.voltages[cell_count] != UINT16_MAX) ); cell_count++) {
                total_voltage += battery_status.voltages[cell_count];
            }

//            QSettings settings;
//            if (cell_count && (cell_count != settings.value("battery_cells", QVariant(3)).toInt()) ) {
//                LocalMessage::instance()->showMessage("Battery Cells updated by Telemetry", 7);
//                settings.setValue("battery_cells", QVariant(cell_count));
//                settings.sync();
//            }

           OpenHD::instance().set_fc_battery_percent(battery_status.battery_remaining);
            QString fc_battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_status.battery_remaining);
           OpenHD::instance().set_fc_battery_gauge(fc_battery_gauge_glyph);
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
        case MAVLINK_MSG_ID_AOA_SSA: {
            break;
        }
        case MAVLINK_MSG_ID_VIBRATION:{
            mavlink_vibration_t vibration;
            mavlink_msg_vibration_decode (&msg, &vibration);

           OpenHD::instance().set_vibration_x(vibration.vibration_x);
           OpenHD::instance().set_vibration_y(vibration.vibration_y);
           OpenHD::instance().set_vibration_z(vibration.vibration_z);

           OpenHD::instance().set_clipping_x(vibration.clipping_0);
           OpenHD::instance().set_clipping_y(vibration.clipping_1);
           OpenHD::instance().set_clipping_z(vibration.clipping_2);
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
        case MAVLINK_MSG_ID_POSITION_TARGET_GLOBAL_INT:{
            break;
        }
        case MAVLINK_MSG_ID_SCALED_PRESSURE2:{
            break;
        }
        case MAVLINK_MSG_ID_HOME_POSITION:{
            mavlink_home_position_t home_position;
            mavlink_msg_home_position_decode(&msg, &home_position);
           OpenHD::instance().set_homelat((double)home_position.latitude / 10000000.0);
           OpenHD::instance().set_homelon((double)home_position.longitude / 10000000.0);
            //LocalMessage::instance()->showMessage("Home Position set by Telemetry", 7);
            break;
        }
        case MAVLINK_MSG_ID_STATUSTEXT: {
            mavlink_statustext_t statustext;
            mavlink_msg_statustext_decode(&msg, &statustext);
            const QString s=QOpenHDMavlinkHelper::safe_string(statustext.text,sizeof(statustext.text));
            if(msg.sysid==OHD_SYS_ID_AIR || msg.sysid == OHD_SYS_ID_GROUND){
                // the message is a log message from openhd
                //qDebug()<<"Log message from OpenHD:"<<s;
                LogMessagesModel::instance().addLogMessage("OHD",s,statustext.severity);

            }else{
                // most likely from the flight controller, but can be someone else, too
                 //qDebug()<<"Log message from not OpenHD:"<<s;
                OpenHD::instance().telemetryMessage(s, statustext.severity);
            }
            break;
        }
        case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4: {
            mavlink_esc_telemetry_1_to_4_t esc_telemetry;
            mavlink_msg_esc_telemetry_1_to_4_decode(&msg, &esc_telemetry);

           OpenHD::instance().set_esc_temp((int)esc_telemetry.temperature[0]);
            break;
        }
        case MAVLINK_MSG_ID_ADSB_VEHICLE: {
            break;
        }
    case MAVLINK_MSG_ID_PING:{
        mavlink_ping_t ping;
        mavlink_msg_ping_decode(&msg, &ping);
        //qDebug()<<"Got ping message sender:"<<msg.sysid<<":"<<msg.compid<<" target:"<<ping.target_system<<":"<<ping.target_component<<"seq:"<<ping.seq;
        // We only process ping responses with our specific sys id and a matching sequence number.
        // Note that if the user clicks the ping multiple times in rapid succession, some pings might be dropped.
        // Check if the ping is targeted at our system
        if(ping.seq==pingSequenceNumber && ping.target_system==QOpenHDMavlinkHelper::getSysId()){
            const auto delta=QOpenHDMavlinkHelper::getTimeMicroseconds()-ping.time_usec;
            const float deltaMs=delta/1000.0f;
            std::stringstream ss;
            ss<<deltaMs<<"ms";
            if(msg.sysid==OHD_SYS_ID_AIR){
                OHDSystemAir::instance().set_last_ping_result_openhd_air(ss.str().c_str());
            }else if(msg.sysid==OHD_SYS_ID_GROUND){
                OHDSystemGround::instance().set_last_ping_result_openhd_ground(ss.str().c_str());
            }else{
                qDebug()<<"Got ping from fc";
                // almost 100% from flight controller
                // TODO make sure
                //if(msg.compid==MAV_COMP_ID_AUTOPILOT1)
               OpenHD::instance().set_last_ping_result_flight_ctrl(ss.str().c_str());
            }
        }else{
            //qDebug()<<"Got ping message sender:"<<msg.sysid<<":"<<msg.compid<<" target:"<<ping.target_system<<":"<<ping.target_component<<"seq:"<<ping.seq;
        }
        break;
    }
    case MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS:{
        mavlink_onboard_computer_status_t decoded;
        mavlink_msg_onboard_computer_status_decode(&msg,&decoded);
        if(msg.sysid==OHD_SYS_ID_AIR){
            OHDSystemAir::instance().set_cpuload_air(decoded.cpu_cores[0]);
            OHDSystemAir::instance().set_temp_air(decoded.temperature_core[0]);
        }else if(msg.sysid==OHD_SYS_ID_GROUND){
            OHDSystemGround::instance().set_cpuload_gnd(decoded.cpu_cores[0]);
            OHDSystemGround::instance().set_temp_gnd(decoded.temperature_core[0]);
        }else{
            qDebug()<<"Sys tele with unknown sys id";
        }
        break;
    }
    case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE:{
        mavlink_openhd_version_message_t parsedMsg;
        mavlink_msg_openhd_version_message_decode(&msg,&parsedMsg);
        QString version(parsedMsg.version);
        if(msg.sysid==OHD_SYS_ID_AIR){
            OHDSystemAir::instance().set_openhd_version_air(version);
        }else if(msg.sysid==OHD_SYS_ID_GROUND){
            OHDSystemGround::instance().set_openhd_version_ground(version);
        }else{
            qDebug()<<"OHD version with unknown sys id";
        }
        break;
    }
    case MAVLINK_MSG_ID_OPENHD_WIFIBROADCAST_STATISTICS:{
        mavlink_openhd_wifibroadcast_statistics_t parsedMsg;
        mavlink_msg_openhd_wifibroadcast_statistics_decode(&msg,&parsedMsg);
        //OpenHD::instance()->setWifiAdapter0(parsedMsg.count_p_all,0,0);
        //OHDSystemGround::instance().set_wifi_adapter0(parsedMsg.count_p_all,13,1);
        //OHDSystemAir::instance().set_wifi_adapter(13,33,1);
        //qDebug()<<"kkkk"<<parsedMsg.count_p_all;
        break;
    }
    case MAVLINK_MSG_ID_OPENHD_WIFI_CARD:{
        mavlink_openhd_wifi_card_t parsedMsg;
        mavlink_msg_openhd_wifi_card_decode(&msg,&parsedMsg);
        //qDebug()<<"Got MAVLINK_MSG_ID_OPENHD_WIFI_CARD"<<(int)parsedMsg.card_index<<" "<<(int)parsedMsg.signal_millidBm;
        if(msg.sysid==OHD_SYS_ID_AIR){
            if(parsedMsg.card_index==0){
                OHDSystemAir::instance().set_wifi_adapter(parsedMsg.count_p_received,parsedMsg.signal_millidBm,true);
            }
        }else if(msg.sysid==OHD_SYS_ID_GROUND){
             OHDSystemGround::instance().set_wifi_adapter(parsedMsg.card_index,parsedMsg.count_p_received,parsedMsg.signal_millidBm,true);
        }
        break;
    }
    /*case MAVLINK_MSG_ID_OPENHD_LOG_MESSAGE:{
        mavlink_openhd_log_message_t parsedMsg;
        mavlink_msg_openhd_log_message_decode(&msg,&parsedMsg);
        const QString message{parsedMsg.text};
        const quint64 timestamp=parsedMsg.timestamp;
        const quint8 severity=parsedMsg.severity;
        qDebug()<<"Log message:"<<message;
        LogMessagesModel::instance().addLogMessage({"OHD",message,timestamp,LogMessagesModel::log_severity_to_color(severity)});
        break;
    }*/
    break;
        default: {
            //printf("MavlinkTelemetry received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            qDebug()<<"MavlinkTelemetry received unmatched message with ID "<<msg.msgid
                   <<", sequence: "<<msg.seq
                  <<" from component "<<msg.compid
                 <<" of system "<<msg.sysid;
            break;
        }
    }
}

void MavlinkTelemetry::pingAllSystems()
{
    pingSequenceNumber++;
    mavlink_message_t msg;
    mavlink_msg_ping_pack(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(),&msg,QOpenHDMavlinkHelper::getTimeMicroseconds(),pingSequenceNumber,0,0);
    sendData(msg);
}

void MavlinkTelemetry::setDataStreamRate(MAV_DATA_STREAM streamType, uint8_t hz) {
    auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
    mavlink_message_t msg;
    msg.sysid = mavlink_sysid;
    msg.compid = MAV_COMP_ID_MISSIONPLANNER;
    /*
     * This only sends the message to sysid 1 compid 1 because nothing else responds to this
     * message anyway, iNav uses a fixed rate and so does betaflight
     *
     */
    mavlink_msg_request_data_stream_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, 1, MAV_COMP_ID_AUTOPILOT1, streamType, hz, 1);
    sendData(msg);
}

void MavlinkTelemetry::requestAutopilotInfo()
{
    qDebug() << "MavlinkTelemetry::request_Autopilot_Info";
    auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
    mavlink_message_t msg;
    mavlink_msg_autopilot_version_request_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID,targetCompID);
    sendData(msg);
}

void MavlinkTelemetry::get_Mission_Items(int count)
{
    qDebug() << "MavlinkBase::get_Mission_Items total="<< count;
    auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
    mavlink_message_t msg;
    int current_seq;
    for (current_seq = 1; current_seq < count; ++current_seq){
        //qDebug() << "MavlinkBase::get_Mission_Items current="<< current_seq;
        mavlink_msg_mission_request_int_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID,targetCompID,current_seq,0);
        sendData(msg);
    }
}

void MavlinkTelemetry::send_Mission_Ack()
{
    qDebug() << "MavlinkBase::send_Mission_Ack";
    auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
    mavlink_message_t msg;
    mavlink_msg_mission_ack_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID,targetCompID,0,0);
    sendData(msg);
}

void MavlinkTelemetry::request_Mission_Changed()
{
    qDebug() << "MavlinkTelemetry::request_Mission_Changed";
    auto mavlink_sysid= QOpenHDMavlinkHelper::getSysId();
    mavlink_message_t msg;
    mavlink_msg_mission_request_list_pack(mavlink_sysid, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID,targetCompID,0);
    sendData(msg);
}

bool MavlinkTelemetry::isConnectionLost() {
    /* we want to know if a heartbeat has been received (not -1, the default)
       but not in the last 5 seconds.*/
    if (m_last_heartbeat > -1 && m_last_heartbeat < 5000) {
        return false;
    }
    return true;
}

void MavlinkTelemetry::set_last_heartbeat(qint64 last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}

void MavlinkTelemetry::set_last_attitude(qint64 last_attitude) {
    m_last_attitude = last_attitude;
    emit last_attitude_changed(m_last_attitude);
}

void MavlinkTelemetry::set_last_battery(qint64 last_battery) {
    m_last_battery = last_battery;
    emit last_battery_changed(m_last_battery);
}

void MavlinkTelemetry::set_last_gps(qint64 last_gps) {
    m_last_gps = last_gps;
    emit last_gps_changed(m_last_gps);
}

void MavlinkTelemetry::set_last_vfr(qint64 last_vfr) {
    m_last_vfr = last_vfr;
    emit last_vfr_changed(m_last_vfr);
}

void MavlinkTelemetry::requestAllParameters()
{
#ifdef X_USE_MAVSDK
    if(mOHDConnection->paramOhdGround==nullptr){
        return;
    }
    qDebug()<<"MavlinkTelemetry::requestAllParameters()";
    {
        // request all parameters
         const auto result=mOHDConnection->paramOhdGround->get_all_params();
         std::stringstream ss;
         ss<<"Get all:"<<result;
         qDebug()<<ss.str().c_str();
    }
    {
        // request specific
        //const auto customParam=mOHDConnection->paramOhdGround->get_param_int("OHD_UART_BAUD");
        //const auto customParam=mOHDConnection->paramOhdGround->get_param_int("OHD_UART_NAME");
        const auto customParam=mOHDConnection->paramOhdGround->get_param_custom("OHD_UART_NAME");
        std::stringstream ss;
        ss<<"Get specific: "<<customParam.first<<":"<<customParam.second;
        qDebug()<<ss.str().c_str();
    }
#endif //X_USE_MAVSDK
}

