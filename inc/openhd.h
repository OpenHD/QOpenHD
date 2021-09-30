#ifndef OPENHD_H
#define OPENHD_H

#include <QObject>
#include <QtQuick>

#include "blackboxmodel.h"

#if defined(ENABLE_SPEECH)
#include <QtTextToSpeech/QTextToSpeech>
#endif

class OpenHD : public QObject
{
    Q_OBJECT

public:
    explicit OpenHD(QObject *parent = nullptr);
    static OpenHD* instance();

    void telemetryMessage(QString message, int level);
    void calculate_home_distance();
    void calculate_home_course();

    Q_INVOKABLE void pauseBlackBox(bool pause, int index);
    void updateBlackBoxModel();

    Q_INVOKABLE void set_Requested_Flight_Mode(int mode);

    Q_INVOKABLE void set_Requested_ArmDisarm(int mode);

    Q_INVOKABLE void set_FC_Reboot_Shutdown(int reboot_shutdown);

    Q_INVOKABLE void request_Mission();

    void setWifiAdapter0(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);
    void setWifiAdapter1(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);
    void setWifiAdapter2(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);
    void setWifiAdapter3(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);
    void setWifiAdapter4(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);
    void setWifiAdapter5(uint32_t received_packet_cnt, int8_t current_signal_dbm, int8_t signal_good);

    void setEngine(QQmlApplicationEngine *engine);

    Q_INVOKABLE void switchToLanguage(const QString &language);

    Q_INVOKABLE void setGroundGPIO(int pin, bool state) {
        m_ground_gpio[pin] = state ? 1 : 0;
        emit save_ground_gpio(m_ground_gpio);
    }

    Q_INVOKABLE void setAirGPIO(int pin, bool state) {
        m_air_gpio[pin] = state ? 1 : 0;
        emit save_air_gpio(m_air_gpio);
    }

    Q_INVOKABLE void setAirFREQ(int air_freq) {
        qDebug() << "OPENHD setAirFREQ =" <<  air_freq;
        m_air_freq = air_freq;
        emit save_air_freq(m_air_freq);
    }
    Q_INVOKABLE void setGndFREQ(int gnd_freq) {
        m_gnd_freq = gnd_freq;
        emit save_gnd_freq(m_gnd_freq);
    }

    Q_INVOKABLE void setCamBright(int cam_bright) {
        qDebug() << "OPENHD setCamBright =" <<  cam_bright;
        m_cam_bright = cam_bright;
        emit save_cam_bright(m_cam_bright);
    }

    /* public so that a QTimer can call it from main(), temporary fix due to some quirks with
       the way QTimer and QML singletons/context properties work */
    void updateFlightTimer();

    void findGcsPosition();
    void updateFlightDistance();
    void updateAppMah();
    void updateAppMahKm();
    void updateVehicleAngles();
    void updateWind();

    Q_PROPERTY(QString gstreamer_version READ get_gstreamer_version NOTIFY gstreamer_version_changed)
    QString get_gstreamer_version();

    Q_PROPERTY(QString qt_version READ get_qt_version NOTIFY qt_version_changed)
    QString get_qt_version();


    Q_PROPERTY(double home_distance MEMBER m_home_distance WRITE set_home_distance NOTIFY home_distance_changed)
    void set_home_distance(double home_distance);

    Q_PROPERTY(int home_course MEMBER m_home_course WRITE set_home_course NOTIFY home_course_changed)
    void set_home_course(int home_course);

    Q_PROPERTY(int home_heading MEMBER m_home_heading WRITE set_home_heading NOTIFY home_heading_changed)
    void set_home_heading(int home_heading);

    Q_PROPERTY(int boot_time MEMBER m_boot_time WRITE set_boot_time NOTIFY boot_time_changed)
    void set_boot_time(int boot_time);

    Q_PROPERTY(double alt_rel MEMBER m_alt_rel WRITE set_alt_rel NOTIFY alt_rel_changed)
    void set_alt_rel(double alt_rel);

    Q_PROPERTY(double alt_msl MEMBER m_alt_msl WRITE set_alt_msl NOTIFY alt_msl_changed)
    void set_alt_msl(double alt_msl);

    Q_PROPERTY(double vx MEMBER m_vx WRITE set_vx NOTIFY vx_changed)
    void set_vx(double vx);

    Q_PROPERTY(double vy MEMBER m_vy WRITE set_vy NOTIFY vy_changed)
    void set_vy(double vy);

