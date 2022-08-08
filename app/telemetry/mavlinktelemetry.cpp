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

#include "mavlink_include.h"

#include "../util/util.h"
#include "../logging/logmessagesmodel.h"
#include <sstream>

#include "openhd_defines.hpp"
#include "qopenhdmavlinkhelper.hpp"

#include "fcmavlinksystem.h"
#include "openhd_systems/aohdsystem.h"

MavlinkTelemetry& MavlinkTelemetry::instance() {
    static MavlinkTelemetry instance;
    return instance;
}

static std::string time_microseconds_readable(int64_t micros){
    if(micros > 1000*1000){
       float seconds=micros/1000.0f/1000.0f;
       std::stringstream ss;
       ss<<seconds<<"s";
       return ss.str();
    }
    const float deltaMs=micros/1000.0f;
    std::stringstream ss;
    ss<<deltaMs<<"ms";
    return ss.str();
}

MavlinkTelemetry::MavlinkTelemetry(QObject *parent){
    qDebug() << "MavlinkTelemetry::MavlinkTelemetry()";
    mOHDConnection=std::make_unique<OHDConnection>(nullptr,false);
    mOHDConnection->registerNewMessageCalback([this](mavlink_message_t msg){
        //qDebug()<<"this->onProcessMavlinkMessage";
        this->onProcessMavlinkMessage(msg);
    });
}



void MavlinkTelemetry::sendData(mavlink_message_t msg)
{
    mOHDConnection->sendMessage(msg);
}


