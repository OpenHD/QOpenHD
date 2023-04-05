#include "fcmavlinksystem.h"

#include "../qopenhdmavlinkhelper.hpp"
#include "rcchannelsmodel.h"

#include <QDebug>
#include "util/qopenhd.h"
#include "../telemetryutil.hpp"

#include <geographiclib-c-2.0/src/geodesic.h>

#include <QDateTime>

#include <logging/logmessagesmodel.h>
#include <logging/hudlogmessagesmodel.h>
#include "mavsdk_helper.hpp"
#include "fcmavlinkmissionitemsmodel.h"

FCMavlinkSystem::FCMavlinkSystem(QObject *parent): QObject(parent) {
    m_flight_time_timer = new QTimer(this);
    QObject::connect(m_flight_time_timer, &QTimer::timeout, this, &FCMavlinkSystem::updateFlightTimer);
    m_flight_time_timer->start(1000);
    m_alive_timer = new QTimer(this);
    QObject::connect(m_alive_timer, &QTimer::timeout, this, &FCMavlinkSystem::update_alive);
    m_alive_timer->start(1000);
}

FCMavlinkSystem& FCMavlinkSystem::instance() {
    static FCMavlinkSystem* instance = new FCMavlinkSystem();
    return *instance;
}


void FCMavlinkSystem::set_system(std::shared_ptr<mavsdk::System> system)
{
    // The system is set once when discovered, then should not change !!
    assert(m_system==nullptr);
    m_system=system;
    if(!m_system->has_autopilot()){
        qDebug()<<"FCMavlinkSystem::set_system WARNING no autopilot";
    }
    const int tmp_sys_id=m_system->get_system_id();
    qDebug()<<"FCMavlinkSystem::set_system: FC SYS ID is:"<<(int)tmp_sys_id;
    set_for_osd_sys_id(tmp_sys_id);
    m_action=std::make_shared<mavsdk::Action>(system);
    m_pass_thru=std::make_shared<mavsdk::MavlinkPassthrough>(system);
    // must be manually enabled by the user to save resources
    //m_mission=std::make_shared<mavsdk::Mission>(system);
}

