#include "openhd.h"

#include "mavlinktelemetry.h"
#include "openhdtelemetry.h"
#include "localmessage.h"

#include <GeographicLib/Geodesic.hpp>


#if defined(ENABLE_GSTREAMER)
#include <gst/gst.h>
#include<QDebug>
#endif

static OpenHD* _instance = nullptr;

OpenHD* OpenHD::instance() {
    if (_instance == nullptr) {
        _instance = new OpenHD();
    }
    return _instance;
}

OpenHD::OpenHD(QObject *parent): QObject(parent) {

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
#endif

    set_ground_gpio({0, 0, 0, 0, 0, 0, 0, 0});
    set_air_gpio({0, 0, 0, 0, 0, 0, 0, 0});

    timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, this, &OpenHD::updateFlightTimer);
    timer->start(1000);

    auto mavlink = MavlinkTelemetry::instance();
    connect(mavlink, &MavlinkTelemetry::last_heartbeat_changed, this, &OpenHD::set_last_telemetry_heartbeat);

    auto openhd = OpenHDTelemetry::instance();
    connect(openhd, &OpenHDTelemetry::last_heartbeat_changed, this, &OpenHD::set_last_openhd_heartbeat);
}


QString OpenHD::get_gstreamer_version() {
#if defined(ENABLE_GSTREAMER)
    guint major, minor, micro, nano;
    gst_version(&major, &minor, &micro, &nano);
    QString gst_ver = QString();
    QTextStream s(&gst_ver);

    s << major;
    s << ".";
    s << minor;
    s << ".";
    s << micro;

    return gst_ver;
#else
    return "N/A";
#endif
}

QString OpenHD::get_qt_version() {
    QString qt_ver = qVersion();
    return qt_ver;
}


void OpenHD::setWifiAdapter0(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter0Changed(received_packet_cnt, current_signal_dbm, signal_good);
}


void OpenHD::setWifiAdapter1(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter1Changed(received_packet_cnt, current_signal_dbm, signal_good);
}


void OpenHD::setWifiAdapter2(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter2Changed(received_packet_cnt, current_signal_dbm, signal_good);
}


void OpenHD::setWifiAdapter3(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter3Changed(received_packet_cnt, current_signal_dbm, signal_good);
}


void OpenHD::setWifiAdapter4(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter4Changed(received_packet_cnt, current_signal_dbm, signal_good);
}


void OpenHD::setWifiAdapter5(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good) {
    emit wifiAdapter5Changed(received_packet_cnt, current_signal_dbm, signal_good);
}

void OpenHD::telemetryMessage(QString message, int level) {
    emit messageReceived(message, level);
#if defined(ENABLE_SPEECH)
    QSettings settings;
    auto enable_speech = settings.value("enable_speech", QVariant(0));
    if (enable_speech == 1 && level >= 3) {
        OpenHD::instance()->m_speech->say(message);
    }
#endif
}

