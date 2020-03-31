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

    void setWifiAdapters(QList<QVariantMap> adapters);

    Q_INVOKABLE void setGroundGPIO(int pin, bool state) {
        m_ground_gpio[pin] = state ? 1 : 0;
        emit save_ground_gpio(m_ground_gpio);
    }

    Q_INVOKABLE void setAirGPIO(int pin, bool state) {
        m_air_gpio[pin] = state ? 1 : 0;
        emit save_air_gpio(m_air_gpio);
    }


    // public so that a QTimer can call it from main(), temporary fix due to some quirks with
    // the way QTimer and QML singletons/context properties work
    void updateFlightTimer();

    void updateFlightDistance();
    void updateFlightMah();

    Q_PROPERTY(QString gstreamer_version READ get_gstreamer_version NOTIFY gstreamer_version_changed)
    QString get_gstreamer_version();

    Q_PROPERTY(QString qt_version READ get_qt_version NOTIFY qt_version_changed)
    QString get_qt_version();


    Q_PROPERTY(double home_distance MEMBER m_home_distance WRITE set_home_distance NOTIFY home_distance_changed)
    void set_home_distance(double home_distance);

    Q_PROPERTY(double home_course MEMBER m_home_course WRITE set_home_course NOTIFY home_course_changed)
    void set_home_course(double home_course);

    Q_PROPERTY(int boot_time MEMBER m_boot_time WRITE set_boot_time NOTIFY boot_time_changed)
    void set_boot_time(int boot_time);

    Q_PROPERTY(int alt_rel MEMBER m_alt_rel WRITE set_alt_rel NOTIFY alt_rel_changed)
    void set_alt_rel(int alt_rel);

    Q_PROPERTY(int alt_msl MEMBER m_alt_msl WRITE set_alt_msl NOTIFY alt_msl_changed)
    void set_alt_msl(int alt_msl);

    Q_PROPERTY(int vx MEMBER m_vx WRITE set_vx NOTIFY vx_changed)
    void set_vx(int vx);

    Q_PROPERTY(int vy MEMBER m_vy WRITE set_vy NOTIFY vy_changed)
    void set_vy(int vy);

    Q_PROPERTY(int vz MEMBER m_vz WRITE set_vz NOTIFY vz_changed)
    void set_vz(int vz);

    Q_PROPERTY(double hdg MEMBER m_hdg WRITE set_hdg NOTIFY hdg_changed)
    void set_hdg(double hdg);

    Q_PROPERTY(int speed MEMBER m_speed WRITE set_speed NOTIFY speed_changed)
    void set_speed(int speed);

    Q_PROPERTY(int airspeed MEMBER m_airspeed WRITE set_airspeed NOTIFY airspeed_changed)
    void set_airspeed(int airspeed);

    Q_PROPERTY(bool armed MEMBER m_armed WRITE set_armed NOTIFY armed_changed)
    void set_armed(bool armed);

    Q_PROPERTY(QString flight_mode MEMBER m_flight_mode WRITE set_flight_mode NOTIFY flight_mode_changed)
    void set_flight_mode(QString flight_mode);

    Q_PROPERTY(double homelat MEMBER m_homelat WRITE set_homelat NOTIFY homelat_changed)
    void set_homelat(double homelat);

    Q_PROPERTY(double homelon MEMBER m_homelon WRITE set_homelon NOTIFY homelon_changed)
    void set_homelon(double homelon);

    Q_PROPERTY(double lat MEMBER m_lat WRITE set_lat NOTIFY lat_changed)
    void set_lat(double lat);

    Q_PROPERTY(double lon MEMBER m_lon WRITE set_lon NOTIFY lon_changed)
    void set_lon(double lon);

    Q_PROPERTY(int satellites_visible MEMBER m_satellites_visible WRITE set_satellites_visible NOTIFY satellites_visible_changed)
    void set_satellites_visible(int satellites_visible);

    Q_PROPERTY(double gps_hdop MEMBER m_gps_hdop WRITE set_gps_hdop NOTIFY gps_hdop_changed)
    void set_gps_hdop(double gps_hdop);

    Q_PROPERTY(int battery_percent MEMBER m_battery_percent WRITE set_battery_percent NOTIFY battery_percent_changed)
    void set_battery_percent(int battery_percent);

    Q_PROPERTY(double battery_voltage MEMBER m_battery_voltage WRITE set_battery_voltage NOTIFY battery_voltage_changed)
    void set_battery_voltage(double battery_voltage);

    Q_PROPERTY(double battery_current MEMBER m_battery_current WRITE set_battery_current NOTIFY battery_current_changed)
    void set_battery_current(double battery_current);

    Q_PROPERTY(QString battery_gauge MEMBER m_battery_gauge WRITE set_battery_gauge NOTIFY battery_gauge_changed)
    void set_battery_gauge(QString battery_gauge);

    Q_PROPERTY(float pitch MEMBER m_pitch WRITE set_pitch NOTIFY pitch_changed)
    void set_pitch(float pitch);

    Q_PROPERTY(float roll MEMBER m_roll WRITE set_roll NOTIFY roll_changed)
    void set_roll(float roll);

    Q_PROPERTY(float yaw MEMBER m_yaw WRITE set_yaw NOTIFY pitch_changed)
    void set_yaw(float yaw);


    Q_PROPERTY(double throttle MEMBER m_throttle WRITE set_throttle NOTIFY throttle_changed)
    void set_throttle(double throttle);


    // openhd

    Q_PROPERTY(int downlink_rssi MEMBER m_downlink_rssi WRITE set_downlink_rssi NOTIFY downlink_rssi_changed)
    void set_downlink_rssi(int downlink_rssi);

    Q_PROPERTY(int current_signal_joystick_uplink MEMBER m_current_signal_joystick_uplink WRITE set_current_signal_joystick_uplink NOTIFY current_signal_joystick_uplink_changed)
    void set_current_signal_joystick_uplink(int current_signal_joystick_uplink);

    Q_PROPERTY(unsigned int lost_packet_cnt_rc MEMBER m_lost_packet_cnt_rc WRITE set_lost_packet_cnt_rc NOTIFY lost_packet_cnt_rc_changed)
    void set_lost_packet_cnt_rc(unsigned int lost_packet_cnt_rc);

    Q_PROPERTY(unsigned int lost_packet_cnt_telemetry_up MEMBER m_lost_packet_cnt_telemetry_up WRITE set_lost_packet_cnt_telemetry_up NOTIFY lost_packet_cnt_telemetry_up_changed)
    void set_lost_packet_cnt_telemetry_up(unsigned int lost_packet_cnt);



    Q_PROPERTY(unsigned int skipped_packet_cnt MEMBER m_skipped_packet_cnt WRITE set_skipped_packet_cnt NOTIFY skipped_packet_cnt_changed)
    void set_skipped_packet_cnt(unsigned int skipped_packet_cnt);

    Q_PROPERTY(unsigned int injection_fail_cnt MEMBER m_injection_fail_cnt WRITE set_injection_fail_cnt NOTIFY injection_fail_cnt_changed)
    void set_injection_fail_cnt(unsigned int injection_fail_cnt);



    Q_PROPERTY(double kbitrate MEMBER m_kbitrate WRITE set_kbitrate NOTIFY kbitrate_changed)
    void set_kbitrate(double kbitrate);

    Q_PROPERTY(double kbitrate_set MEMBER m_kbitrate_set WRITE set_kbitrate_set NOTIFY kbitrate_set_changed)
    void set_kbitrate_set(double kbitrate_set);

    Q_PROPERTY(double kbitrate_measured MEMBER m_kbitrate_measured WRITE set_kbitrate_measured NOTIFY kbitrate_measured_changed)
    void set_kbitrate_measured(double kbitrate_measured);

    Q_PROPERTY(int cpuload_gnd MEMBER m_cpuload_gnd WRITE set_cpuload_gnd NOTIFY cpuload_gnd_changed)
    void set_cpuload_gnd(int cpuload_gnd);

    Q_PROPERTY(int cpuload_air MEMBER m_cpuload_air WRITE set_cpuload_air NOTIFY cpuload_air_changed)
    void set_cpuload_air(int cpuload_air);

    Q_PROPERTY(int temp_gnd MEMBER m_temp_gnd WRITE set_temp_gnd NOTIFY temp_gnd_changed)
    void set_temp_gnd(int temp_gnd);

    Q_PROPERTY(int temp_air MEMBER m_temp_air WRITE set_temp_air NOTIFY temp_air_changed)
    void set_temp_air(int temp_air);

    Q_PROPERTY(unsigned int damaged_block_cnt MEMBER m_damaged_block_cnt WRITE set_damaged_block_cnt NOTIFY damaged_block_cnt_changed)
    void set_damaged_block_cnt(unsigned int damaged_block_cnt);

    Q_PROPERTY(int damaged_block_percent MEMBER m_damaged_block_percent WRITE set_damaged_block_percent NOTIFY damaged_block_percent_changed)
    void set_damaged_block_percent(int damaged_block_percent);

    Q_PROPERTY(unsigned int lost_packet_cnt MEMBER m_lost_packet_cnt WRITE set_lost_packet_cnt NOTIFY lost_packet_cnt_changed)
    void set_lost_packet_cnt(unsigned int lost_packet_cnt);

    Q_PROPERTY(int lost_packet_percent MEMBER m_lost_packet_percent WRITE set_lost_packet_percent NOTIFY lost_packet_percent_changed)
    void set_lost_packet_percent(int lost_packet_percent);

    Q_PROPERTY(bool air_undervolt MEMBER m_air_undervolt WRITE set_air_undervolt NOTIFY air_undervolt_changed)
    void set_air_undervolt(bool air_undervolt);


    Q_PROPERTY(bool cts MEMBER m_cts WRITE set_cts NOTIFY cts_changed)
    void set_cts(bool cts);


    Q_PROPERTY(QString flight_time MEMBER m_flight_time WRITE set_flight_time NOTIFY flight_time_changed)
    void set_flight_time(QString flight_time);

    Q_PROPERTY(double flight_distance MEMBER m_flight_distance WRITE set_flight_distance NOTIFY flight_distance_changed)
    void set_flight_distance(double flight_distance);

    Q_PROPERTY(double flight_mah MEMBER m_flight_mah WRITE set_flight_mah NOTIFY flight_mah_changed)
    void set_flight_mah(double flight_mah);

    Q_PROPERTY(qint64 last_openhd_heartbeat MEMBER m_last_openhd_heartbeat WRITE set_last_openhd_heartbeat NOTIFY last_openhd_heartbeat_changed)
    void set_last_openhd_heartbeat(qint64 last_openhd_heartbeat);

    Q_PROPERTY(qint64 last_telemetry_heartbeat MEMBER m_last_telemetry_heartbeat WRITE set_last_telemetry_heartbeat NOTIFY last_telemetry_heartbeat_changed)
    void set_last_telemetry_heartbeat(qint64 last_telemetry_heartbeat);


    Q_PROPERTY(bool main_video_running MEMBER m_main_video_running WRITE set_main_video_running NOTIFY main_video_running_changed)
    void set_main_video_running(bool main_video_running);

    Q_PROPERTY(bool lte_video_running MEMBER m_lte_video_running WRITE set_lte_video_running NOTIFY lte_video_running_changed)
    void set_lte_video_running(bool lte_video_running);


    Q_PROPERTY(bool pip_video_running MEMBER m_pip_video_running WRITE set_pip_video_running NOTIFY pip_video_running_changed)
    void set_pip_video_running(bool pip_video_running);


    Q_PROPERTY(QList<int> ground_gpio MEMBER m_ground_gpio WRITE set_ground_gpio NOTIFY ground_gpio_changed)
    void set_ground_gpio(QList<int> ground_gpio);

    Q_PROPERTY(bool ground_gpio_busy MEMBER m_ground_gpio_busy WRITE set_ground_gpio_busy NOTIFY ground_gpio_busy_changed)
    void set_ground_gpio_busy(bool ground_gpio_busy);

    Q_PROPERTY(QList<int> air_gpio MEMBER m_air_gpio WRITE set_air_gpio NOTIFY air_gpio_changed)
    void set_air_gpio(QList<int> air_gpio);

    Q_PROPERTY(bool air_gpio_busy MEMBER m_air_gpio_busy WRITE set_air_gpio_busy NOTIFY air_gpio_busy_changed)
    void set_air_gpio_busy(bool air_gpio_busy);

    Q_PROPERTY(QVariantMap wifi_adapter0 MEMBER m_wifi_adapter0 NOTIFY wifi_adapter0_changed)
    Q_PROPERTY(QVariantMap wifi_adapter1 MEMBER m_wifi_adapter1 NOTIFY wifi_adapter1_changed)
    Q_PROPERTY(QVariantMap wifi_adapter2 MEMBER m_wifi_adapter2 NOTIFY wifi_adapter2_changed)
    Q_PROPERTY(QVariantMap wifi_adapter3 MEMBER m_wifi_adapter3 NOTIFY wifi_adapter3_changed)
    Q_PROPERTY(QVariantMap wifi_adapter4 MEMBER m_wifi_adapter4 NOTIFY wifi_adapter4_changed)
    Q_PROPERTY(QVariantMap wifi_adapter5 MEMBER m_wifi_adapter5 NOTIFY wifi_adapter5_changed)

    Q_PROPERTY(double ground_vin MEMBER m_ground_vin WRITE set_ground_vin NOTIFY ground_vin_changed)
    void set_ground_vin(double ground_vin);

    Q_PROPERTY(double ground_vout MEMBER m_ground_vout WRITE set_ground_vout NOTIFY ground_vout_changed)
    void set_ground_vout(double ground_vout);

    Q_PROPERTY(double ground_vbat MEMBER m_ground_vbat WRITE set_ground_vbat NOTIFY ground_vbat_changed)
    void set_ground_vbat(double ground_vbat);

    Q_PROPERTY(double ground_iout MEMBER m_ground_iout WRITE set_ground_iout NOTIFY ground_iout_changed)
    void set_ground_iout(double ground_iout);