    Q_PROPERTY(double vz MEMBER m_vz WRITE set_vz NOTIFY vz_changed)
    void set_vz(double vz);

    Q_PROPERTY(int hdg MEMBER m_hdg WRITE set_hdg NOTIFY hdg_changed)
    void set_hdg(int hdg);

    Q_PROPERTY(double speed MEMBER m_speed WRITE set_speed NOTIFY speed_changed)
    void set_speed(double speed);

    Q_PROPERTY(double airspeed MEMBER m_airspeed WRITE set_airspeed NOTIFY airspeed_changed)
    void set_airspeed(double airspeed);

    Q_PROPERTY(bool armed MEMBER m_armed WRITE set_armed NOTIFY armed_changed)
    void set_armed(bool armed);

    Q_PROPERTY(QString flight_mode MEMBER m_flight_mode WRITE set_flight_mode NOTIFY flight_mode_changed)
    void set_flight_mode(QString flight_mode);

    Q_PROPERTY(QString mav_type MEMBER m_mav_type WRITE set_mav_type NOTIFY mav_type_changed)
    void set_mav_type(QString mav_type);

    Q_PROPERTY(double homelat MEMBER m_homelat WRITE set_homelat NOTIFY homelat_changed)
    void set_homelat(double homelat);

    Q_PROPERTY(double homelon MEMBER m_homelon WRITE set_homelon NOTIFY homelon_changed)
    void set_homelon(double homelon);

    Q_PROPERTY(double lat MEMBER m_lat WRITE set_lat NOTIFY lat_changed)
    void set_lat(double lat);

    Q_PROPERTY(double lon MEMBER m_lon WRITE set_lon NOTIFY lon_changed)
    void set_lon(double lon);

    double get_lat() {
        return m_lat;
    };
    
    double get_lon() { 
        return m_lon;
    };

    double get_home_lat() {
        return m_homelat;
    };

    double get_home_lon() {
        return m_homelon;
    };


    double get_msl_alt() {
        return m_alt_msl;
    }

    double get_hdg() {
        return m_hdg;
    }

    Q_PROPERTY(int satellites_visible MEMBER m_satellites_visible WRITE set_satellites_visible NOTIFY satellites_visible_changed)
    void set_satellites_visible(int satellites_visible);

    Q_PROPERTY(double gps_hdop MEMBER m_gps_hdop WRITE set_gps_hdop NOTIFY gps_hdop_changed)
    void set_gps_hdop(double gps_hdop);

    Q_PROPERTY(unsigned int gps_fix_type MEMBER m_gps_fix_type WRITE set_gps_fix_type NOTIFY gps_fix_type_changed)
    void set_gps_fix_type(unsigned int gps_fix_type);

    Q_PROPERTY(int battery_percent MEMBER m_battery_percent WRITE set_battery_percent NOTIFY battery_percent_changed)
    void set_battery_percent(int battery_percent);

    Q_PROPERTY(int ground_battery_percent MEMBER m_ground_battery_percent WRITE set_ground_battery_percent NOTIFY ground_battery_percent_changed)
    void set_ground_battery_percent(int ground_battery_percent);

    Q_PROPERTY(int fc_battery_percent MEMBER m_fc_battery_percent WRITE set_fc_battery_percent NOTIFY fc_battery_percent_changed)
    void set_fc_battery_percent(int fc_battery_percent);

    Q_PROPERTY(double battery_voltage MEMBER m_battery_voltage WRITE set_battery_voltage NOTIFY battery_voltage_changed)
    void set_battery_voltage(double battery_voltage);

    Q_PROPERTY(double battery_current MEMBER m_battery_current WRITE set_battery_current NOTIFY battery_current_changed)
    void set_battery_current(double battery_current);

    Q_PROPERTY(QString battery_gauge MEMBER m_battery_gauge WRITE set_battery_gauge NOTIFY battery_gauge_changed)
    void set_battery_gauge(QString battery_gauge);

    Q_PROPERTY(QString ground_battery_gauge MEMBER m_ground_battery_gauge WRITE set_ground_battery_gauge NOTIFY ground_battery_gauge_changed)
    void set_ground_battery_gauge(QString ground_battery_gauge);

    Q_PROPERTY(QString fc_battery_gauge MEMBER m_fc_battery_gauge WRITE set_fc_battery_gauge NOTIFY fc_battery_gauge_changed)
    void set_fc_battery_gauge(QString fc_battery_gauge);

