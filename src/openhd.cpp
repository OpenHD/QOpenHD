#include "openhd.h"

#include <GeographicLib/Geodesic.hpp>
#include <GeographicLib/Math.hpp>

#include <gst/gst.h>


static OpenHD* _instance = new OpenHD();

OpenHD::OpenHD(QObject *parent): QObject(parent) {

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
#endif

}

OpenHD* OpenHD::instance() {
    return _instance;
}


void OpenHD::init() {
    //emit gstreamer_version_changed();
}

QString OpenHD::get_gstreamer_version() {
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
}

QString OpenHD::get_qt_version() {
    QString qt_ver = qVersion();
    return qt_ver;
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

void OpenHD::set_boot_time(QString boot_time) {
    m_boot_time = boot_time;
    emit boot_time_changed(m_boot_time);
}

void OpenHD::set_alt_rel(QString alt_rel) {
    m_alt_rel = alt_rel;
    emit alt_rel_changed(m_alt_rel);
}

void OpenHD::set_alt_msl(QString alt_msl) {
    m_alt_msl = alt_msl;
    emit alt_msl_changed(m_alt_msl);
}

void OpenHD::set_vx(int vx) {
    m_vx = vx;
    emit vx_changed(m_vx);
}

void OpenHD::set_vy(int vy) {
    m_vy = vy;
    emit vy_changed(m_vy);
}

void OpenHD::set_vz(int vz) {
    m_vz = vz;
    emit vz_changed(m_vz);
}

void OpenHD::set_hdg(QString hdg) {
    m_hdg = hdg;
    emit hdg_changed(m_hdg);
}

void OpenHD::set_hdg_raw(double hdg_raw) {
    m_hdg_raw = hdg_raw;
    emit hdg_raw_changed(m_hdg_raw);
}

void OpenHD::set_speed(QString speed) {
    m_speed = speed;
    emit speed_changed(m_speed);
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

void OpenHD::set_homelat(QString homelat) {
    m_homelat = homelat;
    emit homelat_changed(m_homelat);
}

void OpenHD::set_homelat_raw(double homelat_raw) {
    m_homelat_raw = homelat_raw;
    emit homelat_raw_changed(m_homelat_raw);
}

void OpenHD::set_homelon(QString homelon) {
    m_homelon = homelon;
    emit homelon_changed(m_homelon);
}

void OpenHD::set_homelon_raw(double homelon_raw) {
    m_homelon_raw = homelon_raw;
    emit homelon_raw_changed(m_homelon_raw);
}

void OpenHD::calculate_home_distance() {
    // if home lat/long are zero the calculation will be wrong so we skip it
    if (m_armed && m_homelat_raw != 0.0 && m_homelon_raw != 0.0) {
        GeographicLib::Math::real s12;
        GeographicLib::Math::real azi1;
        GeographicLib::Math::real azi2;

        GeographicLib::Geodesic geod(GeographicLib::Constants::WGS84_a(), GeographicLib::Constants::WGS84_f());
        geod.Inverse(m_homelat_raw, m_homelon_raw, m_lat_raw, m_lon_raw, s12, azi1, azi2);

        // todo: this could be easily extended to save the azimuth as well, which gives us the direction
        // home for free as a result of the calculation above.
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

    qDebug() << "Home RAW lat lon " << m_homelat_raw << " :" << m_homelon_raw;

    double  dlon = (m_lon_raw-m_homelon_raw)*0.017453292519;
    double lat1 = (m_homelat_raw)*0.017453292519;
    double lat2 = (m_lat_raw)*0.017453292519;
    double  a1 = sin(dlon) * cos(lat2);
    double  a2 = sin(lat1) * cos(lat2) * cos(dlon);
    a2 = cos(lat1) * sin(lat2) - a2;
    a2 = atan2(a1, a2);
    if (a2 < 0.0) a2 += M_PI*2;

    set_home_course(180.0f / M_PI*(a2));

}

void OpenHD::set_home_course(double home_course) {
    //so arrow points correct way it must be relative to heading
    double rel_heading = home_course - m_hdg_raw;
    if (rel_heading < 0) rel_heading += 360;
    if (rel_heading >= 360) rel_heading -=360;
    m_home_course = rel_heading;
    emit home_course_changed(home_course);
}

void OpenHD::set_lat(QString lat) {
    m_lat = lat;
    emit lat_changed(m_lat);
}

void OpenHD::set_lat_raw(double lat_raw) {
    m_lat_raw = lat_raw;
    emit lat_raw_changed(m_lat_raw);
}

void OpenHD::set_lon(QString lon) {
    m_lon = lon;
    emit lon_changed(m_lon);
}

void OpenHD::set_lon_raw(double lon_raw) {
    m_lon_raw = lon_raw;
    emit lon_raw_changed(m_lon_raw);
}

void OpenHD::set_battery_percent(QString battery_percent) {
    m_battery_percent = battery_percent;
    emit battery_percent_changed(m_battery_percent);
}

void OpenHD::set_battery_voltage(QString battery_voltage) {
    m_battery_voltage = battery_voltage;
    emit battery_voltage_changed(m_battery_voltage);
}

void OpenHD::set_battery_voltage_raw(double battery_voltage_raw) {
    m_battery_voltage_raw = battery_voltage_raw;
    emit battery_voltage_raw_changed(m_battery_voltage_raw);
}

void OpenHD::set_battery_current(QString battery_current) {
    m_battery_current = battery_current;
    emit battery_current_changed(m_battery_current);
}

void OpenHD::set_battery_gauge(QString battery_gauge) {
    m_battery_gauge = battery_gauge;
    emit battery_gauge_changed(m_battery_gauge);
}

void OpenHD::set_satellites_visible(QString satellites_visible) {
    m_satellites_visible = satellites_visible;
    emit satellites_visible_changed(m_satellites_visible);
}

void OpenHD::set_gps_hdop(QString gps_hdop) {
    m_gps_hdop = gps_hdop;
    emit gps_hdop_changed(m_gps_hdop);
}

void OpenHD::set_pitch_raw(float pitch_raw) {
    m_pitch_raw = pitch_raw;
    emit pitch_raw_changed(m_pitch_raw);
}

void OpenHD::set_roll_raw(float roll_raw) {
    m_roll_raw = roll_raw;
    emit roll_raw_changed(m_roll_raw);
}

void OpenHD::set_yaw_raw(float yaw_raw) {
    m_yaw_raw = yaw_raw;
    emit yaw_raw_changed(m_yaw_raw);
}

void OpenHD::set_throttle(double throttle) {
    m_throttle = throttle;
     emit throttle_changed(m_throttle);
}

void OpenHD::set_downlink_rssi(QString downlink_rssi) {
    m_downlink_rssi = downlink_rssi;
    emit downlink_rssi_changed(m_downlink_rssi);
}

void OpenHD::set_current_signal_joystick_uplink(QString current_signal_joystick_uplink) {
    m_current_signal_joystick_uplink = current_signal_joystick_uplink;
    emit current_signal_joystick_uplink_changed(m_current_signal_joystick_uplink);
}

void OpenHD::set_lost_packet_cnt_rc(QString lost_packet_cnt_rc) {
    m_lost_packet_cnt_rc = lost_packet_cnt_rc;
    emit lost_packet_cnt_rc_changed(m_lost_packet_cnt_rc);
}

void OpenHD::set_lost_packet_cnt_telemetry_up(QString lost_packet_cnt_telemetry_up) {
    m_lost_packet_cnt_telemetry_up = lost_packet_cnt_telemetry_up;
    emit lost_packet_cnt_telemetry_up_changed(m_lost_packet_cnt_telemetry_up);
}

void OpenHD::set_kbitrate(QString kbitrate) {
    m_kbitrate = kbitrate;
    emit kbitrate_changed(m_kbitrate);
}

void OpenHD::set_kbitrate_set(QString kbitrate_set) {
    m_kbitrate_set = kbitrate_set;
    emit kbitrate_set_changed(m_kbitrate_set);
}

void OpenHD::set_kbitrate_measured(QString kbitrate_measured) {
    m_kbitrate_measured = kbitrate_measured;
    emit kbitrate_measured_changed(m_kbitrate_measured);
}

void OpenHD::set_cpuload_gnd(QString cpuload_gnd) {
    m_cpuload_gnd = cpuload_gnd;
    emit cpuload_gnd_changed(m_cpuload_gnd);
}

void OpenHD::set_cpuload_air(QString cpuload_air) {
    m_cpuload_air = cpuload_air;
    emit cpuload_air_changed(m_cpuload_air);
}

void OpenHD::set_temp_gnd(QString temp_gnd) {
    m_temp_gnd = temp_gnd;
    emit temp_gnd_changed(m_temp_gnd);
}

void OpenHD::set_temp_air(QString temp_air) {
    m_temp_air = temp_air;
    emit temp_air_changed(m_temp_air);
}

void OpenHD::set_damaged_block_cnt(QString damaged_block_cnt) {
    m_damaged_block_cnt = damaged_block_cnt;
    emit damaged_block_cnt_changed(m_damaged_block_cnt);
}

void OpenHD::set_lost_packet_cnt(QString lost_packet_cnt) {
    m_lost_packet_cnt = lost_packet_cnt;
    emit lost_packet_cnt_changed(m_lost_packet_cnt);
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
