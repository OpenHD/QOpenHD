#ifndef OPENHDTELEMETRY_H
#define OPENHDTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "wifibroadcast.h"
#include "constants.h"

class QUdpSocket;

class OpenHDTelemetry: public QObject {
    Q_OBJECT

public:
    explicit OpenHDTelemetry(QObject *parent = nullptr);

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

    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);


    Q_PROPERTY(bool air_undervolt MEMBER m_air_undervolt WRITE set_air_undervolt NOTIFY air_undervolt_changed)
    void set_air_undervolt(bool air_undervolt);


    Q_PROPERTY(bool cts MEMBER m_cts WRITE set_cts NOTIFY cts_changed)
    void set_cts(bool cts);

signals:
    void boot_time_changed(QString boot_time);

    void alt_rel_changed(QString alt_rel);
    void alt_msl_changed(QString alt_msl);

    void vx_changed(QString vx);
    void vy_changed(QString vy);
    void vz_changed(QString vz);

    void hdg_changed(QString hdg);

    void armed_changed(bool armed);
    void flight_mode_changed(QString flight_mode);

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

    void homelat_changed(QString homelat);
    void homelon_changed(QString homelon);

    void battery_voltage_changed(QString battery_voltage);
    void battery_voltage_raw_changed(double battery_voltage);

    void battery_current_changed(QString battery_current);
    void battery_gauge_changed(QString battery_gauge);

    void satellites_visible_changed(QString satellites_visible);

    void last_heartbeat_changed(QString last_heartbeat);


    void air_undervolt_changed(bool air_undervolt);
    void cts_changed(bool cts);

private slots:
#if defined(__rasp_pi__)
    void processSHM();
    void restartSHM();
#else
    void processDatagrams();
#endif
    void processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry);
private:
    void init();
#if defined(__rasp_pi__)
    QFuture<void> shmFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *telemetrySocket = nullptr;
#endif
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


    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;
#if defined(__rasp_pi__)
    wifibroadcast_rx_status_t *rx_status = nullptr;
    wifibroadcast_rx_status_t_osd *rx_status_osd = nullptr;
    wifibroadcast_rx_status_t_rc *rx_status_rc = nullptr;
    wifibroadcast_rx_status_t_uplink *rx_status_uplink = nullptr;
    wifibroadcast_rx_status_t_sysair *rx_status_sysair = nullptr;
#endif
};

QObject *openHDTelemetrySingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