    Q_PROPERTY(double pitch MEMBER m_pitch WRITE set_pitch NOTIFY pitch_changed)
    void set_pitch(double pitch);

    Q_PROPERTY(double roll MEMBER m_roll WRITE set_roll NOTIFY roll_changed)
    void set_roll(double roll);

    Q_PROPERTY(double yaw MEMBER m_yaw WRITE set_yaw NOTIFY pitch_changed)
    void set_yaw(double yaw);

    Q_PROPERTY(double throttle MEMBER m_throttle WRITE set_throttle NOTIFY throttle_changed)
    void set_throttle(double throttle);

    Q_PROPERTY(int control_pitch MEMBER m_control_pitch WRITE set_control_pitch NOTIFY control_pitch_changed)
    void set_control_pitch(int control_pitch);

    Q_PROPERTY(int control_roll MEMBER m_control_roll WRITE set_control_roll NOTIFY control_roll_changed)
    void set_control_roll(int control_roll);

    Q_PROPERTY(int control_yaw MEMBER m_control_yaw WRITE set_control_yaw NOTIFY control_yaw_changed)
    void set_control_yaw(int control_yaw);

    Q_PROPERTY(int control_throttle MEMBER m_control_throttle WRITE set_control_throttle NOTIFY control_throttle_changed)
    void set_control_throttle(int control_throttle);

    Q_PROPERTY(float vibration_x MEMBER m_vibration_x WRITE set_vibration_x NOTIFY vibration_x_changed)
    void set_vibration_x(float vibration_x);

    Q_PROPERTY(float vibration_y MEMBER m_vibration_y WRITE set_vibration_y NOTIFY vibration_y_changed)
    void set_vibration_y(float vibration_y);

    Q_PROPERTY(float vibration_z MEMBER m_vibration_z WRITE set_vibration_z NOTIFY vibration_z_changed)
    void set_vibration_z(float vibration_z);

    Q_PROPERTY(float clipping_x MEMBER m_clipping_x WRITE set_clipping_x NOTIFY clipping_x_changed)
    void set_clipping_x(float clipping_x);

    Q_PROPERTY(float clipping_y MEMBER m_clipping_y WRITE set_clipping_y NOTIFY clipping_y_changed)
    void set_clipping_y(float clipping_y);

    Q_PROPERTY(float clipping_z MEMBER m_clipping_z WRITE set_clipping_z NOTIFY clipping_z_changed)
    void set_clipping_z(float clipping_z);

    Q_PROPERTY(float vsi MEMBER m_vsi WRITE set_vsi NOTIFY vsi_changed)
    void set_vsi(float vsi);

    Q_PROPERTY(double lateral_speed MEMBER m_lateral_speed WRITE set_lateral_speed NOTIFY lateral_speed_changed)
    void set_lateral_speed(double lateral_speed);

    Q_PROPERTY(double wind_speed MEMBER m_wind_speed WRITE set_wind_speed NOTIFY wind_speed_changed)
    void set_wind_speed(double wind_speed);

    Q_PROPERTY(double wind_direction MEMBER m_wind_direction WRITE set_wind_direction NOTIFY wind_direction_changed)
    void set_wind_direction(double wind_direction);

    Q_PROPERTY(float mav_wind_direction MEMBER m_mav_wind_direction WRITE set_mav_wind_direction NOTIFY mav_wind_direction_changed)
    void set_mav_wind_direction(float mav_wind_direction);

    Q_PROPERTY(float mav_wind_speed MEMBER m_mav_wind_speed WRITE set_mav_wind_speed NOTIFY mav_wind_speed_changed)
    void set_mav_wind_speed(float mav_wind_speed);

    Q_PROPERTY(int rcRssi MEMBER m_rcRssi WRITE setRcRssi NOTIFY rcRssiChanged)
    void setRcRssi(int rcRssi);

    Q_PROPERTY(int imu_temp MEMBER m_imu_temp WRITE set_imu_temp NOTIFY imu_temp_changed)
    void set_imu_temp(int imu_temp);

    Q_PROPERTY(int press_temp MEMBER m_press_temp WRITE set_press_temp NOTIFY press_temp_changed)
    void set_press_temp(int press_temp);

    Q_PROPERTY(int esc_temp MEMBER m_esc_temp WRITE set_esc_temp NOTIFY esc_temp_changed)
    void set_esc_temp(int esc_temp);

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    void setFontFamily(QString fontFamily);

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

