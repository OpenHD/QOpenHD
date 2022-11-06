#include "fcmavlinksystem.h"

#include "../qopenhdmavlinkhelper.hpp"

#include <QDebug>
#include "qopenhd.h"
#include "../telemetryutil.hpp"

#include <geographiclib-c-2.0/src/geodesic.h>

#include <QDateTime>

FCMavlinkSystem& FCMavlinkSystem::instance() {
    static FCMavlinkSystem* instance = new FCMavlinkSystem();
    return *instance;
}

void FCMavlinkSystem::register_for_qml(QQmlContext *qml_context)
{
    qml_context->setContextProperty("_fcMavlinkSystem", &FCMavlinkSystem::instance());
}

void FCMavlinkSystem::set_system(std::shared_ptr<mavsdk::System> system)
{
    // The system is set once when discovered, then should not change !!
    assert(_system==nullptr);
    _system=system;
    if(!_system->has_autopilot()){
        qDebug()<<"FCMavlinkSystem::set_system WARNING no autopilot";
    }
    qDebug()<<"FCMavlinkSystem::set_system: FC SYS ID is:"<<(int)_system->get_system_id();
    _action=std::make_shared<mavsdk::Action>(system);
    _mavsdk_telemetry=std::make_shared<mavsdk::Telemetry>(system);
    auto cb_attituede=[this](mavsdk::Telemetry::EulerAngle angle){
        //qDebug()<<"Got att euler";
        FCMavlinkSystem::instance().set_pitch((double)angle.pitch_deg);
         //qDebug() << "Pitch:" <<  attitude.pitch*57.2958;
        FCMavlinkSystem::instance().set_roll((double)angle.roll_deg);
    };
    _mavsdk_telemetry->subscribe_attitude_euler(cb_attituede);
    auto cb_heading=[this](mavsdk::Telemetry::Heading heading){
        FCMavlinkSystem::instance().set_hdg(heading.heading_deg);
    };
    _mavsdk_telemetry->subscribe_heading(cb_heading);
    auto cb_armed=[this](bool armed){
        set_armed(armed);
    };
    _mavsdk_telemetry->subscribe_armed(cb_armed);
    //_mavsdk_telemetry->subscribe_status_text()
    /*auto cb_flight_mode=[this](mavsdk::Telemetry::FlightMode flight_mode){
        flight_mode
    };
    _mavsdk_telemetry->subscribe_flight_mode(cb_flight_mode);*/
    //_mavsdk_telemetry->subscribe_position()
    //_mavsdk_telemetry->subscribe_home()
    //
    /*telemetryFC=std::make_unique<mavsdk::Telemetry>(system);
    auto res=telemetryFC->set_rate_attitude(60);
    std::stringstream ss;
    ss<<res;
    qDebug()<<"Set rate result:"<<ss.str().c_str();*/
}