bool FCMavlinkSystem::process_message(const mavlink_message_t &msg)
{
    //qDebug()<<"FCMavlinkSystem::process_message";
    if(!m_system){
        qDebug()<<"WARNING the system must be set before FC model starts processing data";
        return false;
    }
    const auto fc_sys_id=get_fc_sys_id().value();
    if(fc_sys_id != msg.sysid){
        qDebug()<<"Do not pass messages not coming from the FC to the FC model";
        return false;
    }
    if(std::chrono::steady_clock::now()-m_last_update_update_rate_mavlink_message_attitude>std::chrono::seconds(2)){
        const auto delta=std::chrono::steady_clock::now()-m_last_update_update_rate_mavlink_message_attitude;
        const float message_rate_hz=m_n_messages_update_rate_mavlink_message_attitude/
                static_cast<float>(std::chrono::duration_cast<std::chrono::milliseconds>(delta).count()/1000.0);
        //qDebug()<<"Updates:"<<m_n_messages_update_rate_mavlink_message_attitude<<" Rate:"<<message_rate_hz<<" Hz";
        set_curr_update_rate_mavlink_message_attitude(message_rate_hz);
        m_n_messages_update_rate_mavlink_message_attitude=0;
        m_last_update_update_rate_mavlink_message_attitude=std::chrono::steady_clock::now();
    }
    m_last_message_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
    switch (msg.msgid) {
    case MAVLINK_MSG_ID_HEARTBEAT: {
        mavlink_heartbeat_t heartbeat;
        mavlink_msg_heartbeat_decode(&msg, &heartbeat);
        m_last_heartbeat_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
        const auto opt_info=Telemetryutil::parse_heartbeat(heartbeat);
        if(opt_info.has_value()){
            // heartbeat okay
            const auto info=opt_info.value();
            set_flight_mode(info.flight_mode);
            set_mav_type(info.mav_type);
            const bool armed=Telemetryutil::get_arm_mode_from_heartbeat(heartbeat);
            set_armed(armed);
        }else{
            qDebug()<<"Weird heartbeat";
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
        const auto battery_voltage_v = (double)sys_status.voltage_battery / 1000.0;
        set_battery_voltage_volt(battery_voltage_v);
        set_battery_voltage_single_cell(QOpenHDMavlinkHelper::calclate_voltage_per_cell(battery_voltage_v));
        set_battery_current_ampere((double)sys_status.current_battery/100.0);
        // TODO XX
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
        //test_set_data_stream_rates();
        break;
    }
    case MAVLINK_MSG_ID_PARAM_VALUE:{
        // handled by params mavsdk
        break;
    }
    case MAVLINK_MSG_ID_GPS_RAW_INT:{
        // https://mavlink.io/en/messages/common.html#GPS_RAW_INT
        // NOTE: Do not use lat/lon values reported here, use the values actually fused by the FC instead.
        // n satelites and such is okay though
        mavlink_gps_raw_int_t gps_status;
        mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
        set_satellites_visible(gps_status.satellites_visible);
        set_gps_hdop(gps_status.eph / 100.0);
        set_gps_vdop(gps_status.epv / 100.0);
        set_gps_fix_type((unsigned int)gps_status.fix_type);
        set_gps_status_fix_type_str(Telemetryutil::mavlink_gps_fix_type_to_string(gps_status.fix_type));
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
        set_imu_temp_degree((int)raw_imu.temperature/100);
        break;
    }
    case MAVLINK_MSG_ID_SCALED_PRESSURE:{
        mavlink_scaled_pressure_t scaled_pressure;
        mavlink_msg_scaled_pressure_decode(&msg, &scaled_pressure);
        set_preasure_sensor_temperature_degree((int)scaled_pressure.temperature/100);
        //qDebug() << "Temp:" <<  scaled_pressure.temperature;
        break;
    }
    case MAVLINK_MSG_ID_ATTITUDE:{
        mavlink_attitude_t attitude;
        mavlink_msg_attitude_decode (&msg, &attitude);
        // Not handled by mavsdk telemetry callback(s) anymore
        m_n_messages_update_rate_mavlink_message_attitude++;
        const auto roll_deg=Telemetryutil::angle_mavlink_rad_to_degree(attitude.roll);
        const auto pitch_deg=Telemetryutil::angle_mavlink_rad_to_degree(attitude.pitch);
        set_roll((double)roll_deg);
        set_pitch((double)pitch_deg);
        // TODO what about yaw ?! - heading something weird is going on there
        //const auto yaw_deg=Telemetryutil::angle_mavlink_rad_to_degree(attitude.yaw);
        //set_hdg(yaw_deg);
        //qDebug()<<"degree Roll:"<<roll_deg<<" Pitch:"<<pitch_deg<<" Yaw:"<<yaw_deg;
        break;
    }
    case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
        break;
    }
    case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
        mavlink_global_position_int_t global_position_int;
        mavlink_msg_global_position_int_decode(&msg, &global_position_int);
        const double lat=static_cast<double>(global_position_int.lat) / 10000000.0;
        const double lon=static_cast<double>(global_position_int.lon) / 10000000.0;
        set_lat(lat);
        set_lon(lon);
        set_boot_time(global_position_int.time_boot_ms);
        set_alt_rel(global_position_int.relative_alt/1000.0);
        // qDebug() << "Altitude relative " << alt_rel;
        set_alt_msl(global_position_int.alt/1000.0);
        set_vx(global_position_int.vx/100.0);
        set_vy(global_position_int.vy/100.0);
        set_vz(global_position_int.vz/100.0);
        {
           // Still something funky here
           auto heading_deg = (global_position_int.hdg != std::numeric_limits<uint16_t>::max()) ?
                                              static_cast<double>(global_position_int.hdg) * 1e-2 :
                                              static_cast<double>(0);
           set_hdg(heading_deg);
        }
        // Really dirty, we want inav to fix that and get rid of it !
        {
           QSettings settings;
           const bool dirty_enable_inav_hacks=settings.value("dirty_enable_inav_hacks",false).toBool();
           if(dirty_enable_inav_hacks){
               if(m_armed && m_home_latitude==0.0 && m_home_longitude==0.0){
                   set_home_latitude(lat);
                   set_home_longitude(lon);
                   HUDLogMessagesModel::instance().add_message_warning("INAV HOME SET");
               }
           }
        }
        calculate_home_distance();
        calculate_home_course();
        updateFlightDistance();
        updateVehicleAngles();
        updateWind();
        break;
    }
    case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
        // Seems to be outdated
        //qDebug()<<"Got message RC channels raw";
        mavlink_rc_channels_raw_t rc_channels_raw;
        mavlink_msg_rc_channels_raw_decode(&msg, &rc_channels_raw);
        //const auto tmp=Telemetryutil::mavlink_msg_rc_channels_raw_to_array(rc_channels_raw);
        //RCChannelsModel::instanceFC().update_all_channels(tmp);
        set_rc_rssi_percentage( Telemetryutil::mavlink_rc_rssi_to_percent(rc_channels_raw.rssi));
        break;
    }
    case MAVLINK_MSG_ID_RC_CHANNELS:{
        // Seems to be used by ARDUPILOT
        mavlink_rc_channels_t rc_channels;
        mavlink_msg_rc_channels_decode(&msg, &rc_channels);
        const auto tmp=Telemetryutil::mavlink_msg_rc_channels_to_array(rc_channels);
        RCChannelsModel::instanceFC().update_all_channels(tmp);
        set_rc_rssi_percentage( Telemetryutil::mavlink_rc_rssi_to_percent(rc_channels.rssi));
        break;
    }
    case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:{
        break;
    }
    case MAVLINK_MSG_ID_MISSION_CURRENT:{
        //qDebug()<<"Got MAVLINK_MSG_ID_MISSION_CURRENT";
        // https://mavlink.io/en/messages/common.html#MISSION_CURRENT
        mavlink_mission_current_t mission_current;
        mavlink_msg_mission_current_decode(&msg,&mission_current);
        set_mission_waypoints_current(mission_current.seq);
        break;
    }
    case MAVLINK_MSG_ID_MISSION_COUNT:{
        //qDebug()<<"Got MAVLINK_MSG_ID_MISSION_COUNT";
        // https://mavlink.io/en/messages/common.html#MISSION_COUNT
        mavlink_mission_count_t mission;
        mavlink_msg_mission_count_decode(&msg,&mission);
        set_mission_waypoints_current_total(mission.count);
        set_mission_current_type(Telemetryutil::mavlink_mission_type_to_string(mission.mission_type));
        break;
    }
    case MAVLINK_MSG_ID_MISSION_ITEM_INT:{
        //qDebug()<<"Got MAVLINK_MSG_ID_MISSION_ITEM_INT";
        mavlink_mission_item_int_t item;
        mavlink_msg_mission_item_int_decode(&msg, &item);
        {
           double lat=static_cast<double>(item.x)* 1e-7;
           double lon=static_cast<double>(item.y)* 1e-7;
           const int mission_index=item.seq;
           //qDebug()<<"Lat:"<<lat<<", Lon:"<<lon;
           //FCMavlinkMissionItemsModel::instance().add_element({lat,lon});
           FCMavlinkMissionItemsModel::instance().hack_add_el_if_nonexisting(lat,lon,mission_index);
           //FCMavlinkMissionItemsModel::instance().test_add();
        }
        break;
    }
    case MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN:{
        break;
    }
    case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:{
        break;
    }
    case MAVLINK_MSG_ID_VFR_HUD:{
        mavlink_vfr_hud_t vfr_hud;
        mavlink_msg_vfr_hud_decode (&msg, &vfr_hud);
        set_throttle(vfr_hud.throttle);
        auto airspeed = vfr_hud.airspeed*3.6;
        set_airspeed(airspeed);
        auto speed = vfr_hud.groundspeed*3.6;
        set_speed(speed);
        // qDebug() << "Speed- ground " << speed;
        auto vsi = vfr_hud.climb;
        set_vsi(vsi);
        // qDebug() << "VSI- " << vsi;
        //qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
        //last_vfr_timestamp = current_timestamp;
        break;
    }
    case MAVLINK_MSG_ID_HIGH_LATENCY2:{
        mavlink_high_latency2_t high_latency2;
        mavlink_msg_high_latency2_decode(&msg, &high_latency2);
        auto airspeed_temp = high_latency2.temperature_air;
        set_airspeed_sensor_temperature_degree(airspeed_temp);
        //qDebug() << "Airspeed Sensor Temp- " << airspeed_temp;
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
        set_mav_wind_direction(mav_wind.direction);
        set_mav_wind_speed(mav_wind.speed);
        /*qDebug() << "Windmavdir: " << mav_wind.direction;
            qDebug() << "Windmavspd: " << mav_wind.speed;*/
        break;
    }
    case MAVLINK_MSG_ID_BATTERY_STATUS: {
        mavlink_battery_status_t battery_status;
        mavlink_msg_battery_status_decode(&msg, &battery_status);
        set_battery_consumed_mah(battery_status.current_consumed);
        set_battery_percent(battery_status.battery_remaining);
        const QString fc_battery_gauge_glyph = Telemetryutil::battery_gauge_glyph_from_percentage(battery_status.battery_remaining);
        set_battery_percent_gauge(fc_battery_gauge_glyph);
        // we always use the first cell for the "single volt" value. However, not sure how many people have the HW on their air
        // battery to measure the voltage of a single cell (which is what this would be for)
        // January 22: doesn't work reliably, use the worse but working qopenhd local setting approach
        //set_battery_voltage_single_cell((double)battery_status.voltages[0]/1000.0);
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
        mavlink_aoa_ssa_t aoa;
        mavlink_msg_aoa_ssa_decode(&msg, &aoa);
        set_aoa(aoa.AOA);
        //qDebug() << "AOA- " << aoa.AOA;
        break;
    }
    case MAVLINK_MSG_ID_VIBRATION:{
        mavlink_vibration_t vibration;
        mavlink_msg_vibration_decode (&msg, &vibration);
        set_vibration_x(vibration.vibration_x);
        set_vibration_y(vibration.vibration_y);
        set_vibration_z(vibration.vibration_z);
        set_clipping_x(vibration.clipping_0);
        set_clipping_y(vibration.clipping_1);
        set_clipping_z(vibration.clipping_2);
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
        set_home_latitude((double)home_position.latitude / 10000000.0);
        set_home_longitude((double)home_position.longitude / 10000000.0);
        //LocalMessage::instance()->showMessage("Home Position set by Telemetry", 7);
        break;
    }
    case MAVLINK_MSG_ID_STATUSTEXT:{
        mavlink_statustext_t parsedMsg;
        mavlink_msg_statustext_decode(&msg,&parsedMsg);
        auto tmp=Telemetryutil::statustext_convert(parsedMsg);
        LogMessagesModel::instanceFC().addLogMessage("FC",tmp.message.c_str(),tmp.level);
        if(get_SHOW_FC_MESSAGES_IN_HUD()){
            std::stringstream ss;
            ss<<"["<<tmp.message<<"]";
            HUDLogMessagesModel::instance().add_message(tmp.level,ss.str().c_str());
        }
        return true;
    }break;
    case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4: {
        mavlink_esc_telemetry_1_to_4_t esc_telemetry;
        mavlink_msg_esc_telemetry_1_to_4_decode(&msg, &esc_telemetry);

        set_esc_temp((int)esc_telemetry.temperature[0]);
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
    case MAVLINK_MSG_ID_AIRSPEED_AUTOCAL:
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
    if(m_system){
        return m_system->get_system_id();
    }
    return std::nullopt;
}