    Q_PROPERTY(double app_mah MEMBER m_app_mah WRITE set_app_mah NOTIFY app_mah_changed)
    void set_app_mah(double app_mah);

    Q_PROPERTY(int mah_km MEMBER m_mah_km WRITE set_mah_km NOTIFY mah_km_changed)
    void set_mah_km(int mah_km);

    Q_PROPERTY(qint64 last_openhd_heartbeat MEMBER m_last_openhd_heartbeat WRITE set_last_openhd_heartbeat NOTIFY last_openhd_heartbeat_changed)
    void set_last_openhd_heartbeat(qint64 last_openhd_heartbeat);

    Q_PROPERTY(qint64 last_telemetry_heartbeat MEMBER m_last_telemetry_heartbeat WRITE set_last_telemetry_heartbeat NOTIFY last_telemetry_heartbeat_changed)
    void set_last_telemetry_heartbeat(qint64 last_telemetry_heartbeat);

    Q_PROPERTY(qint64 last_telemetry_attitude MEMBER m_last_telemetry_attitude WRITE set_last_telemetry_attitude NOTIFY last_telemetry_attitude_changed)
    void set_last_telemetry_attitude(qint64 last_telemetry_attitude);

    Q_PROPERTY(qint64 last_telemetry_battery MEMBER m_last_telemetry_battery WRITE set_last_telemetry_battery NOTIFY last_telemetry_battery_changed)
    void set_last_telemetry_battery(qint64 last_telemetry_battery);

    Q_PROPERTY(qint64 last_telemetry_gps MEMBER m_last_telemetry_gps WRITE set_last_telemetry_gps NOTIFY last_telemetry_gps_changed)
    void set_last_telemetry_gps(qint64 last_telemetry_gps);

    Q_PROPERTY(qint64 last_telemetry_vfr MEMBER m_last_telemetry_vfr WRITE set_last_telemetry_vfr NOTIFY last_telemetry_vfr_changed)
    void set_last_telemetry_vfr(qint64 last_telemetry_vfr);


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

    Q_PROPERTY(int air_freq MEMBER m_air_freq WRITE set_air_freq NOTIFY air_freq_changed)
    void set_air_freq(int air_freq);

    Q_PROPERTY(int gnd_freq MEMBER m_gnd_freq WRITE set_gnd_freq NOTIFY gnd_freq_changed)
    void set_gnd_freq(int gnd_freq);

    Q_PROPERTY(bool air_freq_busy MEMBER m_air_freq_busy WRITE set_air_freq_busy NOTIFY air_freq_busy_changed)
    void set_air_freq_busy(bool air_freq_busy);

    Q_PROPERTY(bool gnd_freq_busy MEMBER m_gnd_freq_busy WRITE set_gnd_freq_busy NOTIFY gnd_freq_busy_changed)
    void set_gnd_freq_busy(bool gnd_freq_busy);

    Q_PROPERTY(int cam_bright MEMBER m_cam_bright WRITE set_cam_bright NOTIFY cam_bright_changed)
    void set_cam_bright(int cam_bright);

    Q_PROPERTY(bool cam_busy MEMBER m_cam_busy WRITE set_cam_busy NOTIFY cam_busy_changed)
    void set_cam_busy(bool cam_busy);

    Q_PROPERTY(double ground_vin MEMBER m_ground_vin WRITE set_ground_vin NOTIFY ground_vin_changed)
    void set_ground_vin(double ground_vin);

    Q_PROPERTY(double ground_vout MEMBER m_ground_vout WRITE set_ground_vout NOTIFY ground_vout_changed)
    void set_ground_vout(double ground_vout);

    Q_PROPERTY(double ground_vbat MEMBER m_ground_vbat WRITE set_ground_vbat NOTIFY ground_vbat_changed)
    void set_ground_vbat(double ground_vbat);

    Q_PROPERTY(double ground_iout MEMBER m_ground_iout WRITE set_ground_iout NOTIFY ground_iout_changed)
    void set_ground_iout(double ground_iout);



    Q_PROPERTY(double air_vout MEMBER m_air_vout WRITE set_air_vout NOTIFY air_vout_changed)
    void set_air_vout(double air_vout);

    Q_PROPERTY(double air_iout MEMBER m_air_iout WRITE set_air_iout NOTIFY air_iout_changed)
    void set_air_iout(double air_iout);

