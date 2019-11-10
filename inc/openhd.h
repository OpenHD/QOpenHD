#ifndef OPENHD_H
#define OPENHD_H

#include <QObject>
#include <QtQuick>


#if defined(ENABLE_SPEECH)
#include <QtTextToSpeech/QTextToSpeech>
#endif

class OpenHD : public QObject
{
    Q_OBJECT

public:
    explicit OpenHD(QObject *parent = nullptr);
    static OpenHD* instance();

    void init();

    void telemetryMessage(QString message, int level);
    void calculate_home_distance();
    void calculate_home_course();


    Q_PROPERTY(QString gstreamer_version READ get_gstreamer_version NOTIFY gstreamer_version_changed)
    QString get_gstreamer_version();

    Q_PROPERTY(QString qt_version READ get_qt_version NOTIFY qt_version_changed)
    QString get_qt_version();


    Q_PROPERTY(double home_distance MEMBER m_home_distance WRITE set_home_distance NOTIFY home_distance_changed)
    void set_home_distance(double home_distance);

    Q_PROPERTY(double home_course MEMBER m_home_course WRITE set_home_course NOTIFY home_course_changed)
    void set_home_course(double home_course);

    Q_PROPERTY(QString boot_time MEMBER m_boot_time WRITE set_boot_time NOTIFY boot_time_changed)
    void set_boot_time(QString boot_time);

    Q_PROPERTY(QString alt_rel MEMBER m_alt_rel WRITE set_alt_rel NOTIFY alt_rel_changed)
    void set_alt_rel(QString alt_rel);

    Q_PROPERTY(QString alt_msl MEMBER m_alt_msl WRITE set_alt_msl NOTIFY alt_msl_changed)
    void set_alt_msl(QString alt_msl);

    Q_PROPERTY(int vx MEMBER m_vx WRITE set_vx NOTIFY vx_changed)
    void set_vx(int vx);

    Q_PROPERTY(int vy MEMBER m_vy WRITE set_vy NOTIFY vy_changed)
    void set_vy(int vy);

    Q_PROPERTY(int vz MEMBER m_vz WRITE set_vz NOTIFY vz_changed)
    void set_vz(int vz);

    Q_PROPERTY(QString hdg MEMBER m_hdg WRITE set_hdg NOTIFY hdg_changed)
    void set_hdg(QString hdg);

    Q_PROPERTY(double hdg_raw MEMBER m_hdg_raw WRITE set_hdg_raw NOTIFY hdg_raw_changed)
    void set_hdg_raw(double hdg_raw);

    Q_PROPERTY(QString speed MEMBER m_speed WRITE set_speed NOTIFY speed_changed)
    void set_speed(QString speed);

    Q_PROPERTY(bool armed MEMBER m_armed WRITE set_armed NOTIFY armed_changed)
    void set_armed(bool armed);

    Q_PROPERTY(QString flight_mode MEMBER m_flight_mode WRITE set_flight_mode NOTIFY flight_mode_changed)
    void set_flight_mode(QString flight_mode);

    Q_PROPERTY(QString homelat MEMBER m_homelat WRITE set_homelat NOTIFY homelat_changed)
    void set_homelat(QString homelat);

    Q_PROPERTY(double homelat_raw MEMBER m_homelat_raw WRITE set_homelat_raw NOTIFY homelat_raw_changed)
    void set_homelat_raw(double homelat_raw);

    Q_PROPERTY(QString homelon MEMBER m_homelon WRITE set_homelon NOTIFY homelon_changed)
    void set_homelon(QString homelon);

    Q_PROPERTY(double homelon_raw MEMBER m_homelon_raw WRITE set_homelon_raw NOTIFY homelon_raw_changed)
    void set_homelon_raw(double homelon_raw);

    Q_PROPERTY(QString lat MEMBER m_lat WRITE set_lat NOTIFY lat_changed)
    void set_lat(QString lat);

    Q_PROPERTY(double lat_raw MEMBER m_lat_raw WRITE set_lat_raw NOTIFY lat_raw_changed)
    void set_lat_raw(double lat_raw);

    Q_PROPERTY(QString lon MEMBER m_lon WRITE set_lon NOTIFY lon_changed)
    void set_lon(QString lon);

    Q_PROPERTY(double lon_raw MEMBER m_lon_raw WRITE set_lon_raw NOTIFY lon_raw_changed)
    void set_lon_raw(double lon_raw);

    Q_PROPERTY(QString satellites_visible MEMBER m_satellites_visible WRITE set_satellites_visible NOTIFY satellites_visible_changed)
    void set_satellites_visible(QString satellites_visible);

    Q_PROPERTY(QString gps_hdop MEMBER m_gps_hdop WRITE set_gps_hdop NOTIFY gps_hdop_changed)
    void set_gps_hdop(QString gps_hdop);

    Q_PROPERTY(QString battery_percent MEMBER m_battery_percent WRITE set_battery_percent NOTIFY battery_percent_changed)
    void set_battery_percent(QString battery_percent);