void FCMavlinkSystem::telemetryStatusMessage(QString message, int level) {
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

void FCMavlinkSystem::updateFlightDistance() {
    if (m_gps_hdop > 20 || m_lat == 0.0){
        //do not pollute distance if we have bad data
        return;
    }
    if (m_armed==true){
        const auto elapsed = flightTimeStart.elapsed();
        const auto time = elapsed / 3600;
        const auto time_diff = time - flightDistanceLastTime;
        flightDistanceLastTime = time;
        const auto added_distance =  m_speed * time_diff;
        //qDebug() << "added distance" << added_distance;
        total_dist = total_dist + added_distance;
        //qDebug() << "total distance" << total_dist;
        set_flight_distance_m( total_dist);
    }
}


void FCMavlinkSystem::set_armed(bool armed) {
    if(m_armed==armed)return; //there has been no change so exit
    if (armed && !m_armed) {
        /*
         * Restart the flight timer when the vehicle transitions to the armed state.
         *
         * In the updateFlightTimer() callback we skip updating the property if the
         * vehicle is disarmed, causing it to appear to stop in the UI.
         */
        flightTimeStart.start();
        if (m_home_latitude == 0.0 && m_home_longitude == 0.0) {
            //LocalMessage::instance()->showMessage("No Home Position in FCMavlinkSystem", 4);
        }
    }
    m_armed = armed;
    emit armed_changed(m_armed);

    send_message_arm_change(armed);
}

void FCMavlinkSystem::send_message_arm_change(bool armed){
    qDebug() << "FCMavlinkSystem::send_message_arm_change: " << armed;
    if (armed){
        HUDLogMessagesModel::instance().add_message_warning("ARMED!");
        QOpenHD::instance().textToSpeech_sayMessage("Armed");
    }else {
        HUDLogMessagesModel::instance().add_message_info("Disarmed");
        QOpenHD::instance().textToSpeech_sayMessage("Disarmed");
    }
}

void FCMavlinkSystem::set_flight_mode(QString flight_mode) {
    if(flight_mode==m_flight_mode)return;
    QString message=tr("%1 flight mode").arg(flight_mode);
    QOpenHD::instance().textToSpeech_sayMessage(message);
    m_flight_mode = flight_mode;
    emit flight_mode_changed(m_flight_mode);
}

void FCMavlinkSystem::calculate_home_distance() {
    // if home lat/long are zero the calculation will be wrong so we skip it
    if (m_home_latitude != 0.0 && m_home_longitude != 0.0) {
        double s12;
        double azi1;
        double azi2;

        geod_geodesic geod{};
        // from https://manpages.ubuntu.com/manpages/bionic/man3/geodesic.3.html
        const double a = 6378137, f = 1/298.257223563; /* WGS84 */
        geod_init(&geod,a,f);
        geod_inverse(&geod,m_home_latitude,m_home_longitude,m_lat,m_lon,&s12,&azi1,&azi2);

        /* todo: this could be easily extended to save the azimuth as well, which gives us the direction
           home for free as a result of the calculation above.
        */
        set_home_distance(s12);
        //qDebug()<<"XX"<<Telemetryutil::normalize_degree(azi1);
    } else {
        /*
         * If the system doesnt have home pos just show "0"
         */
        set_home_distance(0.0);
    }
}

void FCMavlinkSystem::calculate_home_course() {

    //qDebug() << "Home lat lon " << m_home_latitude << " :" << m_home_longitude;

    const double  dlon = (m_lon-m_home_longitude)*0.017453292519;
    const double lat1 = (m_home_latitude)*0.017453292519;
    const double lat2 = (m_lat)*0.017453292519;
    const double  a1 = sin(dlon) * cos(lat2);
    double  a2 = sin(lat1) * cos(lat2) * cos(dlon);
    a2 = cos(lat1) * sin(lat2) - a2;
    a2 = atan2(a1, a2);
    if (a2 < 0.0) a2 += M_PI*2;

    const int result= 180.0f / M_PI*(a2);

    set_home_course(result);
    set_home_heading(result);

}

void FCMavlinkSystem::set_home_course(int home_course) {
    //so arrow points correct way it must be relative to heading
    int rel_heading = home_course - m_hdg;
    if (rel_heading < 0) rel_heading += 360;
    if (rel_heading >= 360) rel_heading -=360;
    if(m_home_course != rel_heading){
        m_home_course = rel_heading;
        emit home_course_changed(home_course);
    }
}

void FCMavlinkSystem::set_home_heading(int home_heading) {
    //backwards for some reason
    home_heading=home_heading-180;
    if (home_heading < 0) home_heading += 360;
    if (home_heading >= 360) home_heading -=360;
    if(m_home_heading != home_heading){
        m_home_heading = home_heading;
        emit home_heading_changed(home_heading);
    }
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

void FCMavlinkSystem::arm_fc_async(bool arm)
{
    if(!m_action){
        qDebug()<<"No fc action module";
        return;
    }
    qDebug()<<"FCMavlinkSystem::arm_fc_async "<<(arm ? "arm" : "disarm");
    // We listen for the armed / disarmed changes directly
    auto cb=[this](mavsdk::Action::Result res){
        if(res!=mavsdk::Action::Result::Success){
            std::stringstream ss;
            ss<<"ARM/Disarm failed:"<<res;
            qDebug()<<ss.str().c_str();
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }
    };
    if(arm){
        m_action->arm_async(cb);
    }else{
        m_action->disarm_async(cb);
    }
}

void FCMavlinkSystem::send_return_to_launch_async()
{ //TODO ------this probably only works for px4---------
    if(!m_action){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return;
    }
    auto cb=[](mavsdk::Action::Result res){
        std::stringstream ss;
        ss<<"send_return_to_launch: result: "<<res;
        qDebug()<<ss.str().c_str();
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
    };
    m_action->return_to_launch_async(cb);
}

bool FCMavlinkSystem::send_command_reboot(bool reboot)
{
    if(!m_action){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return false;
    }
    mavsdk::Action::Result res{};
    if(reboot){
        res=m_action->reboot();
    }else{
        res=m_action->shutdown();
    }
    if(res==mavsdk::Action::Result::Success){
        return true;
    }
    return false;
}


void FCMavlinkSystem::flight_mode_cmd(long cmd_msg) {
    if(!m_pass_thru){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        qDebug()<<"No fc pass_thru module";
        return;
    }
    /*
    qDebug() << "flight_mode_cmd CMD:" << cmd_msg;
    qDebug() << "flight_mode_cmd our sysid:" << _pass_thru->get_our_sysid();
    qDebug() << "flight_mode_cmd our comp id:" << _pass_thru->get_our_compid();
    qDebug() << "flight_mode_cmd target id:" << _pass_thru->get_target_sysid();
    qDebug() << "flight_mode_cmd target compid:" << _pass_thru->get_target_compid();*/
    mavsdk::MavlinkPassthrough::CommandLong cmd;

    cmd.command = MAV_CMD_DO_SET_MODE;

    cmd.target_sysid= m_pass_thru->get_target_sysid();
    cmd.target_compid=m_pass_thru->get_target_compid();

    cmd.param1=MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    cmd.param2=cmd_msg;
    cmd.param3=0;
    cmd.param4=0;
    cmd.param5=0;
    cmd.param6=0;
    cmd.param7=0;

    const auto res=m_pass_thru->send_command_long(cmd);

    //result is not really used right now as mavsdk will output errors
    //----here for future use----
    if(res==mavsdk::MavlinkPassthrough::Result::Success){
        const auto msg="flight_mode_cmd Success!!";
        qDebug()<<msg;
        HUDLogMessagesModel::instance().add_message_info(msg);
    }
    else {
        const auto msg=mavsdk::helper::to_string2("flight_mode_cmd error:",res);
        qDebug()<<msg.c_str();
        HUDLogMessagesModel::instance().add_message_warning(msg.c_str());
    }
}

void FCMavlinkSystem::request_home_position_from_fc()
{
    if(!m_pass_thru){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        qDebug()<<"No fc pass_thru module";
        return;
    }
    mavsdk::MavlinkPassthrough::CommandLong cmd{};
    cmd.command = MAV_CMD_REQUEST_MESSAGE;
    cmd.target_sysid= m_pass_thru->get_target_sysid();
    cmd.target_compid=m_pass_thru->get_target_compid();
    cmd.param1=MAVLINK_MSG_ID_HOME_POSITION;
    const auto res=m_pass_thru->send_command_long(cmd);
    if(res==mavsdk::MavlinkPassthrough::Result::Success){
        const auto msg="Request home Success!!";
        qDebug()<<msg;
        HUDLogMessagesModel::instance().add_message_info(msg);
    }else {
        const auto msg=mavsdk::helper::to_string2("Request home error:",res);
        qDebug()<<msg.c_str();
        HUDLogMessagesModel::instance().add_message_warning(msg.c_str());
    }
}

bool FCMavlinkSystem::enable_disable_mission_updates(bool enable)
{
    if(enable){
        // Enable mission updates via mavsdk
        // by instantiating the mavsdk mission instance, we now automatically get updates, but manually parse the mission updates in the main mavlink message callback.
        if(m_system==nullptr){
             HUDLogMessagesModel::instance().add_message_info("No FC");
             return false;
        }
        if(m_mission==nullptr){
            // must be manually enabled by the user to save resources
            m_mission=std::make_shared<mavsdk::Mission>(m_system);
            auto cb=[this](mavsdk::Mission::MissionProgress mp){
                //qDebug()<<"Mission progress: "<<mp.current<<":"<<mp.total;
            };
            m_mission->subscribe_mission_progress(cb);
            const auto [res,plan]=m_mission->download_mission();
            if(res!=mavsdk::Mission::Result::Success){
                std::stringstream ss;
                ss<<"Mission "<<res;
                HUDLogMessagesModel::instance().add_message_warning(ss.str().c_str());
            }
            qDebug()<<"mission items:"<<plan.mission_items.size();
            HUDLogMessagesModel::instance().add_message_info("Mission updates enabled");
        }else{
            HUDLogMessagesModel::instance().add_message_info("Mission updates already enabled");
        }
    }else{
        if(m_mission!=nullptr){
            // disable mission updates via mavsdk
            m_mission=nullptr;
            HUDLogMessagesModel::instance().add_message_info("Mission updates disabled");
        }else{
            HUDLogMessagesModel::instance().add_message_info("Mission updates already disabled");
        }
    }
    return true;
    /*const auto [res,plan]=m_mission->download_mission();
    if(res!=mavsdk::Mission::Result::Success){
        HUDLogMessagesModel::instance().add_message_info("Mission download failure");
        return;
    }
    HUDLogMessagesModel::instance().add_message_info("Mission download success");*/
    /*auto cb=[this](mavsdk::Mission::MissionProgress mp){
        //qDebug()<<"Mission progress: "<<mp.current<<":"<<mp.total;
    };
    m_mission->subscribe_mission_progress(cb);*/
}

void FCMavlinkSystem::send_message_hud_connection(bool connected)
{
    std::stringstream message;
    message << "FC ";
    if(connected){
        message << "connected";
        HUDLogMessagesModel::instance().add_message_info(message.str().c_str());
    }else{
        message << "disconnected";
        HUDLogMessagesModel::instance().add_message_warning(message.str().c_str());
    }
}

void FCMavlinkSystem::update_alive()
{
    if(m_last_heartbeat_ms==-1){
        // we did not get any heartbeat (yet)
        set_is_alive(false);
    }else{
        const auto elapsed_since_last_heartbeat=QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_heartbeat_ms;
        // after 3 seconds, consider as "not alive"
        const bool alive=elapsed_since_last_heartbeat< 4*1000;
        if(alive != m_is_alive){
            // message when state changes
            send_message_hud_connection(alive);
            //
            set_is_alive(alive);
        }
    }
    recalculate_efficiency();
    //test_set_data_stream_rates();
}

void FCMavlinkSystem::test_set_data_stream_rates()
{
    if(m_rate_success)return;
    if(m_rate_n_times_tried>4){
        return;
    }
    qDebug()<<"test_set_data_stream_rates";
    if(!m_pass_thru){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        qDebug()<<"No fc pass_thru module";
        return;
    }
    //qDebug() << "test_set_data_stream_rates:" << _pass_thru->get_target_sysid();
    //qDebug() << "test_set_data_stream_rates:" << _pass_thru->get_target_compid();
    mavsdk::MavlinkPassthrough::CommandLong cmd;
    cmd.command = MAV_CMD_SET_MESSAGE_INTERVAL;
    cmd.target_sysid= m_pass_thru->get_target_sysid();
    cmd.target_compid=m_pass_thru->get_target_compid();
    cmd.param1=MAVLINK_MSG_ID_ATTITUDE; // affects artificial horizon update rate
    const int interval_us=std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::milliseconds(10)).count();
    cmd.param2=interval_us;
    const auto res=m_pass_thru->send_command_long(cmd);
    if(res==mavsdk::MavlinkPassthrough::Result::Success){
        const auto msg="test_set_data_stream_rates() Success!!";
        qDebug()<<msg;
        m_rate_success=true;
    }
    else {
        const auto msg=mavsdk::helper::to_string2("test_set_data_stream_rates() error:",res);
        qDebug()<<msg.c_str();
    }
    m_rate_n_times_tried++;
    /*auto cb=[](mavsdk::MavlinkPassthrough::Result res){
        std::stringstream ss;
        ss<<"send_return_to_launch: result: "<<res;
        qDebug()<<ss.str().c_str();
    };*/
}

bool FCMavlinkSystem::get_SHOW_FC_MESSAGES_IN_HUD()
{
    QSettings settings;
    return settings.value("show_fc_messages_in_hud", false).toBool();
}

void FCMavlinkSystem::recalculate_efficiency()
{
    // We recalculate the efficiency in X second intervals
    const auto elapsed=std::chrono::steady_clock::now()-m_efficiency_last_update;
    if(elapsed<std::chrono::seconds(10)){
        return;
    }
    //qDebug()<<"FCMavlinkSystem::recalculate_efficiency()";
    m_efficiency_last_update=std::chrono::steady_clock::now();
    const double delta_distance_m=m_flight_distance_m-m_efficiency_last_distance_m;
    const double delta_distance_km=delta_distance_m / 1000.0;
    const int delta_charge_mah=m_battery_consumed_mah-m_efficiency_last_charge_consumed_mAh;
    if(delta_distance_m>0 && delta_charge_mah>0){
        //qDebug()<<"recalculate_efficiency: delta_distance_m:"<<delta_distance_m<<" delta_charge_mah:"<<delta_charge_mah;
        // recalculate and update efficiency
        const int efficiency_mah_per_km=Telemetryutil::calculate_efficiency_in_mah_per_km(delta_charge_mah,delta_distance_km);
        set_battery_consumed_mah_per_km(efficiency_mah_per_km);
        //qDebug()<<"FCMavlinkSystem::recalculate_efficiency:"<<efficiency_mah_per_km;
    }else{
        //qDebug()<<"FCMavlinkSystem::recalculate_efficiency - cannot";
    }
    m_efficiency_last_distance_m=m_flight_distance_m;
    m_efficiency_last_charge_consumed_mAh=m_battery_consumed_mah;
}