signals:
    // system
    void gstreamer_version_changed();
    void qt_version_changed();

    void save_ground_gpio(QList<int> ground_gpio);
    void save_air_gpio(QList<int> air_gpio);

    void ground_gpio_busy_changed(bool ground_gpio_busy);
    void air_gpio_busy_changed(bool air_gpio_busy);

    void wifi_adapter0_changed(QVariantMap wifi_adapter);
    void wifi_adapter1_changed(QVariantMap wifi_adapter);
    void wifi_adapter2_changed(QVariantMap wifi_adapter);
    void wifi_adapter3_changed(QVariantMap wifi_adapter);
    void wifi_adapter4_changed(QVariantMap wifi_adapter);
    void wifi_adapter5_changed(QVariantMap wifi_adapter);

    // mavlink
    void boot_time_changed(int boot_time);
    void alt_rel_changed(int alt_rel);
    void alt_msl_changed(int alt_msl);
    void vx_changed(int vx);
    void vy_changed(int vy);
    void vz_changed(int vz);
    void hdg_changed(double hdg);
    void speed_changed(int speed);
    void airspeed_changed(int airspeed);
    void armed_changed(bool armed);
    void flight_mode_changed(QString flight_mode);
    void homelat_changed(double homelat);
    void homelon_changed(double homelon);
    void lat_changed(double lat);
    void lon_changed(double lon);
    void home_distance_changed(double home_distance);
    void home_course_changed(double home_course);
    void battery_percent_changed(int battery_percent);
    void battery_voltage_changed(double battery_voltage);
    void battery_current_changed(double battery_current);
    void battery_gauge_changed(QString battery_gauge);
    void satellites_visible_changed(int satellites_visible);
    void gps_hdop_changed(double gps_hdop);
    void pitch_changed(float pitch);
    void roll_changed(float roll);
    void yaw_changed(float yaw);
    void messageReceived(QString message, int level);

    void throttle_changed(double throttle);


    // openhd
    void downlink_rssi_changed(int downlink_rssi);
    void current_signal_joystick_uplink_changed(int current_signal_joystick_uplink);
    void lost_packet_cnt_rc_changed(unsigned int lost_packet_cnt_rc);
    void lost_packet_cnt_telemetry_up_changed(unsigned int lost_packet_cnt_telemetry_up);

    void skipped_packet_cnt_changed(unsigned int skipped_packet_cnt);
    void injection_fail_cnt_changed(unsigned int injection_fail_cnt);

    void kbitrate_changed(double kbitrate);
    void kbitrate_set_changed(double kbitrate_set);
    void kbitrate_measured_changed(double kbitrate_measured);
    void cpuload_gnd_changed(int cpuload_gnd);
    void temp_gnd_changed(int temp_gnd);
    void cpuload_air_changed(int cpuload_air);
    void temp_air_changed(int temp_air);
    void damaged_block_cnt_changed(unsigned int damaged_block_cnt);
    void damaged_block_percent_changed(int damaged_block_percent);
    void lost_packet_cnt_changed(unsigned int lost_packet_cnt);
    void lost_packet_percent_changed(int lost_packet_percent);
    void air_undervolt_changed(bool air_undervolt);
    void cts_changed(bool cts);

    void flight_time_changed(QString flight_time);

    void flight_distance_changed(double flight_distance);

    void flight_mah_changed(int flight_mah);

    void last_openhd_heartbeat_changed(qint64 last_openhd_heartbeat);

    void last_telemetry_heartbeat_changed(qint64 last_telemetry_heartbeat);

    void main_video_running_changed(bool main_video_running);
    void pip_video_running_changed(bool pip_video_running);

    void lte_video_running_changed(bool lte_video_running);

    void ground_gpio_changed(QList<int> ground_gpio);
    void air_gpio_changed(QList<int> air_gpio);

    void air_reboot();
    void air_shutdown();
    void ground_reboot();
    void ground_shutdown();

    void ground_vin_changed(double ground_vin);
    void ground_vout_changed(double ground_vout);
    void ground_vbat_changed(double ground_vbat);
    void ground_iout_changed(double ground_iout);