    Q_PROPERTY(QString battery_voltage MEMBER m_battery_voltage WRITE set_battery_voltage NOTIFY battery_voltage_changed)
    void set_battery_voltage(QString battery_voltage);

    Q_PROPERTY(double battery_voltage_raw MEMBER m_battery_voltage_raw WRITE set_battery_voltage_raw NOTIFY battery_voltage_raw_changed)
    void set_battery_voltage_raw(double battery_voltage_raw);

    Q_PROPERTY(QString battery_current MEMBER m_battery_current WRITE set_battery_current NOTIFY battery_current_changed)
    void set_battery_current(QString battery_current);

    Q_PROPERTY(QString battery_gauge MEMBER m_battery_gauge WRITE set_battery_gauge NOTIFY battery_gauge_changed)
    void set_battery_gauge(QString battery_gauge);

    Q_PROPERTY(float pitch_raw MEMBER m_pitch_raw WRITE set_pitch_raw NOTIFY pitch_raw_changed)
    void set_pitch_raw(float pitch_raw);

    Q_PROPERTY(float roll_raw MEMBER m_roll_raw WRITE set_roll_raw NOTIFY roll_raw_changed)
    void set_roll_raw(float roll_raw);

    Q_PROPERTY(float yaw_raw MEMBER m_yaw_raw WRITE set_yaw_raw NOTIFY pitch_raw_changed)
    void set_yaw_raw(float yaw_raw);


    Q_PROPERTY(double throttle MEMBER m_throttle WRITE set_throttle NOTIFY throttle_changed)
    void set_throttle(double throttle);


    // openhd

    Q_PROPERTY(QString downlink_rssi MEMBER m_downlink_rssi WRITE set_downlink_rssi NOTIFY downlink_rssi_changed)
    void set_downlink_rssi(QString downlink_rssi);

    Q_PROPERTY(QString current_signal_joystick_uplink MEMBER m_current_signal_joystick_uplink WRITE set_current_signal_joystick_uplink NOTIFY current_signal_joystick_uplink_changed)
    void set_current_signal_joystick_uplink(QString current_signal_joystick_uplink);

    Q_PROPERTY(QString lost_packet_cnt_rc MEMBER m_lost_packet_cnt_rc WRITE set_lost_packet_cnt_rc NOTIFY lost_packet_cnt_rc_changed)
    void set_lost_packet_cnt_rc(QString lost_packet_cnt_rc);

    Q_PROPERTY(QString lost_packet_cnt_telemetry_up MEMBER m_lost_packet_cnt_telemetry_up WRITE set_lost_packet_cnt_telemetry_up NOTIFY lost_packet_cnt_telemetry_up_changed)
    void set_lost_packet_cnt_telemetry_up(QString lost_packet_cnt);

    Q_PROPERTY(QString kbitrate MEMBER m_kbitrate WRITE set_kbitrate NOTIFY kbitrate_changed)
    void set_kbitrate(QString kbitrate);

    Q_PROPERTY(QString kbitrate_set MEMBER m_kbitrate_set WRITE set_kbitrate_set NOTIFY kbitrate_set_changed)
    void set_kbitrate_set(QString kbitrate_set);

    Q_PROPERTY(QString kbitrate_measured MEMBER m_kbitrate_measured WRITE set_kbitrate_measured NOTIFY kbitrate_measured_changed)
    void set_kbitrate_measured(QString kbitrate_measured);

    Q_PROPERTY(QString cpuload_gnd MEMBER m_cpuload_gnd WRITE set_cpuload_gnd NOTIFY cpuload_gnd_changed)
    void set_cpuload_gnd(QString cpuload_gnd);

    Q_PROPERTY(QString cpuload_air MEMBER m_cpuload_air WRITE set_cpuload_air NOTIFY cpuload_air_changed)
    void set_cpuload_air(QString cpuload_air);

    Q_PROPERTY(QString temp_gnd MEMBER m_temp_gnd WRITE set_temp_gnd NOTIFY temp_gnd_changed)
    void set_temp_gnd(QString temp_gnd);

    Q_PROPERTY(QString temp_air MEMBER m_temp_air WRITE set_temp_air NOTIFY temp_air_changed)
    void set_temp_air(QString temp_air);

    Q_PROPERTY(QString damaged_block_cnt MEMBER m_damaged_block_cnt WRITE set_damaged_block_cnt NOTIFY damaged_block_cnt_changed)
    void set_damaged_block_cnt(QString damaged_block_cnt);

    Q_PROPERTY(QString lost_packet_cnt MEMBER m_lost_packet_cnt WRITE set_lost_packet_cnt NOTIFY lost_packet_cnt_changed)
    void set_lost_packet_cnt(QString lost_packet_cnt);

    Q_PROPERTY(bool air_undervolt MEMBER m_air_undervolt WRITE set_air_undervolt NOTIFY air_undervolt_changed)
    void set_air_undervolt(bool air_undervolt);


    Q_PROPERTY(bool cts MEMBER m_cts WRITE set_cts NOTIFY cts_changed)
    void set_cts(bool cts);