    Q_PROPERTY(double vehicle_vx_angle MEMBER m_vehicle_vx_angle WRITE set_vehicle_vx_angle NOTIFY vehicle_vx_angle_changed)
    void set_vehicle_vx_angle(double vehicle_vx_angle);

    Q_PROPERTY(double vehicle_vz_angle MEMBER m_vehicle_vz_angle WRITE set_vehicle_vz_angle NOTIFY vehicle_vz_angle_changed)
    void set_vehicle_vz_angle(double vehicle_vz_angle);


    Q_PROPERTY(int rcChannel1 MEMBER mRCChannel1 WRITE setRCChannel1 NOTIFY rcChannel1Changed)
    void setRCChannel1(int rcChannel1);

    Q_PROPERTY(int rcChannel2 MEMBER mRCChannel2 WRITE setRCChannel2 NOTIFY rcChannel2Changed)
    void setRCChannel2(int rcChannel2);

    Q_PROPERTY(int rcChannel3 MEMBER mRCChannel3 WRITE setRCChannel3 NOTIFY rcChannel3Changed)
    void setRCChannel3(int rcChannel3);

    Q_PROPERTY(int rcChannel4 MEMBER mRCChannel4 WRITE setRCChannel4 NOTIFY rcChannel4Changed)
    void setRCChannel4(int rcChannel4);

    Q_PROPERTY(int rcChannel5 MEMBER mRCChannel5 WRITE setRCChannel5 NOTIFY rcChannel5Changed)
    void setRCChannel5(int rcChannel5);

    Q_PROPERTY(int rcChannel6 MEMBER mRCChannel6 WRITE setRCChannel6 NOTIFY rcChannel6Changed)
    void setRCChannel6(int rcChannel6);

    Q_PROPERTY(int rcChannel7 MEMBER mRCChannel7 WRITE setRCChannel7 NOTIFY rcChannel7Changed)
    void setRCChannel7(int rcChannel7);

    Q_PROPERTY(int rcChannel8 MEMBER mRCChannel8 WRITE setRCChannel8 NOTIFY rcChannel8Changed)
    void setRCChannel8(int rcChannel8);

    Q_PROPERTY(int current_waypoint MEMBER m_current_waypoint WRITE setCurrentWaypoint NOTIFY currentWaypointChanged)
    void setCurrentWaypoint(int current_waypoint);

    Q_PROPERTY(int total_waypoints MEMBER m_total_waypoints WRITE setTotalWaypoints NOTIFY totalWaypointsChanged)
    void setTotalWaypoints(int total_waypoints);

signals:
    // system
    void gstreamer_version_changed();
    void qt_version_changed();

    void save_ground_gpio(QList<int> ground_gpio);
    void save_air_gpio(QList<int> air_gpio);

    void ground_gpio_busy_changed(bool ground_gpio_busy);
    void air_gpio_busy_changed(bool air_gpio_busy);

    void save_air_freq(int air_freq);
    void save_gnd_freq(int gnd_freq);

    void air_freq_busy_changed(bool air_freq_busy);
    void gnd_freq_busy_changed(bool gnd_freq_busy);

    void save_cam_bright(int cam_bright);
    void cam_busy_changed(bool cam_busy);