private:
#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif


    // mavlink
    int m_boot_time = 0;

    int m_alt_rel = 0;
    int m_alt_msl = 0;

    int m_vx = 0;
    int m_vy = 0;
    int m_vz = 0;

    double m_hdg = 000.0;

    int m_speed = 0;
    int m_airspeed = 0;

    bool m_armed = false;
    QString m_flight_mode = "Stabilize";
    double m_homelat = 0.0;
    double m_homelon = 0.0;
    double m_lat = 0.0;
    double m_lon = 0.0;
    double m_home_distance = 0.0;
    double m_home_course = 0.0;
    int m_battery_percent = 0;
    double m_battery_current = 0.0;
    double m_battery_voltage = 0.0;
    QString m_battery_gauge = "\uf091";
    int m_satellites_visible = 0;
    double m_gps_hdop = 99.00;

    float m_roll = 0.0;
    float m_yaw = 0.0;
    float m_pitch = 0.0;

    // openhd

    int m_downlink_rssi = -127;
    int m_current_signal_joystick_uplink = -127;
    unsigned int m_lost_packet_cnt_rc = 0;
    unsigned int m_lost_packet_cnt_telemetry_up = 0;

    unsigned int m_skipped_packet_cnt = 0;
    unsigned int m_injection_fail_cnt = 0;

    double m_kbitrate = 0.0;
    double m_kbitrate_measured = 0.0;
    double m_kbitrate_set = 0.0;

    int m_cpuload_gnd = 0;

    int m_temp_gnd = 0;

    int m_cpuload_air = 0;

    int m_temp_air = 0;

    unsigned int m_damaged_block_cnt = 0;
    int m_damaged_block_percent = 0;

    unsigned int m_lost_packet_cnt = 0;
    int m_lost_packet_percent = 0;

    bool m_air_undervolt = false;
    bool m_cts = false;

    double m_throttle = 0;

    QString m_flight_time = "00:00";

    double m_flight_distance = 0.0;
    qint64 flightDistanceLastTime= 0;
    long total_dist= 0;

    int m_flight_mah = 0;
    qint64 flightMahLastTime= 0;
    double total_mah= 0;

    qint64 m_last_openhd_heartbeat = -1;
    qint64 m_last_telemetry_heartbeat = -1;

    bool m_main_video_running = false;
    bool m_pip_video_running = false;
    bool m_lte_video_running = false;

    QVariantMap m_wifi_adapter0;
    QVariantMap m_wifi_adapter1;
    QVariantMap m_wifi_adapter2;
    QVariantMap m_wifi_adapter3;
    QVariantMap m_wifi_adapter4;
    QVariantMap m_wifi_adapter5;

    QTime flightTimeStart;

    QList<int> m_ground_gpio;
    QList<int> m_air_gpio;

    bool m_ground_gpio_busy = false;
    bool m_air_gpio_busy = false;

    QTimer* timer = nullptr;

    double m_ground_vin = 0.0;
    double m_ground_vout = 0.0;
    double m_ground_vbat = 0.0;
    double m_ground_iout = 0.0;
};



#endif // OPENHD_H