void MavlinkTelemetry::onProcessMavlinkMessage(mavlink_message_t msg) {
    //qDebug()<<"MavlinkTelemetry::onProcessMavlinkMessage"<<msg.msgid;
    //if(pause_telemetry==true){
    //    return;
    //}
    // Ping is special, since there is no component differentation - any component can ping all systems,
    // but never a specific system
    // Obsolete, rpelaced by timesync
    /*if(msg.msgid==MAVLINK_MSG_ID_PING){
        mavlink_ping_t ping;
        mavlink_msg_ping_decode(&msg, &ping);
        //qDebug()<<"Got ping message sender:"<<msg.sysid<<":"<<msg.compid<<" target:"<<ping.target_system<<":"<<ping.target_component<<"seq:"<<ping.seq;
        // We only process ping responses with our specific sys id and a matching sequence number.
        // Note that if the user clicks the ping multiple times in rapid succession, some pings might be dropped.
        // Check if the ping is targeted at our system
        if(ping.seq==pingSequenceNumber && ping.target_system==QOpenHDMavlinkHelper::getSysId()){
            const auto delta=QOpenHDMavlinkHelper::getTimeMicroseconds()-ping.time_usec;
            const auto delta_readable=time_microseconds_readable(delta);
            if(msg.sysid==OHD_SYS_ID_AIR){
                AOHDSystem::instanceAir().set_last_ping_result_openhd(delta_readable.c_str());
            }else if(msg.sysid==OHD_SYS_ID_GROUND){
                AOHDSystem::instanceGround().set_last_ping_result_openhd(delta_readable.c_str());
            }else{
                qDebug()<<"Got ping from fc";
                // almost 100% from flight controller
                //if(msg.compid==MAV_COMP_ID_AUTOPILOT1)
               FCMavlinkSystem::instance().set_last_ping_result_flight_ctrl(delta_readable.c_str());
            }
        }else{
            //qDebug()<<"Got ping message sender:"<<msg.sysid<<":"<<msg.compid<<" target:"<<ping.target_system<<":"<<ping.target_component<<"seq:"<<ping.seq;
        }
        return;
    }*/
    if(msg.msgid==MAVLINK_MSG_ID_TIMESYNC){
        mavlink_timesync_t timesync;
        mavlink_msg_timesync_decode(&msg,&timesync);
        if(timesync.tc1==0){
            // someone (most likely the FC) wants to timesync with us, but we ignore it to save uplink bandwidth.
            return;
        }
        if(timesync.ts1==lastTimeSyncOut){
            qDebug()<<"Got timesync response with we:"<<lastTimeSyncOut<<" msg tc1:"<<timesync.tc1<<" ts1:"<<timesync.ts1;
            const auto delta=QOpenHDMavlinkHelper::getTimeMicroseconds()-timesync.ts1;
            const auto delta_readable=time_microseconds_readable(delta);
            if(msg.sysid==OHD_SYS_ID_AIR){
                AOHDSystem::instanceAir().set_last_ping_result_openhd(delta_readable.c_str());
            }else if(msg.sysid==OHD_SYS_ID_GROUND){
                AOHDSystem::instanceGround().set_last_ping_result_openhd(delta_readable.c_str());
            }else{
                qDebug()<<"Got ping from fc";
                // almost 100% from flight controller
                //if(msg.compid==MAV_COMP_ID_AUTOPILOT1)
               FCMavlinkSystem::instance().set_last_ping_result_flight_ctrl(delta_readable.c_str());
            }
        }else{
            qDebug()<<"Got timesync but it doesn't match: we:"<<lastTimeSyncOut<<" msg tc1:"<<timesync.tc1<<" ts1:"<<timesync.ts1;
        }
        return;
    }
    // Other than ping, we seperate by sys ID's - there are up to 3 Systems - The OpenHD air unit, the OpenHD ground unit and the FC connected to the OHD air unit.
    // The systems then (optionally) can seperate by components, but r.n this is not needed.
    if(msg.sysid==OHD_SYS_ID_AIR){
        // msg was produced by the OHD air unit
        if(AOHDSystem::instanceAir().process_message(msg)){
            // OHD specific message comsumed
            return;
        }
    } else if(msg.sysid==OHD_SYS_ID_GROUND){
        // msg was produced by the OHD ground unit
        if(AOHDSystem::instanceGround().process_message(msg)){
            // OHD specific message consumed
            return;
        }
    }else {
        // msg was neither produced by the OHD air nor ground unit, so almost 100% from the FC
        const auto fc_sys_id=FCMavlinkSystem::instance().get_fc_sys_id();
        if(fc_sys_id.has_value()){
            if(msg.sysid==fc_sys_id.value()){
                bool processed=FCMavlinkSystem::instance().process_message(msg);
            }else{
                qDebug()<<"MavlinkTelemetry received unmatched message "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);

            }
        }else{
             // we don't know the FC sys id yet.
            qDebug()<<"MavlinkTelemetry received unmatched message (FC not yet know) "<<QOpenHDMavlinkHelper::debug_mavlink_message(msg);
        }
    }
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
            const auto time_millis=QOpenHDMavlinkHelper::getTimeMilliseconds();
            FCMavlinkSystem::instance().set_last_heartbeat(time_millis);

            auto custom_mode = heartbeat.custom_mode;

            auto autopilot = (MAV_AUTOPILOT)heartbeat.autopilot;

            //upon first heartbeat find out if autopilot is ardupilot or "other"
            /*if (!sent_autopilot_request){
                requestAutopilotInfo();
                sent_autopilot_request=true;
            }*/

            switch (autopilot) {
                case MAV_AUTOPILOT_PX4: {
                    if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                        auto px4_mode = m_util.px4_mode_from_custom_mode(custom_mode);
                       FCMavlinkSystem::instance().set_flight_mode(px4_mode);
                    }
                     FCMavlinkSystem::instance().set_mav_type("PX4?");
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
                               FCMavlinkSystem::instance().set_flight_mode(plane_mode);
                               FCMavlinkSystem::instance().set_mav_type("ARDUPLANE");
                                /* autopilot detecton not reliable
                                if(ap_version>999){
                                   FCMavlinkSystem::instance().set_mav_type("ARDUPLANE");
                                    //qDebug() << "Mavlink Mav Type= ARDUPLANE";
                                }
                                else{
                                   FCMavlinkSystem::instance().set_mav_type("UKNOWN PLANE");
                                }
                                */
                                break;
                            }
                            case MAV_TYPE_GROUND_ROVER: {
                                auto rover_mode = m_util.rover_mode_from_enum((ROVER_MODE)custom_mode);
                               FCMavlinkSystem::instance().set_flight_mode(rover_mode);
                                break;
                            }
                            case MAV_TYPE_QUADROTOR: {
                                auto copter_mode = m_util.copter_mode_from_enum((COPTER_MODE)custom_mode);
                               FCMavlinkSystem::instance().set_flight_mode(copter_mode);
                               FCMavlinkSystem::instance().set_mav_type("ARDUCOPTER");
                                /* autopilot detection not reliable
                                if(ap_version>999){
                                   FCMavlinkSystem::instance().set_mav_type("ARDUCOPTER");
                                    //qDebug() << "Mavlink Mav Type= ARDUCOPTER";
                                }
                                else {
                                   FCMavlinkSystem::instance().set_mav_type("UNKNOWN COPTER");
                                }
                                */
                                break;
                            }
                            case MAV_TYPE_SUBMARINE: {
                                auto sub_mode = m_util.sub_mode_from_enum((SUB_MODE)custom_mode);
                               FCMavlinkSystem::instance().set_flight_mode(sub_mode);
                                break;
                            }
                            case MAV_TYPE_ANTENNA_TRACKER: {
                                auto tracker_mode = m_util.tracker_mode_from_enum((TRACKER_MODE)custom_mode);
                                //FCMavlinkSystem::instance()->set_tracker_mode(tracker_mode);
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
               FCMavlinkSystem::instance().set_armed(true);
            } else {
               FCMavlinkSystem::instance().set_armed(false);
            }

            qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            //last_heartbeat_timestamp = current_timestamp;
            break;
        }

        case MAVLINK_MSG_ID_AUTOPILOT_VERSION: {
            mavlink_autopilot_version_t autopilot_version;
            mavlink_msg_autopilot_version_decode(&msg, &autopilot_version);

            //ap_version = autopilot_version.flight_sw_version;
            auto ap_board_version = autopilot_version.board_version;
            auto ap_os_version = autopilot_version.os_sw_version;
            auto ap_product_id = autopilot_version.product_id;
            auto ap_uid = autopilot_version.uid;

            //qDebug() << "MAVLINK AUTOPILOT VERSION=" <<  ap_version;
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
           FCMavlinkSystem::instance().set_battery_voltage(battery_voltage);

           FCMavlinkSystem::instance().set_battery_current(sys_status.current_battery);

           FCMavlinkSystem::instance().updateAppMah();

           FCMavlinkSystem::instance().updateAppMahKm();

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = m_util.lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            //FCMavlinkSystem::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_percent);
            //FCMavlinkSystem::instance()->set_battery_gauge(battery_gauge_glyph);

            //qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
            //last_battery_timestamp = current_timestamp;
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            mavlink_system_time_t sys_time;
            mavlink_msg_system_time_decode(&msg, &sys_time);
            uint32_t boot_time = sys_time.time_boot_ms;

            /*if (boot_time < m_last_boot || m_last_boot == 0) {
                m_last_boot = boot_time;
                qDebug() << "setDataStreamRate and requestAutopilotInfo called";
                setDataStreamRate(MAV_DATA_STREAM_EXTENDED_STATUS, 2);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA1, 10);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA2, 5);
                setDataStreamRate(MAV_DATA_STREAM_EXTRA3, 3);
                setDataStreamRate(MAV_DATA_STREAM_POSITION, 3);
                setDataStreamRate(MAV_DATA_STREAM_RAW_SENSORS, 2);
                setDataStreamRate(MAV_DATA_STREAM_RC_CHANNELS, 2);
            }*/

            break;
        }
        case MAVLINK_MSG_ID_PARAM_VALUE:{
            // handled by params mavsdk
            break;
        }
        case MAVLINK_MSG_ID_GPS_RAW_INT:{
            mavlink_gps_raw_int_t gps_status;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
           FCMavlinkSystem::instance().set_satellites_visible(gps_status.satellites_visible);
           FCMavlinkSystem::instance().set_gps_hdop(gps_status.eph / 100.0);
           FCMavlinkSystem::instance().set_gps_fix_type((unsigned int)gps_status.fix_type);
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
           FCMavlinkSystem::instance().set_imu_temp((int)raw_imu.temperature/100);
            break;
        }
        case MAVLINK_MSG_ID_SCALED_PRESSURE:{
            mavlink_scaled_pressure_t scaled_pressure;
            mavlink_msg_scaled_pressure_decode(&msg, &scaled_pressure);

           FCMavlinkSystem::instance().set_press_temp((int)scaled_pressure.temperature/100);
            //qDebug() << "Temp:" <<  scaled_pressure.temperature;
            break;
        }
        case MAVLINK_MSG_ID_ATTITUDE:{
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode (&msg, &attitude);
            // handled by mavsdk
            //FCMavlinkSystem::instance().set_pitch((double)attitude.pitch *57.2958);
            //qDebug() << "Pitch:" <<  attitude.pitch*57.2958;
            //FCMavlinkSystem::instance().set_roll((double)attitude.roll *57.2958);
            //qDebug() << "Roll:" <<  attitude.roll*57.2958;
            //qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
            //last_attitude_timestamp = current_timestamp;
            break;
        }
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
            break;
        }
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

           FCMavlinkSystem::instance().set_lat((double)global_position.lat / 10000000.0);
           FCMavlinkSystem::instance().set_lon((double)global_position.lon / 10000000.0);

           FCMavlinkSystem::instance().set_boot_time(global_position.time_boot_ms);

           FCMavlinkSystem::instance().set_alt_rel(global_position.relative_alt/1000.0);
            // qDebug() << "Altitude relative " << alt_rel;
           FCMavlinkSystem::instance().set_alt_msl(global_position.alt/1000.0);

            // FOR INAV heading does not /100
            //MAVSDK
            /*QSettings settings;
            auto _heading_inav = settings.value("heading_inav", false).toBool();
            if(_heading_inav==true){
               FCMavlinkSystem::instance().set_hdg(global_position.hdg);
            }
            else{
               FCMavlinkSystem::instance().set_hdg(global_position.hdg / 100);
            }*/
           FCMavlinkSystem::instance().set_vx(global_position.vx/100.0);
           FCMavlinkSystem::instance().set_vy(global_position.vy/100.0);
           FCMavlinkSystem::instance().set_vz(global_position.vz/100.0);

           FCMavlinkSystem::instance().findGcsPosition();
           FCMavlinkSystem::instance().calculate_home_distance();
           FCMavlinkSystem::instance().calculate_home_course();

           FCMavlinkSystem::instance().updateFlightDistance();

           FCMavlinkSystem::instance().updateVehicleAngles();

           FCMavlinkSystem::instance().updateWind();

            //qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            //last_gps_timestamp = current_timestamp;

            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
            mavlink_rc_channels_raw_t rc_channels_raw;
            mavlink_msg_rc_channels_raw_decode(&msg, &rc_channels_raw);

            auto rssi = static_cast<int>(static_cast<double>(rc_channels_raw.rssi) / 255.0 * 100.0);
           FCMavlinkSystem::instance().setRcRssi(rssi);

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
            /*FCMavlinkSystem::instance()->set_control_pitch(rc_channels.chan2_raw);
           FCMavlinkSystem::instance().set_control_roll(rc_channels.chan1_raw);
           FCMavlinkSystem::instance().set_control_throttle(rc_channels.chan3_raw);
           FCMavlinkSystem::instance().set_control_yaw(rc_channels.chan4_raw);*/

            auto rssi = static_cast<int>(static_cast<double>(rc_channels.rssi) / 255.0 * 100.0);
           FCMavlinkSystem::instance().setRcRssi(rssi);

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

           FCMavlinkSystem::instance().set_throttle(vfr_hud.throttle);

            auto airspeed = vfr_hud.airspeed*3.6;
           FCMavlinkSystem::instance().set_airspeed(airspeed);

            auto speed = vfr_hud.groundspeed*3.6;
           FCMavlinkSystem::instance().set_speed(speed);
            // qDebug() << "Speed- ground " << speed;

            auto vsi = vfr_hud.climb;
           FCMavlinkSystem::instance().set_vsi(vsi);
            // qDebug() << "VSI- " << vsi;

            //qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

            //last_vfr_timestamp = current_timestamp;

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

           FCMavlinkSystem::instance().set_mav_wind_direction(mav_wind.direction);
           FCMavlinkSystem::instance().set_mav_wind_speed(mav_wind.speed);


            /*qDebug() << "Windmavdir: " << mav_wind.direction;
            qDebug() << "Windmavspd: " << mav_wind.speed;*/


            break;
        }
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery_status;
            mavlink_msg_battery_status_decode(&msg, &battery_status);

           FCMavlinkSystem::instance().set_flight_mah(battery_status.current_consumed);

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

           FCMavlinkSystem::instance().set_fc_battery_percent(battery_status.battery_remaining);
            QString fc_battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_status.battery_remaining);
           FCMavlinkSystem::instance().set_fc_battery_gauge(fc_battery_gauge_glyph);
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

           FCMavlinkSystem::instance().set_vibration_x(vibration.vibration_x);
           FCMavlinkSystem::instance().set_vibration_y(vibration.vibration_y);
           FCMavlinkSystem::instance().set_vibration_z(vibration.vibration_z);

           FCMavlinkSystem::instance().set_clipping_x(vibration.clipping_0);
           FCMavlinkSystem::instance().set_clipping_y(vibration.clipping_1);
           FCMavlinkSystem::instance().set_clipping_z(vibration.clipping_2);
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
           FCMavlinkSystem::instance().set_homelat((double)home_position.latitude / 10000000.0);
           FCMavlinkSystem::instance().set_homelon((double)home_position.longitude / 10000000.0);
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
                const auto tag= (msg.sysid==OHD_SYS_ID_AIR) ? "OHDAir":"OHDGround";
                LogMessagesModel::instance().addLogMessage(tag,s,statustext.severity);

            }else{
                // most likely from the flight controller, but can be someone else, too
                 //qDebug()<<"Log message from not OpenHD:"<<s;
                FCMavlinkSystem::instance().telemetryStatusMessage(s, statustext.severity);
            }
            break;
        }
        case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4: {
            mavlink_esc_telemetry_1_to_4_t esc_telemetry;
            mavlink_msg_esc_telemetry_1_to_4_decode(&msg, &esc_telemetry);

           FCMavlinkSystem::instance().set_esc_temp((int)esc_telemetry.temperature[0]);
            break;
        }
        case MAVLINK_MSG_ID_ADSB_VEHICLE: {
            break;
        }
    case MAVLINK_MSG_ID_EXTENDED_SYS_STATE:{
        break;
    }
    // Commands and Params are done by mavsdk
    case MAVLINK_MSG_ID_PARAM_EXT_ACK:
    case MAVLINK_MSG_ID_PARAM_EXT_VALUE:
    case MAVLINK_MSG_ID_COMMAND_ACK:
    //TODO who sends out pings to us ?
    case MAVLINK_MSG_ID_PING:
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
    // Obsolete, rpelaced by timesync
    /*pingSequenceNumber++;
    mavlink_message_t msg;
    mavlink_msg_ping_pack(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(),&msg,QOpenHDMavlinkHelper::getTimeMicroseconds(),pingSequenceNumber,0,0);
    sendData(msg);*/
    // Ardupilot (and PX4?) don't support ping, but timesync
    // Here I just use a single timesync message to emulate a ping - they are almost the same
    {
        mavlink_message_t msg2;
        mavlink_timesync_t timesync{};
        timesync.tc1=0;
        // NOTE: MAVSDK does time in nanoseconds by default
        lastTimeSyncOut=QOpenHDMavlinkHelper::getTimeMicroseconds();
        timesync.ts1=lastTimeSyncOut;
        mavlink_msg_timesync_encode(QOpenHDMavlinkHelper::getSysId(),QOpenHDMavlinkHelper::getCompId(),&msg2,&timesync);
        sendData(msg2);
    }
}