    void wifiAdapter0Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);
    void wifiAdapter1Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);
    void wifiAdapter2Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);
    void wifiAdapter3Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);
    void wifiAdapter4Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);
    void wifiAdapter5Changed(unsigned int received_packet_cnt, int current_signal_dbm, int signal_good);


    // mavlink
    void boot_time_changed(int boot_time);
    void alt_rel_changed(double alt_rel);
    void alt_msl_changed(double alt_msl);
    void vx_changed(double vx);
    void vy_changed(double vy);
    void vz_changed(double vz);
    void hdg_changed(int hdg);
    void speed_changed(double speed);
    void airspeed_changed(double airspeed);
    void armed_changed(bool armed);
    void flight_mode_changed(QString flight_mode);
    void mav_type_changed(QString mav_type);
    void homelat_changed(double homelat);
    void homelon_changed(double homelon);
    void lat_changed(double lat);
    void lon_changed(double lon);
    void home_distance_changed(double home_distance);
    void home_course_changed(int home_course);
    void home_heading_changed(int home_heading);
    void battery_percent_changed(int battery_percent);
    void ground_battery_percent_changed(int ground_battery_percent);
    void fc_battery_percent_changed(int fc_battery_percent);
    void battery_voltage_changed(double battery_voltage);
    void battery_current_changed(double battery_current);
    void battery_gauge_changed(QString battery_gauge);
    void ground_battery_gauge_changed(QString ground_battery_gauge);
    void fc_battery_gauge_changed(QString fc_battery_gauge);
    void satellites_visible_changed(int satellites_visible);
    void gps_hdop_changed(double gps_hdop);
    void gps_fix_type_changed(unsigned int gps_fix_type);
    void pitch_changed(double pitch);
    void roll_changed(double roll);
    void yaw_changed(double yaw);
    void messageReceived(QString message, int level);

    void throttle_changed(double throttle);

    void control_pitch_changed(int control_pitch);
    void control_roll_changed(int control_roll);
    void control_yaw_changed(int control_yaw);
    void control_throttle_changed(int control_throttle);

    void vibration_x_changed(float vibration_x);
    void vibration_y_changed(float vibration_y);
    void vibration_z_changed(float vibration_z);

    void clipping_x_changed(float clipping_x);
    void clipping_y_changed(float clipping_y);
    void clipping_z_changed(float clipping_z);

    void vsi_changed(float vsi);

    void lateral_speed_changed(double lateral_speed);

    void wind_speed_changed(double wind_speed);
    void wind_direction_changed(double wind_direction);

    void mav_wind_direction_changed(float mav_wind_direction);
    void mav_wind_speed_changed(float mav_wind_speed);

    void rcRssiChanged(int rcRssi);

    void imu_temp_changed (int imu_temp);
    void press_temp_changed (int press_temp);
    void esc_temp_changed (int esc_temp);

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
    void app_mah_changed(int app_mah);
    void mah_km_changed(int mah_km);

    void last_openhd_heartbeat_changed(qint64 last_openhd_heartbeat);

    void last_telemetry_heartbeat_changed(qint64 last_telemetry_heartbeat);
    void last_telemetry_attitude_changed(qint64 last_telemetry_attitude);
    void last_telemetry_battery_changed(qint64 last_telemetry_battery);
    void last_telemetry_gps_changed(qint64 last_telemetry_gps);
    void last_telemetry_vfr_changed(qint64 last_telemetry_vfr);

    void main_video_running_changed(bool main_video_running);
    void pip_video_running_changed(bool pip_video_running);

    void lte_video_running_changed(bool lte_video_running);

    void ground_gpio_changed(QList<int> ground_gpio);
    void air_gpio_changed(QList<int> air_gpio);

    void air_freq_changed(int air_freq);
    void gnd_freq_changed(int gnd_freq);

    void cam_bright_changed(int cam_bright);

    void air_reboot();
    void air_shutdown();
    void ground_reboot();
    void ground_shutdown();

    void ground_vin_changed(double ground_vin);
    void ground_vout_changed(double ground_vout);
    void ground_vbat_changed(double ground_vbat);
    void ground_iout_changed(double ground_iout);

    void air_vout_changed(double air_vout);
    void air_iout_changed(double air_iout);

    void vehicle_vx_angle_changed(double vehicle_vx_angle);
    void vehicle_vz_angle_changed(double vehicle_vz_angle);

    void rcChannel1Changed(int rcChanne1);
    void rcChannel2Changed(int rcChanne2);
    void rcChannel3Changed(int rcChanne3);
    void rcChannel4Changed(int rcChanne4);
    void rcChannel5Changed(int rcChanne5);
    void rcChannel6Changed(int rcChanne6);
    void rcChannel7Changed(int rcChanne7);
    void rcChannel8Changed(int rcChanne8);

    void currentWaypointChanged (int current_waypoint);
    void totalWaypointsChanged (int total_waypoints);

    void addBlackBoxObject(const BlackBox &blackbox);
    void pauseTelemetry(bool pause);
    void requested_Flight_Mode_Changed(int mode);
    void requested_ArmDisarm_Changed(int arm_disarm);
    void FC_Reboot_Shutdown_Changed(int reboot_shutdown);
    void request_Mission_Changed();
    void playBlackBoxObject(int index);

    void fontFamilyChanged(QString fontFamily);

private:
#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif
    QString m_fontFamily;

    QFont m_font;

