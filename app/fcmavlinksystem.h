#ifndef FC_MAVLINK_SYSTEM_H
#define FC_MAVLINK_SYSTEM_H

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/action/action.h>
#include <mavsdk/plugins/telemetry/telemetry.h>

/**
 * This used to be called OpenHD and was a mix of everything, it has become FCMavlinkSystem -
 * A QT model for (fire and forget) data from the mavlink FC connected to the air unit.
 * OpenHD only ever has one connected FC, so this can be a singleton, too.
 * Also, note that nothing OpenHD specific should ever make it into here - OpenHD supports raw access to
 * the Flight Controller, but it is NOT a Flight Controller ;)
 * The corresponding qml element is called _fcMavlinkSystem.
 */
class FCMavlinkSystem : public QObject
{
    Q_OBJECT

public:
    explicit FCMavlinkSystem(QObject *parent = nullptr);
    static FCMavlinkSystem& instance();

    void telemetryMessage(QString message, int level);
    void calculate_home_distance();
    void calculate_home_course();

    Q_INVOKABLE void set_Requested_Flight_Mode(int mode);

    Q_INVOKABLE void set_Requested_ArmDisarm(int mode);

    Q_INVOKABLE void set_FC_Reboot_Shutdown(int reboot_shutdown);

    Q_INVOKABLE void request_Mission();

    //void setEngine(QQmlApplicationEngine *engine);
    //Q_INVOKABLE void switchToLanguage(const QString &language);

    /* public so that a QTimer can call it from main(), temporary fix due to some quirks with
       the way QTimer and QML singletons/context properties work */
    void updateFlightTimer();

    void findGcsPosition();
    void updateFlightDistance();
    void updateAppMah();
    void updateAppMahKm();
    void updateVehicleAngles();
    void updateWind();

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

    Q_PROPERTY(int satellites_visible MEMBER m_satellites_visible WRITE set_satellites_visible NOTIFY satellites_visible_changed)
    void set_satellites_visible(int satellites_visible);

    Q_PROPERTY(double gps_hdop MEMBER m_gps_hdop WRITE set_gps_hdop NOTIFY gps_hdop_changed)
    void set_gps_hdop(double gps_hdop);

    Q_PROPERTY(unsigned int gps_fix_type MEMBER m_gps_fix_type WRITE set_gps_fix_type NOTIFY gps_fix_type_changed)
    void set_gps_fix_type(unsigned int gps_fix_type);

    Q_PROPERTY(int fc_battery_percent MEMBER m_fc_battery_percent WRITE set_fc_battery_percent NOTIFY fc_battery_percent_changed)
    void set_fc_battery_percent(int fc_battery_percent);

    Q_PROPERTY(double battery_voltage MEMBER m_battery_voltage WRITE set_battery_voltage NOTIFY battery_voltage_changed)
    void set_battery_voltage(double battery_voltage);

    Q_PROPERTY(double battery_current MEMBER m_battery_current WRITE set_battery_current NOTIFY battery_current_changed)
    void set_battery_current(double battery_current);

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

    Q_PROPERTY(double vehicle_vx_angle MEMBER m_vehicle_vx_angle WRITE set_vehicle_vx_angle NOTIFY vehicle_vx_angle_changed)
    void set_vehicle_vx_angle(double vehicle_vx_angle);

    Q_PROPERTY(double vehicle_vz_angle MEMBER m_vehicle_vz_angle WRITE set_vehicle_vz_angle NOTIFY vehicle_vz_angle_changed)
    void set_vehicle_vz_angle(double vehicle_vz_angle);

    Q_PROPERTY(int current_waypoint MEMBER m_current_waypoint WRITE setCurrentWaypoint NOTIFY currentWaypointChanged)
    void setCurrentWaypoint(int current_waypoint);

    Q_PROPERTY(int total_waypoints MEMBER m_total_waypoints WRITE setTotalWaypoints NOTIFY totalWaypointsChanged)
    void setTotalWaypoints(int total_waypoints);

    Q_PROPERTY(QString last_ping_result_flight_ctrl MEMBER  m_last_ping_result_flight_ctrl WRITE set_last_ping_result_flight_ctrl NOTIFY last_ping_result_flight_ctrl_changed)
    void set_last_ping_result_flight_ctrl(QString last_ping_result_flight_ctrl);
signals:
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
    void fc_battery_percent_changed(int fc_battery_percent);
    void battery_voltage_changed(double battery_voltage);
    void battery_current_changed(double battery_current);
    void battery_gauge_changed(QString battery_gauge);
    void fc_battery_gauge_changed(QString fc_battery_gauge);
    void satellites_visible_changed(int satellites_visible);
    void gps_hdop_changed(double gps_hdop);
    void gps_fix_type_changed(unsigned int gps_fix_type);
    void pitch_changed(double pitch);
    void roll_changed(double roll);
    void yaw_changed(double yaw);
    void messageReceived(QString message, int level);