    Q_PROPERTY(QString flight_time MEMBER m_flight_time WRITE set_flight_time NOTIFY flight_time_changed)
    void set_flight_time(QString flight_time);

signals:
    // system
    void gstreamer_version_changed();
    void qt_version_changed();

    // mavlink
    void boot_time_changed(QString boot_time);
    void alt_rel_changed(QString alt_rel);
    void alt_msl_changed(QString alt_msl);
    void vx_changed(int vx);
    void vy_changed(int vy);
    void vz_changed(int vz);
    void hdg_changed(QString hdg);
    void hdg_raw_changed(double hdg_raw);
    void speed_changed(QString speed);
    void armed_changed(bool armed);
    void flight_mode_changed(QString flight_mode);
    void homelat_changed(QString homelat);
    void homelat_raw_changed(double homelat_raw);
    void homelon_changed(QString homelon);
    void homelon_raw_changed(double homelon_raw);
    void lat_changed(QString lat);
    void lat_raw_changed(double lat_raw);
    void lon_changed(QString lon);
    void lon_raw_changed(double lon_raw);
    void home_distance_changed(double home_distance);
    void home_course_changed(double home_course);
    void battery_percent_changed(QString battery_percent);
    void battery_voltage_changed(QString battery_voltage);
    void battery_voltage_raw_changed(double battery_voltage);
    void battery_current_changed(QString battery_current);
    void battery_gauge_changed(QString battery_gauge);
    void satellites_visible_changed(QString satellites_visible);
    void gps_hdop_changed(QString gps_hdop);
    void pitch_raw_changed(float pitch_raw);
    void roll_raw_changed(float roll_raw);
    void yaw_raw_changed(float yaw_raw);
    void messageReceived(QString message, int level);

    void throttle_changed(double throttle);


    // openhd
    void downlink_rssi_changed(QString downlink_rssi);
    void current_signal_joystick_uplink_changed(QString current_signal_joystick_uplink);
    void lost_packet_cnt_rc_changed(QString lost_packet_cnt_rc);
    void lost_packet_cnt_telemetry_up_changed(QString lost_packet_cnt_telemetry_up);
    void kbitrate_changed(QString kbitrate);
    void kbitrate_set_changed(QString kbitrate_set);
    void kbitrate_measured_changed(QString kbitrate_measured);
    void cpuload_gnd_changed(QString cpuload_gnd);
    void temp_gnd_changed(QString temp_gnd);
    void cpuload_air_changed(QString cpuload_air);
    void temp_air_changed(QString temp_air);
    void damaged_block_cnt_changed(QString damaged_block_cnt);
    void lost_packet_cnt_changed(QString lost_packet_cnt);
    void air_undervolt_changed(bool air_undervolt);
    void cts_changed(bool cts);

    void flight_time_changed(QString flight_time);


private:
#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif

    void updateFlightTimer();

    // mavlink
    QString m_boot_time = "0";

    QString m_alt_rel = "0";
    QString m_alt_msl = "0";

    int m_vx = 0;
    int m_vy = 0;
    int m_vz = 0;

    QString m_hdg = "360";
    double m_hdg_raw=360.0;

    QString m_speed = "0";

    bool m_armed = false;
    QString m_flight_mode = "Stabilize";
    QString m_homelat = "0.000000";
    double m_homelat_raw = 0.0;
    QString m_homelon = "0.000000";
    double m_homelon_raw = 0.0;
    QString m_lat = "0.000000";
    double m_lat_raw = 0.0;
    QString m_lon = "0.000000";
    double m_lon_raw = 0.0;
    double m_home_distance = 0.0;
    double m_home_course = 0.0;
    QString m_battery_percent = "0%";
    QString m_battery_current = "0.0a";
    QString m_battery_voltage = "0.0v";
    double m_battery_voltage_raw = 0.0;
    QString m_battery_gauge = "\uf091";
    QString m_satellites_visible = "0";
    QString m_gps_hdop = "99.00";

    float m_roll_raw = 0.0;
    float m_yaw_raw = 0.0;
    float m_pitch_raw = 0.0;

    // openhd

    QString m_downlink_rssi = "-127";
    QString m_current_signal_joystick_uplink = "-127";
    QString m_lost_packet_cnt_rc = "0";
    QString m_lost_packet_cnt_telemetry_up = "0";

    QString m_kbitrate = "0.0";
    QString m_kbitrate_measured = "0.0";
    QString m_kbitrate_set = "0.0";

    QString m_cpuload_gnd = "0%";
    QString m_temp_gnd = "0°";
    QString m_cpuload_air = "0%";
    QString m_temp_air = "0°";

    QString m_damaged_block_cnt = "0";
    QString m_lost_packet_cnt = "0";

    bool m_air_undervolt = false;
    bool m_cts = false;

    double m_throttle = 0;

    QString m_flight_time = "00:00";


    QTime flightTimeStart;
    QTimer flightTimerCheck;
};



QObject *openHDSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);


#endif // OPENHD_H