public:
    // mavlink
    int m_boot_time = 0;

    double m_alt_rel = 0;
    double m_alt_msl = 0;

    double m_vx = 0;
    double m_vy = 0;
    double m_vz = 0;

    int m_hdg = 000;

    double m_speed = 0;
    double m_airspeed = 0;

    bool m_armed = false;
    QString m_flight_mode = "------";
    QString m_mav_type = "UNKOWN";

    double m_homelat = 0.0;
    double m_homelon = 0.0;
    bool gcs_position_set = false;
    int gps_quality_count = 0;

    double m_lat = 0.0;
    double m_lon = 0.0;
    double m_home_distance = 0.0;
    int m_home_heading = 0; //this is actual global heading
    int m_home_course = 0; //this is the relative course from nose

    int m_battery_percent = 0;
    int m_ground_battery_percent = 0;
    int m_fc_battery_percent = 0;
    double m_battery_current = 0.0;
    double m_battery_voltage = 0.0;
    QString m_battery_gauge = "\uf091";
    QString m_ground_battery_gauge = "\uf091";
    QString m_fc_battery_gauge = "\uf091";

    int m_satellites_visible = 0;
    double m_gps_hdop = 99.00;
    unsigned int m_gps_fix_type = (unsigned int)GPS_FIX_TYPE_NO_GPS;

    double m_roll = 0.0;
    double m_yaw = 0.0;
    double m_pitch = 0.0;

    double m_throttle = 0;

    int m_control_pitch = 0;
    int m_control_roll = 0;
    int m_control_yaw = 0;
    int m_control_throttle = 0;

    float m_vibration_x = 0.0;
    float m_vibration_y = 0.0;
    float m_vibration_z = 0.0;

    float m_clipping_x = 0.0;
    float m_clipping_y = 0.0;
    float m_clipping_z = 0.0;

    float m_vsi = 0.0;

    double m_lateral_speed = 0.0;

    double m_wind_direction = 0.0;
    double m_wind_speed = 0.0;
    double speed_last_time = 0.0;

    float m_mav_wind_direction = 0.0;
    float m_mav_wind_speed = 0.0;

    int m_rcRssi = 0;

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

    int m_imu_temp = 0;
    int m_press_temp = 0;
    int m_esc_temp = 0;

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



    QString m_flight_time = "00:00";

    double m_flight_distance = 0.0;
    qint64 flightDistanceLastTime= 0;
    long total_dist= 0;

    int m_flight_mah = 0;
    int m_app_mah = 0;
    int m_mah_km = 0;
    qint64 mahLastTime= 0;
    qint64 mahKmLastTime= 0;
    double total_mah= 0;

    qint64 m_last_openhd_heartbeat = -1;
    qint64 m_last_telemetry_heartbeat = -1;
    qint64 m_last_telemetry_attitude = -1;
    qint64 m_last_telemetry_battery = -1;
    qint64 m_last_telemetry_gps = -1;
    qint64 m_last_telemetry_vfr = -1;

    bool m_main_video_running = false;
    bool m_pip_video_running = false;
    bool m_lte_video_running = false;

    QElapsedTimer totalTime;
    QElapsedTimer flightTimeStart;

    QList<int> m_ground_gpio;
    QList<int> m_air_gpio;

    bool m_ground_gpio_busy = false;
    bool m_air_gpio_busy = false;

    int m_air_freq;
    int m_gnd_freq;

    bool m_air_freq_busy = false;
    bool m_gnd_freq_busy = false;

    int m_cam_bright;
    bool m_cam_busy = false;

    QTimer* timer = nullptr;

    double m_ground_vin = -1;
    double m_ground_vout = -1;
    double m_ground_vbat = -1;
    double m_ground_iout = -1;

    double m_air_vout = -1;
    double m_air_iout = -1;

    double m_vehicle_vx_angle = 0.0;
    double m_vehicle_vz_angle = 0.0;

    int mRCChannel1 = 0;
    int mRCChannel2 = 0;
    int mRCChannel3 = 0;
    int mRCChannel4 = 0;
    int mRCChannel5 = 0;
    int mRCChannel6 = 0;
    int mRCChannel7 = 0;
    int mRCChannel8 = 0;

    int m_current_waypoint = 0;
    int m_total_waypoints = 0;

    bool m_pause_blackbox = false;

    QTranslator m_translator;

    QQmlApplicationEngine *m_engine = nullptr;

    int m_mode = 0;

    int m_arm_disarm = 99;

    int m_reboot_shutdown=99;
};



#endif // OPENHD_H