    void throttle_changed(double throttle);

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

    void kbitrate_changed(double kbitrate);
    void kbitrate_set_changed(double kbitrate_set);
    void kbitrate_measured_changed(double kbitrate_measured);
    void damaged_block_cnt_changed(unsigned int damaged_block_cnt);
    void damaged_block_percent_changed(int damaged_block_percent);
    void lost_packet_cnt_changed(unsigned int lost_packet_cnt);
    void lost_packet_percent_changed(int lost_packet_percent);
    void cts_changed(bool cts);

    void flight_time_changed(QString flight_time);

    void flight_distance_changed(double flight_distance);

    void flight_mah_changed(int flight_mah);
    void app_mah_changed(int app_mah);
    void mah_km_changed(int mah_km);

    //void last_FCMavlinkSystem_heartbeat_changed(qint64 last_FCMavlinkSystem_heartbeat);

    void last_telemetry_heartbeat_changed(qint64 last_telemetry_heartbeat);
    void last_telemetry_attitude_changed(qint64 last_telemetry_attitude);
    void last_telemetry_battery_changed(qint64 last_telemetry_battery);
    void last_telemetry_gps_changed(qint64 last_telemetry_gps);
    void last_telemetry_vfr_changed(qint64 last_telemetry_vfr);

    void vehicle_vx_angle_changed(double vehicle_vx_angle);
    void vehicle_vz_angle_changed(double vehicle_vz_angle);

    void rcChannelChanged(int channelIdx,int value);

    void currentWaypointChanged (int current_waypoint);
    void totalWaypointsChanged (int total_waypoints);

    void last_ping_result_flight_ctrl_changed(QString last_ping_result_flight_ctrl);

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
    //QString m_mav_type = "UNKOWN";
    QString m_mav_type = "ARDUPLANE";

    double m_homelat = 0.0;
    double m_homelon = 0.0;
    bool gcs_position_set = false;
    int gps_quality_count = 0;

    double m_lat = 0.0;
    double m_lon = 0.0;
    double m_home_distance = 0.0;
    int m_home_heading = 0; //this is actual global heading
    int m_home_course = 0; //this is the relative course from nose

    int m_battery_percent = 20; //TODO debug, set back to 0
    int m_fc_battery_percent = 0;
    double m_battery_current = 0.0;
    double m_battery_voltage = 0.0;
    QString m_battery_gauge = "\uf091";
    QString m_fc_battery_gauge = "\uf091";

    int m_satellites_visible = 0;
    double m_gps_hdop = 99.00;
    unsigned int m_gps_fix_type = (unsigned int)0;

    double m_roll = 0.0;
    double m_yaw = 0.0;
    double m_pitch = 0.0;

    double m_throttle = 0;

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

    double m_kbitrate = 0.0;
    double m_kbitrate_measured = 0.0;
    double m_kbitrate_set = 0.0;

    int m_imu_temp = 0;
    int m_press_temp = 0;
    int m_esc_temp = 0;

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

    qint64 m_last_telemetry_heartbeat = -1;
    qint64 m_last_telemetry_attitude = -1;
    qint64 m_last_telemetry_battery = -1;
    qint64 m_last_telemetry_gps = -1;
    qint64 m_last_telemetry_vfr = -1;

    QElapsedTimer totalTime;
    QElapsedTimer flightTimeStart;

    QTimer* timer = nullptr;

    double m_vehicle_vx_angle = 0.0;
    double m_vehicle_vz_angle = 0.0;

    int m_current_waypoint = 0;
    int m_total_waypoints = 0;

    int m_mode = 0;

    int m_arm_disarm = 99;

    int m_reboot_shutdown=99;
    QString m_last_ping_result_flight_ctrl="NA";
private:
    // NOTE: Null until system discovered
    std::shared_ptr<mavsdk::System> _system;
    std::shared_ptr<mavsdk::Action> _action;
    std::shared_ptr<mavsdk::Telemetry> _mavsdk_telemetry;
public:
    // Set the mavlink system reference, once discovered
    void set_system(std::shared_ptr<mavsdk::System> system);
    //
    Q_INVOKABLE bool set_flight_mode(int mode);
    Q_INVOKABLE bool arm_fc(bool disarm=false);
    Q_INVOKABLE bool send_command_reboot(bool reboot);
};



#endif // FC_MAVLINK_SYSTEM_H