void OpenHD::updateFlightTimer() {
    if (m_armed) {
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

void OpenHD::findGcsPosition() {
    if (gcs_position_set==false){
        //only attempt to set gcs home position if hdop<3m and unarmed
        if (m_gps_hdop<3 && m_armed==false){
            //get 20 good gps readings before setting
            if (++gps_quality_count == 20) {
                set_homelat(m_lat);
                set_homelon(m_lon);
                gcs_position_set=true;
                LocalMessage::instance()->showMessage("Home Position set by OpenHD", 2);
            }
        }
    }
}

void OpenHD::updateFlightDistance() {
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
        qDebug() << "added distance" << added_distance;
        total_dist = total_dist + added_distance;

        qDebug() << "total distance" << total_dist;
        set_flight_distance( total_dist);
    }
}

void OpenHD::updateAppMah() {
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

void OpenHD::set_boot_time(int boot_time) {
    m_boot_time = boot_time;
    emit boot_time_changed(m_boot_time);
}

void OpenHD::set_alt_rel(double alt_rel) {
    m_alt_rel = alt_rel;
    emit alt_rel_changed(m_alt_rel);
}

void OpenHD::set_alt_msl(double alt_msl) {
    m_alt_msl = alt_msl;
    emit alt_msl_changed(m_alt_msl);
}

void OpenHD::set_vx(double vx) {
    m_vx = vx;
    emit vx_changed(m_vx);
}

void OpenHD::set_vy(double vy) {
    m_vy = vy;
    emit vy_changed(m_vy);
}

void OpenHD::set_vz(double vz) {
    m_vz = vz;
    emit vz_changed(m_vz);
}

void OpenHD::set_hdg(int hdg) {
    m_hdg = hdg;
    emit hdg_changed(m_hdg);
}

void OpenHD::set_speed(double speed) {
    m_speed = speed;
    emit speed_changed(m_speed);
}

void OpenHD::set_airspeed(double airspeed) {
    m_airspeed = airspeed;
    emit airspeed_changed(m_airspeed);
}

void OpenHD::set_armed(bool armed) {
#if defined(ENABLE_SPEECH)
    QSettings settings;
    auto enable_speech = settings.value("enable_speech", QVariant(0));

    if (enable_speech == 1) {
        if (armed && !m_armed) {
            m_speech->say("armed");
        } else if (!armed && m_armed) {
            m_speech->say("disarmed");
        }
    }
#endif

    if (armed && !m_armed) {
        /*
         * Restart the flight timer when the vehicle transitions to the armed state.
         *
         * In the updateFlightTimer() callback we skip updating the property if the
         * vehicle is disarmed, causing it to appear to stop in the UI.
         */
        flightTimeStart.start();

        if(armed==true && m_homelat == 0.0 && m_homelon == 0.0){
            LocalMessage::instance()->showMessage("No Home Position in OpenHD", 4);
        }
    }

    m_armed = armed;
    emit armed_changed(m_armed);
}

void OpenHD::set_flight_mode(QString flight_mode) {
#if defined(ENABLE_SPEECH)
    if (m_flight_mode != flight_mode) {
        m_speech->say(tr("%1 flight mode").arg(flight_mode));
    }
#endif
    m_flight_mode = flight_mode;

    emit flight_mode_changed(m_flight_mode);
}

void OpenHD::set_homelat(double homelat) {
    m_homelat = homelat;
    gcs_position_set = true;
    emit homelat_changed(m_homelat);
}

void OpenHD::set_homelon(double homelon) {
    m_homelon = homelon;
    gcs_position_set = true;
    emit homelon_changed(m_homelon);
}

void OpenHD::calculate_home_distance() {
    // if home lat/long are zero the calculation will be wrong so we skip it
    if (m_armed && m_homelat != 0.0 && m_homelon != 0.0) {
        GeographicLib::Math::real s12;
        GeographicLib::Math::real azi1;
        GeographicLib::Math::real azi2;

        GeographicLib::Geodesic geod(GeographicLib::Constants::WGS84_a(), GeographicLib::Constants::WGS84_f());
        geod.Inverse(m_homelat, m_homelon, m_lat, m_lon, s12, azi1, azi2);

        /* todo: this could be easily extended to save the azimuth as well, which gives us the direction
           home for free as a result of the calculation above.
        */
        set_home_distance(s12);
    } else {
        /*
         * If the system isn't armed we don't want to calculate anything as the home position
         * will be wrong or zero
         */
        set_home_distance(0.0);
    }
}

void OpenHD::set_home_distance(double home_distance) {
    m_home_distance = home_distance;
    emit home_distance_changed(home_distance);
}

void OpenHD::calculate_home_course () {

    //qDebug() << "Home lat lon " << m_homelat << " :" << m_homelon;

    double  dlon = (m_lon-m_homelon)*0.017453292519;
    double lat1 = (m_homelat)*0.017453292519;
    double lat2 = (m_lat)*0.017453292519;
    double  a1 = sin(dlon) * cos(lat2);
    double  a2 = sin(lat1) * cos(lat2) * cos(dlon);
    a2 = cos(lat1) * sin(lat2) - a2;
    a2 = atan2(a1, a2);
    if (a2 < 0.0) a2 += M_PI*2;

    set_home_course(180.0f / M_PI*(a2));

}

void OpenHD::set_home_course(double home_course) {
    //so arrow points correct way it must be relative to heading
    double rel_heading = home_course - m_hdg;
    if (rel_heading < 0) rel_heading += 360;
    if (rel_heading >= 360) rel_heading -=360;
    m_home_course = rel_heading;
    emit home_course_changed(home_course);
}

void OpenHD::set_lat(double lat) {
    m_lat = lat;
    emit lat_changed(m_lat);
}

void OpenHD::set_lon(double lon) {
    m_lon = lon;
    emit lon_changed(m_lon);
}

void OpenHD::set_battery_percent(int battery_percent) {
    m_battery_percent = battery_percent;
    emit battery_percent_changed(m_battery_percent);
}

void OpenHD::set_battery_voltage(double battery_voltage) {
    m_battery_voltage = battery_voltage;
    emit battery_voltage_changed(m_battery_voltage);
}

void OpenHD::set_battery_current(double battery_current) {
    m_battery_current = battery_current;
    emit battery_current_changed(m_battery_current);
}

void OpenHD::set_battery_gauge(QString battery_gauge) {
    m_battery_gauge = battery_gauge;
    emit battery_gauge_changed(m_battery_gauge);
}

void OpenHD::set_satellites_visible(int satellites_visible) {
    m_satellites_visible = satellites_visible;
    emit satellites_visible_changed(m_satellites_visible);
}

void OpenHD::set_gps_hdop(double gps_hdop) {
    m_gps_hdop = gps_hdop;
    emit gps_hdop_changed(m_gps_hdop);
}

void OpenHD::set_pitch(double pitch) {
    m_pitch = pitch;
    emit pitch_changed(m_pitch);
}

void OpenHD::set_roll(double roll) {
    m_roll = roll;
    emit roll_changed(m_roll);
}

void OpenHD::set_yaw(double yaw) {
    m_yaw = yaw;
    emit yaw_changed(m_yaw);
}

void OpenHD::set_throttle(double throttle) {
    m_throttle = throttle;
     emit throttle_changed(m_throttle);
}

void OpenHD::set_vibration_x(float vibration_x) {
    m_vibration_x= vibration_x;
     emit vibration_x_changed(m_vibration_x);
}

void OpenHD::set_vibration_y(float vibration_y) {
    m_vibration_y= vibration_y;
     emit vibration_y_changed(m_vibration_y);
}

void OpenHD::set_vibration_z(float vibration_z) {
    m_vibration_z= vibration_z;
     emit vibration_z_changed(m_vibration_z);
}

void OpenHD::set_clipping_x(float clipping_x) {
    m_clipping_x= clipping_x;
     emit clipping_x_changed(m_clipping_x);
}

void OpenHD::set_clipping_y(float clipping_y) {
    m_clipping_y= clipping_y;
     emit clipping_y_changed(m_clipping_y);
}

void OpenHD::set_clipping_z(float clipping_z) {
    m_clipping_z= clipping_z;
     emit clipping_z_changed(m_clipping_z);
}

void OpenHD::set_vsi(float vsi) {
    m_vsi= vsi;
     emit vsi_changed(m_vsi);
}

void OpenHD::set_lateral_speed(double lateral_speed) {
    m_lateral_speed= lateral_speed;
     emit lateral_speed_changed(m_lateral_speed);
}

void OpenHD::set_wind_speed(double wind_speed) {
    m_wind_speed= wind_speed;
     emit wind_speed_changed(m_wind_speed);
}

void OpenHD::set_wind_direction(double wind_direction) {
    m_wind_direction= wind_direction;
     emit wind_direction_changed(m_wind_direction);
}

void OpenHD::set_mav_wind_direction(float mav_wind_direction) {
    m_mav_wind_direction= mav_wind_direction;
     emit mav_wind_direction_changed(m_mav_wind_direction);
}

void OpenHD::set_mav_wind_speed(float mav_wind_speed) {
    m_mav_wind_speed= mav_wind_speed;
     emit mav_wind_speed_changed(m_mav_wind_speed);
}

void OpenHD::set_control_pitch(int control_pitch) {
    m_control_pitch = control_pitch;
     emit control_pitch_changed(m_control_pitch);
}

void OpenHD::set_control_roll(int control_roll) {
    m_control_roll = control_roll;
     emit control_roll_changed(m_control_roll);
}

void OpenHD::set_control_yaw(int control_yaw) {
    m_control_yaw = control_yaw;
     emit control_yaw_changed(m_control_yaw);
}

void OpenHD::set_control_throttle(int control_throttle) {
    m_control_throttle = control_throttle;
     emit control_throttle_changed(m_control_throttle);
}

void OpenHD::set_downlink_rssi(int downlink_rssi) {
    m_downlink_rssi = downlink_rssi;
    emit downlink_rssi_changed(m_downlink_rssi);
}

void OpenHD::set_current_signal_joystick_uplink(int current_signal_joystick_uplink) {
    m_current_signal_joystick_uplink = current_signal_joystick_uplink;
    emit current_signal_joystick_uplink_changed(m_current_signal_joystick_uplink);
}

void OpenHD::set_lost_packet_cnt_rc(unsigned int lost_packet_cnt_rc) {
    m_lost_packet_cnt_rc = lost_packet_cnt_rc;
    emit lost_packet_cnt_rc_changed(m_lost_packet_cnt_rc);
}

void OpenHD::set_lost_packet_cnt_telemetry_up(unsigned int lost_packet_cnt_telemetry_up) {
    m_lost_packet_cnt_telemetry_up = lost_packet_cnt_telemetry_up;
    emit lost_packet_cnt_telemetry_up_changed(m_lost_packet_cnt_telemetry_up);
}

void OpenHD::set_skipped_packet_cnt(unsigned int skipped_packet_cnt) {
    m_skipped_packet_cnt = skipped_packet_cnt;
    emit skipped_packet_cnt_changed(skipped_packet_cnt);
}

void OpenHD::set_injection_fail_cnt(unsigned int injection_fail_cnt) {
    m_injection_fail_cnt = injection_fail_cnt;
    emit injection_fail_cnt_changed(m_injection_fail_cnt);
}

void OpenHD::set_kbitrate(double kbitrate) {
    m_kbitrate = kbitrate;
    emit kbitrate_changed(m_kbitrate);
}

void OpenHD::set_kbitrate_set(double kbitrate_set) {
    m_kbitrate_set = kbitrate_set;
    emit kbitrate_set_changed(m_kbitrate_set);
}

void OpenHD::set_kbitrate_measured(double kbitrate_measured) {
    m_kbitrate_measured = kbitrate_measured;
    emit kbitrate_measured_changed(m_kbitrate_measured);
}

void OpenHD::set_cpuload_gnd(int cpuload_gnd) {
    m_cpuload_gnd = cpuload_gnd;
    emit cpuload_gnd_changed(m_cpuload_gnd);
}

void OpenHD::set_cpuload_air(int cpuload_air) {
    m_cpuload_air = cpuload_air;
    emit cpuload_air_changed(m_cpuload_air);
}

void OpenHD::set_temp_gnd(int temp_gnd) {
    m_temp_gnd = temp_gnd;
    emit temp_gnd_changed(m_temp_gnd);
}

void OpenHD::set_temp_air(int temp_air) {
    m_temp_air = temp_air;
    emit temp_air_changed(m_temp_air);
}

void OpenHD::set_damaged_block_cnt(unsigned int damaged_block_cnt) {
    m_damaged_block_cnt = damaged_block_cnt;
    emit damaged_block_cnt_changed(m_damaged_block_cnt);
}

void OpenHD::set_damaged_block_percent(int damaged_block_percent) {
    m_damaged_block_percent = damaged_block_percent;
    emit damaged_block_percent_changed(m_damaged_block_percent);
}

void OpenHD::set_lost_packet_cnt(unsigned int lost_packet_cnt) {
    m_lost_packet_cnt = lost_packet_cnt;
    emit lost_packet_cnt_changed(m_lost_packet_cnt);
}

void OpenHD::set_lost_packet_percent(int lost_packet_percent) {
    m_lost_packet_percent = lost_packet_percent;
    emit lost_packet_percent_changed(m_lost_packet_percent);
}

void OpenHD::set_air_undervolt(bool air_undervolt) {
    m_air_undervolt = air_undervolt;
    emit air_undervolt_changed(m_air_undervolt);
}

void OpenHD::set_cts(bool cts) {
    m_cts = cts;
    emit cts_changed(m_cts);
}

void OpenHD::set_flight_time(QString flight_time) {
    m_flight_time = flight_time;
    emit flight_time_changed(m_flight_time);
}

void OpenHD::set_flight_distance(double flight_distance) {
    m_flight_distance = flight_distance;
    emit flight_distance_changed(m_flight_distance);
}

void OpenHD::set_flight_mah(double flight_mah) {
    m_flight_mah = flight_mah;
    emit flight_mah_changed(m_flight_mah);
}

void OpenHD::set_app_mah(double app_mah) {
    m_app_mah = app_mah;
    emit app_mah_changed(m_app_mah);
}

void OpenHD::set_last_openhd_heartbeat(qint64 last_openhd_heartbeat) {
    m_last_openhd_heartbeat = last_openhd_heartbeat;
    emit last_openhd_heartbeat_changed(m_last_openhd_heartbeat);
}

void OpenHD::set_last_telemetry_heartbeat(qint64 last_telemetry_heartbeat) {
    m_last_telemetry_heartbeat = last_telemetry_heartbeat;
    emit last_telemetry_heartbeat_changed(m_last_telemetry_heartbeat);
}

void OpenHD::set_main_video_running(bool main_video_running) {
    m_main_video_running = main_video_running;
    emit main_video_running_changed(m_main_video_running);
}

void OpenHD::set_pip_video_running(bool pip_video_running) {
    m_pip_video_running = pip_video_running;
    emit pip_video_running_changed(m_pip_video_running);
}

void OpenHD::set_lte_video_running(bool lte_video_running) {
    m_lte_video_running = lte_video_running;
    emit lte_video_running_changed(m_lte_video_running);
}

void OpenHD::set_ground_gpio(QList<int> ground_gpio){
    m_ground_gpio = ground_gpio;
    emit ground_gpio_changed(m_ground_gpio);
}

void OpenHD::set_air_gpio(QList<int> air_gpio){
    m_air_gpio = air_gpio;
    emit air_gpio_changed(m_air_gpio);
}

void OpenHD::set_ground_gpio_busy(bool ground_gpio_busy){
    m_ground_gpio_busy = ground_gpio_busy;
    emit ground_gpio_busy_changed(ground_gpio_busy);
}

void OpenHD::set_air_gpio_busy(bool air_gpio_busy){
    m_air_gpio_busy = air_gpio_busy;
    emit air_gpio_busy_changed(air_gpio_busy);
}

void OpenHD::set_ground_vin(double ground_vin) {
    m_ground_vin = ground_vin;
    emit ground_vin_changed(m_ground_vin);
}

void OpenHD::set_ground_vout(double ground_vout) {
    m_ground_vout = ground_vout;
    emit ground_vout_changed(m_ground_vout);
}

void OpenHD::set_ground_vbat(double ground_vbat) {
    m_ground_vbat = ground_vbat;
    emit ground_vbat_changed(m_ground_vbat);
}

void OpenHD::set_ground_iout(double ground_iout) {
    m_ground_iout = ground_iout;
    emit ground_iout_changed(m_ground_iout);
}

void OpenHD::updateLateralSpeed(){

    auto resultant_magnitude = sqrt(m_vx * m_vx + m_vy * m_vy);

    //direction of motion vector in radians then converted to degree
    auto resultant_angle = atan2(m_vy , m_vx)*(180/M_PI);

    //converted from degrees to a compass heading
    if (resultant_angle < 0.0){
        resultant_angle += 360;
    }

    //Compare the motion heading to the vehicle heading
    auto left = m_hdg - resultant_angle;
    auto right = resultant_angle - m_hdg;
    if (left < 0) left += 360;
    if (right < 0) right += 360;
    auto heading_diff = left < right ? -left : right;

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
}

void OpenHD::updateWind(){

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


void OpenHD::setRCChannel1(int rcChannel1) {
    mRCChannel1 = rcChannel1;
    emit rcChannel1Changed(mRCChannel1);
}

void OpenHD::setRCChannel2(int rcChannel2) {
    mRCChannel2 = rcChannel2;
    emit rcChannel2Changed(mRCChannel2);
}

void OpenHD::setRCChannel3(int rcChannel3) {
    mRCChannel3 = rcChannel3;
    emit rcChannel3Changed(mRCChannel3);
}

void OpenHD::setRCChannel4(int rcChannel4) {
    mRCChannel4 = rcChannel4;
    emit rcChannel4Changed(mRCChannel4);
}

void OpenHD::setRCChannel5(int rcChannel5) {
    mRCChannel5 = rcChannel5;
    emit rcChannel5Changed(mRCChannel5);
}

void OpenHD::setRCChannel6(int rcChannel6) {
    mRCChannel6 = rcChannel6;
    emit rcChannel6Changed(mRCChannel6);
}

void OpenHD::setRCChannel7(int rcChannel7) {
    mRCChannel7 = rcChannel7;
    emit rcChannel7Changed(mRCChannel7);
}

void OpenHD::setRCChannel8(int rcChannel8) {
    mRCChannel8 = rcChannel8;
    emit rcChannel8Changed(mRCChannel8);
}