bool FCMavlinkSystem::process_message(const mavlink_message_t &msg)
{
    //qDebug()<<"FCMavlinkSystem::process_message";
    if(!_system){
        qDebug()<<"WARNING the system must be set before this model starts processing data";
        return false;
    }
    const auto fc_sys_id=get_fc_sys_id().value();
    if(fc_sys_id != msg.sysid){
        qDebug()<<"Do not pass messages not coming from the FC to the FC model";
        return false;
    }
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
            const auto time_millis=QOpenHDMavlinkHelper::getTimeMilliseconds();
            FCMavlinkSystem::instance().set_last_heartbeat(time_millis);
            const auto custom_mode = heartbeat.custom_mode;
            const auto autopilot = (MAV_AUTOPILOT)heartbeat.autopilot;
            //upon first heartbeat find out if autopilot is ardupilot or "other"
            /*if (!sent_autopilot_request){
                requestAutopilotInfo();
                sent_autopilot_request=true;
            }*/
            switch (autopilot) {
                case MAV_AUTOPILOT_PX4: {
                    if (heartbeat.base_mode & MAV_MODE_FLAG_CUSTOM_MODE_ENABLED) {
                        auto px4_mode = Telemetryutil::px4_mode_from_custom_mode(custom_mode);
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
                                auto plane_mode = Telemetryutil::plane_mode_from_enum((PLANE_MODE)custom_mode);
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
                                auto rover_mode = Telemetryutil::rover_mode_from_enum((ROVER_MODE)custom_mode);
                               FCMavlinkSystem::instance().set_flight_mode(rover_mode);
                                break;
                            }
                            case MAV_TYPE_QUADROTOR: {
                                auto copter_mode = Telemetryutil::copter_mode_from_enum((COPTER_MODE)custom_mode);
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
                                auto sub_mode = Telemetryutil::sub_mode_from_enum((SUB_MODE)custom_mode);
                               FCMavlinkSystem::instance().set_flight_mode(sub_mode);
                                break;
                            }
                            case MAV_TYPE_ANTENNA_TRACKER: {
                                auto tracker_mode = Telemetryutil::tracker_mode_from_enum((TRACKER_MODE)custom_mode);
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
                    qDebug()<<"Weird heartbeat";
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
            int battery_percent = Telemetryutil::lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            //FCMavlinkSystem::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = Telemetryutil::battery_gauge_glyph_from_percentage(battery_percent);
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

            //FCMavlinkSystem::instance().findGcsPosition();
            FCMavlinkSystem::instance().calculate_home_distance();
            FCMavlinkSystem::instance().calculate_home_course();

            FCMavlinkSystem::instance().updateFlightDistance();

            FCMavlinkSystem::instance().updateVehicleAngles();

            FCMavlinkSystem::instance().updateWind();
            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
            qDebug()<<"Got message RC channels raw";
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
            FCMavlinkSystem::instance().set_battery_percent(battery_status.battery_remaining);
            QString fc_battery_gauge_glyph = Telemetryutil::battery_gauge_glyph_from_percentage(battery_status.battery_remaining);
            FCMavlinkSystem::instance().set_battery_percent_gauge(fc_battery_gauge_glyph);
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
            // handled by mavsdk
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

    return true;
}

std::optional<uint8_t> FCMavlinkSystem::get_fc_sys_id()
{
    if(_system){
        return _system->get_system_id();
    }
    return std::nullopt;
}

FCMavlinkSystem::FCMavlinkSystem(QObject *parent): QObject(parent) {

    timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, this, &FCMavlinkSystem::updateFlightTimer);
    timer->start(1000);

    m_alive_timer = new QTimer(this);
    QObject::connect(m_alive_timer, &QTimer::timeout, this, &FCMavlinkSystem::update_alive);
    m_alive_timer->start(1000);
}


void FCMavlinkSystem::telemetryStatusMessage(QString message, int level) {
    //emit messageReceived(message, level);
    //QOpenHD::instance().textToSpeech_sayMessage(message);
}

void FCMavlinkSystem::updateFlightTimer() {
    if (m_armed == true) {
        // check elapsed time since arming and update the UI-visible flight_time property
        int elapsed = flightTimeStart.elapsed() / 1000;
        auto hours = elapsed / 3600;
        auto minutes = (elapsed % 3600) / 60;
        auto seconds = elapsed % 60;
        QString s;
        if (hours > 0) {
            s = QTime(0,0,0,0).addSecs(elapsed).toString("hh:mm:ss");
        } else {
            s = QTime(0,0,0,0).addSecs(elapsed).toString("mm:ss");
        }
        set_flight_time(s);
    }
}
/*
void FCMavlinkSystem::findGcsPosition() {
    if (gcs_position_set==false){
        //only attempt to set gcs home position if hdop<3m and unarmed
        if (m_gps_hdop<3 && m_armed==false){
            //get 20 good gps readings before setting
            if (++gps_quality_count == 20) {
                set_homelat(m_lat);
                set_homelon(m_lon);                
                gcs_position_set=true;
                //LocalMessage::instance()->showMessage("Home Position set by FCMavlinkSystem", 7);
            }
        }
        else if (m_armed==false){ //we are in flight and the app crashed
            QSettings settings;
            set_homelat(settings.value("home_saved_lat", QVariant(0)).toDouble());
            set_homelon(settings.value("home_saved_lon", QVariant(0)).toDouble());
        }
    }
}
*/
void FCMavlinkSystem::updateFlightDistance() {
    if (m_gps_hdop > 20 || m_lat == 0.0){
        //do not pollute distance if we have bad data
        return;
    }
    if (m_armed==true){
        auto elapsed = flightTimeStart.elapsed();
        auto time = elapsed / 3600;
        auto time_diff = time - flightDistanceLastTime;
        flightDistanceLastTime = time;

        auto added_distance =  m_speed * time_diff;
        //qDebug() << "added distance" << added_distance;
        total_dist = total_dist + added_distance;

        //qDebug() << "total distance" << total_dist;
        set_flight_distance( total_dist);
    }
}

void FCMavlinkSystem::updateAppMah() {
    if (!totalTime.isValid()){
        totalTime.start();
    }
    auto elapsed = totalTime.elapsed();
    auto time = elapsed / 3600;
    auto time_diff = time - mahLastTime;
    mahLastTime = time;

    //m_battery_current is 1 decimals to the right
    auto added_mah=(m_battery_current/100) * time_diff;
    total_mah = total_mah + added_mah;

    set_app_mah( total_mah );
}

void FCMavlinkSystem::updateAppMahKm() {
    if (!totalTime.isValid()){
        totalTime.start();
    }
    static Telemetryutil::pt1Filter_t eFilterState;
    auto currentTimeMs = totalTime.elapsed();
    auto efficiencyTimeDelta = currentTimeMs - mahKmLastTime;

    if ( (m_gps_fix_type >= GPS_FIX_TYPE_2D_FIX) && (m_speed > 0) ) {
        set_mah_km((int)Telemetryutil::pt1FilterApply4(
                    &eFilterState, ((float)m_battery_current*10 / m_speed), 1, efficiencyTimeDelta * 1e-3f));
        mahKmLastTime = currentTimeMs;
    }

}

void FCMavlinkSystem::set_boot_time(int boot_time) {
    m_boot_time = boot_time;
    emit boot_time_changed(m_boot_time);
}

void FCMavlinkSystem::set_alt_rel(double alt_rel) {
    m_alt_rel = alt_rel;
    emit alt_rel_changed(m_alt_rel);
}

void FCMavlinkSystem::set_alt_msl(double alt_msl) {
    m_alt_msl = alt_msl;
    emit alt_msl_changed(m_alt_msl);
}

void FCMavlinkSystem::set_vx(double vx) {
    m_vx = vx;
    emit vx_changed(m_vx);
}

void FCMavlinkSystem::set_vy(double vy) {
    m_vy = vy;
    emit vy_changed(m_vy);
}

void FCMavlinkSystem::set_vz(double vz) {
    m_vz = vz;
    emit vz_changed(m_vz);
}

void FCMavlinkSystem::set_hdg(int hdg) {
    m_hdg = hdg;
    emit hdg_changed(m_hdg);
}

void FCMavlinkSystem::set_speed(double speed) {
    m_speed = speed;
    emit speed_changed(m_speed);
}

void FCMavlinkSystem::set_airspeed(double airspeed) {
    m_airspeed = airspeed;
    emit airspeed_changed(m_airspeed);
}

void FCMavlinkSystem::set_armed(bool armed) {
    if(m_armed==armed)return;
    QString message=(armed && !m_armed) ? "armed" : "disarmed";
    QOpenHD::instance().textToSpeech_sayMessage(message);
    if (armed && !m_armed) {
        /*
         * Restart the flight timer when the vehicle transitions to the armed state.
         *
         * In the updateFlightTimer() callback we skip updating the property if the
         * vehicle is disarmed, causing it to appear to stop in the UI.
         */
        flightTimeStart.start();
        if (m_homelat == 0.0 && m_homelon == 0.0) {
            //LocalMessage::instance()->showMessage("No Home Position in FCMavlinkSystem", 4);
        }
    }
    m_armed = armed;
    emit armed_changed(m_armed);
}

void FCMavlinkSystem::set_flight_mode(QString flight_mode) {
    if(flight_mode==m_flight_mode)return;
    QString message=tr("%1 flight mode").arg(flight_mode);
    QOpenHD::instance().textToSpeech_sayMessage(message);
    m_flight_mode = flight_mode;
    emit flight_mode_changed(m_flight_mode);
}

void FCMavlinkSystem::set_mav_type(QString mav_type) {
    if(m_mav_type==mav_type)return;
    m_mav_type = mav_type;
    emit mav_type_changed(m_mav_type);
}

void FCMavlinkSystem::set_homelat(double homelat) {
    m_homelat = homelat;
    gcs_position_set = true;
    emit homelat_changed(m_homelat);
    QSettings settings;
    settings.value("home_saved_lat", QVariant(0)) = m_homelat;

}

void FCMavlinkSystem::set_homelon(double homelon) {
    m_homelon = homelon;
    gcs_position_set = true;
    emit homelon_changed(m_homelon);
    QSettings settings;
    settings.value("home_saved_lon", QVariant(0)) = m_homelon;
}

void FCMavlinkSystem::calculate_home_distance() {
    // if home lat/long are zero the calculation will be wrong so we skip it
    if (m_homelat != 0.0 && m_homelon != 0.0) {
        double s12;
        double azi1;
        double azi2;

        geod_geodesic geod{};
        // from https://manpages.ubuntu.com/manpages/bionic/man3/geodesic.3.html
        const double a = 6378137, f = 1/298.257223563; /* WGS84 */
        geod_init(&geod,a,f);
        geod_inverse(&geod,m_homelat,m_homelon,m_lat,m_lon,&s12,&azi1,&azi2);

        /* todo: this could be easily extended to save the azimuth as well, which gives us the direction
           home for free as a result of the calculation above.
        */
        set_home_distance(s12);
    } else {
        /*
         * If the system doesnt have home pos just show "0"
         */
        set_home_distance(0.0);
    }
}

void FCMavlinkSystem::set_home_distance(double home_distance) {
    m_home_distance = home_distance;
    emit home_distance_changed(home_distance);
}

void FCMavlinkSystem::calculate_home_course() {

    //qDebug() << "Home lat lon " << m_homelat << " :" << m_homelon;

    double  dlon = (m_lon-m_homelon)*0.017453292519;
    double lat1 = (m_homelat)*0.017453292519;
    double lat2 = (m_lat)*0.017453292519;
    double  a1 = sin(dlon) * cos(lat2);
    double  a2 = sin(lat1) * cos(lat2) * cos(dlon);
    a2 = cos(lat1) * sin(lat2) - a2;
    a2 = atan2(a1, a2);
    if (a2 < 0.0) a2 += M_PI*2;

    int result= 180.0f / M_PI*(a2);

    set_home_course(result);
    set_home_heading(result);

}

void FCMavlinkSystem::set_home_course(int home_course) {
    //so arrow points correct way it must be relative to heading
    int rel_heading = home_course - m_hdg;
    if (rel_heading < 0) rel_heading += 360;
    if (rel_heading >= 360) rel_heading -=360;
    m_home_course = rel_heading;
    emit home_course_changed(home_course);
}

void FCMavlinkSystem::set_home_heading(int home_heading) {
    //backwards for some reason
    home_heading=home_heading-180;
    if (home_heading < 0) home_heading += 360;
    if (home_heading >= 360) home_heading -=360;
    m_home_heading = home_heading;
    emit home_heading_changed(home_heading);
}

void FCMavlinkSystem::set_lat(double lat) {
    m_lat = lat;
    emit lat_changed(m_lat);
}

void FCMavlinkSystem::set_lon(double lon) {
    m_lon = lon;
    emit lon_changed(m_lon);
}

void FCMavlinkSystem::set_satellites_visible(int satellites_visible) {
    m_satellites_visible = satellites_visible;
    emit satellites_visible_changed(m_satellites_visible);
}

void FCMavlinkSystem::set_gps_hdop(double gps_hdop) {
    m_gps_hdop = gps_hdop;
    emit gps_hdop_changed(m_gps_hdop);
}

void FCMavlinkSystem::set_gps_fix_type(unsigned int gps_fix_type) {
    m_gps_fix_type = gps_fix_type;
    emit gps_fix_type_changed(m_gps_fix_type);
}

void FCMavlinkSystem::set_clipping_x(float clipping_x) {
    m_clipping_x= clipping_x;
     emit clipping_x_changed(m_clipping_x);
}

void FCMavlinkSystem::set_clipping_y(float clipping_y) {
    m_clipping_y= clipping_y;
     emit clipping_y_changed(m_clipping_y);
}

void FCMavlinkSystem::set_clipping_z(float clipping_z) {
    m_clipping_z= clipping_z;
     emit clipping_z_changed(m_clipping_z);
}

void FCMavlinkSystem::set_vsi(float vsi) {
    m_vsi= vsi;
     emit vsi_changed(m_vsi);
}

void FCMavlinkSystem::set_lateral_speed(double lateral_speed) {
    m_lateral_speed= lateral_speed;
     emit lateral_speed_changed(m_lateral_speed);
}

void FCMavlinkSystem::set_wind_speed(double wind_speed) {
    m_wind_speed= wind_speed;
     emit wind_speed_changed(m_wind_speed);
}

void FCMavlinkSystem::set_wind_direction(double wind_direction) {
    m_wind_direction= wind_direction;
     emit wind_direction_changed(m_wind_direction);
}

void FCMavlinkSystem::set_mav_wind_direction(float mav_wind_direction) {
    m_mav_wind_direction= mav_wind_direction;
     emit mav_wind_direction_changed(m_mav_wind_direction);
}

void FCMavlinkSystem::set_mav_wind_speed(float mav_wind_speed) {
    m_mav_wind_speed= mav_wind_speed;
     emit mav_wind_speed_changed(m_mav_wind_speed);
}

void FCMavlinkSystem::setRcRssi(int rcRssi) {
    m_rcRssi = rcRssi;
    emit rcRssiChanged(m_rcRssi);
}

void FCMavlinkSystem::set_imu_temp(int imu_temp) {
    m_imu_temp = imu_temp;
    emit imu_temp_changed(m_imu_temp);
}

void FCMavlinkSystem::set_press_temp(int press_temp) {
    m_press_temp = press_temp;
    emit press_temp_changed(m_press_temp);
}

void FCMavlinkSystem::set_esc_temp(int esc_temp) {
    m_esc_temp = esc_temp;
    emit esc_temp_changed(m_esc_temp);
}

void FCMavlinkSystem::set_flight_time(QString flight_time) {
    m_flight_time = flight_time;
    emit flight_time_changed(m_flight_time);
}

void FCMavlinkSystem::set_flight_distance(double flight_distance) {
    m_flight_distance = flight_distance;
    emit flight_distance_changed(m_flight_distance);
}

void FCMavlinkSystem::set_flight_mah(double flight_mah) {
    m_flight_mah = flight_mah;
    emit flight_mah_changed(m_flight_mah);
}

void FCMavlinkSystem::set_app_mah(double app_mah) {
    m_app_mah = app_mah;
    emit app_mah_changed(m_app_mah);
}

void FCMavlinkSystem::set_mah_km(int mah_km) {
    m_mah_km = mah_km;
    emit mah_km_changed(m_mah_km);
}

void FCMavlinkSystem::set_vehicle_vx_angle(double vehicle_vx_angle) {
    m_vehicle_vx_angle = vehicle_vx_angle;
    emit vehicle_vx_angle_changed(m_vehicle_vx_angle);
}

void FCMavlinkSystem::set_vehicle_vz_angle(double vehicle_vz_angle) {
    m_vehicle_vz_angle = vehicle_vz_angle;
    emit vehicle_vz_angle_changed(m_vehicle_vz_angle);
}

void FCMavlinkSystem::updateVehicleAngles(){

    auto resultant_magnitude = sqrt(m_vx * m_vx + m_vy * m_vy);

    //direction of motion vector in radians then converted to degree
    auto resultant_lateral_angle = atan2(m_vy , m_vx)*(180/M_PI);

    //converted from degrees to a compass heading
    if (resultant_lateral_angle < 0.0){
        resultant_lateral_angle += 360;
    }

    //Compare the motion heading to the vehicle heading
    auto left = m_hdg - resultant_lateral_angle;
    auto right = resultant_lateral_angle - m_hdg;
    if (left < 0) left += 360;
    if (right < 0) right += 360;
    auto heading_diff = left < right ? -left : right;
    //qDebug() << "LATERAL ANGLE=" << heading_diff;
    set_vehicle_vx_angle(heading_diff);
    double vehicle_vx=0.0;

    if (heading_diff > 0 && heading_diff <= 90){
        //console.log("we are moving forward and or right");
        vehicle_vx=(heading_diff/90)*resultant_magnitude;
    }
    else if (heading_diff > 90 && heading_diff <= 180){
        //console.log("we are moving backwards and or right");
        vehicle_vx=((heading_diff*-1)+180)/90*resultant_magnitude;
    }
    else if (heading_diff > -180 && heading_diff <= -90){
        //console.log("we are moving backwards and or left");
        vehicle_vx=((heading_diff+180)/90)*-1*resultant_magnitude;
    }
    else{
        //console.log("we are moving forward and or left");
        vehicle_vx=(heading_diff/90)*resultant_magnitude;
    }
    set_lateral_speed(vehicle_vx);

    //--------- CALCULATE THE VERTICAL ANGLE OF MOTION

    //direction of motion vector in radians then converted to degree
    auto resultant_vertical_angle = atan2(resultant_magnitude , m_vz)*(180/M_PI)-90;
    //qDebug() << "VERTICAL ANGLE1=" << resultant_vertical_angle;

    set_vehicle_vz_angle(resultant_vertical_angle);

}

void FCMavlinkSystem::updateWind(){

    if (m_vsi < 1 && m_vsi > -1){
        // we are level, so a 2d vector is possible

        QSettings settings;
        auto max_speed = settings.value("wind_max_quad_speed", QVariant(3)).toDouble();

        //qDebug() << "WIND----" << max_speed;
        auto max_tilt=45;

        auto perf_ratio=max_speed/max_tilt;

        //find total tilt by adding our pitch and roll angles
        auto tilt_angle = sqrt(m_pitch * m_pitch + m_roll * m_roll);

        auto expected_course = atan2 (m_pitch , m_roll)*(180/M_PI);

        //the raw output tilt direction is +1 +180 from right cw left
        //the raw output tilt direction is -1 -180 from right ccw left

        //convert this to compass degree
        if (expected_course < 0.0){
            expected_course += 360.0;
        }
        //reorient so 0 is front of vehicle
        expected_course=expected_course - 270;
        if (expected_course < 0.0){
            expected_course += 360.0;
        }

        //change this tilt direction so it is global rather than local
        expected_course=expected_course + m_hdg;
        if (expected_course < 0.0){
            expected_course += 360.0;
        }
        if (expected_course > 360.0){
            expected_course -= 360.0;
        }

        //get actual course
        auto actual_course = atan2 (m_vy , m_vx)*(180/M_PI);
        //converted from degrees to a compass heading
        if (actual_course < 0.0){
            actual_course += 360.0;
        }



        // get expected speed
        auto expected_speed= tilt_angle*perf_ratio;

        //get actual speed
        auto actual_speed = sqrt(m_vx * m_vx + m_vy * m_vy);

        //qDebug() << "WIND actual crs="<< actual_course <<
        //        "expected crs " << expected_course;
        //qDebug() << "WIND actual speed="<< actual_speed;


        if (actual_speed < 1){
            //we are in pos hold
            auto speed_diff= expected_speed - actual_speed;

            //qDebug() << "WIND hold: dir="<<expected_course<< "exp="<<expected_course<<
            //            "act="<<actual_course << "speed="<< speed_diff;

            set_wind_speed(speed_diff);
            set_wind_direction(expected_course);
        }

        if (actual_speed > 1){
            //we are in motion

            auto speed_diff=speed_last_time-actual_speed;
            if (speed_diff<0)speed_diff=speed_diff*-1;

            //make sure we are not accelerating
            if (speed_diff < .5 ){

                auto course_diff_rad= (actual_course* (M_PI/180)) - (expected_course* (M_PI/180));

                auto course_diff= course_diff_rad * 180 / M_PI;
                if (course_diff > 180){
                    course_diff=(360-course_diff)*-1;
                }

                // too much to calculate if we are getting pushed backwards by wind
                if (course_diff < -90 || course_diff > 90){
                    //qDebug() << "WIND out of bounds";
                    return;
                }

                //find speed
                auto wind_speed = sqrt ((actual_speed*actual_speed +
                                         expected_speed*expected_speed) - ((2*(actual_speed*expected_speed))*cos(course_diff_rad)));

                //complete the triangle by getting the angles
                auto wind_angle_a= acos(((wind_speed*wind_speed + actual_speed*actual_speed
                                          - expected_speed*expected_speed)/(2*wind_speed*actual_speed)));

                //convert radians to degrees
                wind_angle_a= wind_angle_a * 180 / M_PI;

                auto pos_course_diff=course_diff;
                if (pos_course_diff < 0){
                    pos_course_diff=pos_course_diff*-1;
                }

                auto wind_angle_b = 180-(wind_angle_a+pos_course_diff);

                auto wind_direction=0.0;

                //get exterior angles to make life easier
                //auto wind_angle_b_ext=0.0;

                //wind_angle_b_ext = 360 - wind_angle_b;

                // this could be shortened to 2 cases but for easier understanding left it at 4
                if (actual_speed <= expected_speed ){ //headwind
                    if (course_diff >= 0){
                        //qDebug() << "WIND left headwind";

                        wind_direction = expected_course + 180 - wind_angle_b;

                    }
                    else {
                        //qDebug() << "WIND right headwind";

                        wind_direction = expected_course + wind_angle_b+180;

                    }
                }
                else if (actual_speed > expected_speed){ // tailwind
                    if (course_diff >= 0){
                        //qDebug() << "WIND left tailwind";

                        wind_direction = expected_course + wind_angle_b;
                    }
                    else{
                        //qDebug() << "WIND right tailwind";

                        wind_direction = expected_course + 180 - wind_angle_b;
                    }
                }
                // correct for current heading and make wind come from rather than to (vector)
                wind_direction=wind_direction-180;

                if (wind_direction < 0) wind_direction += 360;
                if (wind_direction >= 360) wind_direction -= 360;
                /*
                qDebug() << "WIND expected speed="<< expected_speed;

                qDebug() << "WIND angleA= " << wind_angle_a;
                qDebug() << "WIND angleB= " << wind_angle_b;

                qDebug() << "WIND motion: dir="<<wind_direction<<
                            "exp="<<expected_course<<"act="<<actual_course<<"diff="<< course_diff;
                */
                set_wind_speed(wind_speed);
                set_wind_direction(wind_direction);

            }

            speed_last_time=actual_speed;

        }
    }
}


void FCMavlinkSystem::setCurrentWaypoint(int current_waypoint) {
    m_current_waypoint = current_waypoint;
    emit currentWaypointChanged(m_current_waypoint);
}

void FCMavlinkSystem::setTotalWaypoints(int total_waypoints) {
    m_total_waypoints = total_waypoints-1;
    if(m_total_waypoints<0){
        m_total_waypoints=0;
    }
    emit totalWaypointsChanged(m_total_waypoints);
}


void FCMavlinkSystem::set_last_ping_result_flight_ctrl(QString last_ping_result_flight_ctrl)
{
    m_last_ping_result_flight_ctrl=last_ping_result_flight_ctrl;
    emit last_ping_result_flight_ctrl_changed(m_last_ping_result_flight_ctrl);
}

void FCMavlinkSystem::set_supports_basic_commands(bool supports_basic_commands)
{
    if(m_supports_basic_commands==supports_basic_commands)return;
    m_supports_basic_commands=supports_basic_commands;
    emit supports_basic_commands_changed(supports_basic_commands);
};

void FCMavlinkSystem::arm_fc_async(bool disarm)
{
    qDebug()<<"FCMavlinkSystem::arm_fc_async "<<(disarm ? "disarm" : "arm");
    if(_action){
        // We listen for the armed / disarmed changes directly
        auto cb=[this](mavsdk::Action::Result res){
            if(res!=mavsdk::Action::Result::Success){
                std::stringstream ss;
                ss<<"amr/disarm failed:"<<res;
                qDebug()<<ss.str().c_str();
                emit messageReceived(ss.str().c_str(), 0);

            }
        };
        if(disarm){
             _action->disarm_async(cb);
        }else{
             _action->arm_async(cb);
        }
    }else{
        qDebug()<<"No action set";
    }
}

void FCMavlinkSystem::send_return_to_launch_async()
{
    if(_action){
        auto cb=[](mavsdk::Action::Result res){
            std::stringstream ss;
            ss<<"send_return_to_launch: result: "<<res;
            qDebug()<<ss.str().c_str();
        };
        _action->return_to_launch_async(cb);
    }
}

bool FCMavlinkSystem::send_command_reboot(bool reboot)
{
    if(_action){
        mavsdk::Action::Result res{};
        if(reboot){
            res=_action->reboot();
        }else{
            res=_action->shutdown();
        }
        if(res==mavsdk::Action::Result::Success){
            return true;
        }
    }
    return false;
}

void FCMavlinkSystem::set_last_heartbeat(qint64 last_heartbeat)
{
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}

void FCMavlinkSystem::update_alive()
{
    if(m_last_heartbeat==-1){
        // we did not get any heartbeat (yet)
        set_is_alive(false);
    }else{
        // after 3 seconds, consider as "not alive"
        // (aka if we did not get a heartbeat in the last 3 seconds, we consider the FC as not being alive)
        if(QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_heartbeat> 3*1000){
            set_is_alive(false);
        }else{
            set_is_alive(true);
        }
    }
}


