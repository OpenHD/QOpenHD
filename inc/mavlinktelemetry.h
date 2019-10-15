#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>
#if defined(ENABLE_SPEECH)
#include <QtTextToSpeech/QTextToSpeech>
#endif

#include <common/mavlink.h>
#include <ardupilotmega/ardupilotmega.h>
#include "constants.h"


class QUdpSocket;

class MavlinkTelemetry: public QObject {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);

    Q_PROPERTY(QString boot_time MEMBER m_boot_time WRITE set_boot_time NOTIFY boot_time_changed)
    void set_boot_time(QString boot_time);

    Q_PROPERTY(QString alt_rel MEMBER m_alt_rel WRITE set_alt_rel NOTIFY alt_rel_changed)
    void set_alt_rel(QString alt_rel);

    Q_PROPERTY(QString alt_msl MEMBER m_alt_msl WRITE set_alt_msl NOTIFY alt_msl_changed)
    void set_alt_msl(QString alt_msl);

    Q_PROPERTY(QString vx MEMBER m_vx WRITE set_vx NOTIFY vx_changed)
    void set_vx(QString vx);

    Q_PROPERTY(QString vy MEMBER m_vy WRITE set_vy NOTIFY vy_changed)
    void set_vy(QString vy);

    Q_PROPERTY(QString vz MEMBER m_vz WRITE set_vz NOTIFY vz_changed)
    void set_vz(QString vz);

    Q_PROPERTY(QString hdg MEMBER m_hdg WRITE set_hdg NOTIFY hdg_changed)
    void set_hdg(QString hdg);

    Q_PROPERTY(bool armed MEMBER m_armed WRITE set_armed NOTIFY armed_changed)
    void set_armed(bool armed);

    Q_PROPERTY(QString flight_mode MEMBER m_flight_mode WRITE set_flight_mode NOTIFY flight_mode_changed)
    void set_flight_mode(QString flight_mode);

    Q_PROPERTY(QString homelat MEMBER m_homelat WRITE set_homelat NOTIFY homelat_changed)
    void set_homelat(QString homelat);

    Q_PROPERTY(QString homelon MEMBER m_homelon WRITE set_homelon NOTIFY homelon_changed)
    void set_homelon(QString homelon);

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

    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void mavlink_msg_received(mavlink_message_t msg);

    void boot_time_changed(QString boot_time);

    void alt_rel_changed(QString alt_rel);
    void alt_msl_changed(QString alt_msl);

    void vx_changed(QString vx);
    void vy_changed(QString vy);
    void vz_changed(QString vz);

    void hdg_changed(QString hdg);

    void armed_changed(bool armed);
    void flight_mode_changed(QString flight_mode);
    void homelat_changed(QString homelat);
    void homelon_changed(QString homelon);
    void battery_percent_changed(QString battery_percent);
    void battery_voltage_changed(QString battery_voltage);
    void battery_voltage_raw_changed(double battery_voltage);
    void battery_current_changed(QString battery_current);
    void battery_gauge_changed(QString battery_gauge);
    void satellites_visible_changed(QString satellites_visible);
    void gps_hdop_changed(QString gps_hdop);

    void last_heartbeat_changed(QString last_heartbeat);

    void messageReceived(QString message, int level);

private slots:
#if defined(__rasp_pi__)
    void processMavlinkFifo();
    void restartFifo();
#else
    void processMavlinkDatagrams();
#endif
    void processMavlinkMessage(mavlink_message_t msg);

private:
    void init();
#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif

#if defined(__rasp_pi__)
    QFuture<void> fifoFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *mavlinkSocket = nullptr;
#endif
    mavlink_status_t r_mavlink_status;

    QString m_boot_time = "0";

    QString m_alt_rel = "0";
    QString m_alt_msl = "0";

    QString m_vx = "0";
    QString m_vy = "0";
    QString m_vz = "0";

    QString m_hdg = "360";

    bool m_armed = false;
    QString m_flight_mode = "Stabilize";
    QString m_homelat = "0.000000";
    QString m_homelon = "0.000000";
    QString m_battery_percent = "0%";
    QString m_battery_current = "0.0a";
    QString m_battery_voltage = "0.0v";
    double m_battery_voltage_raw = 0.0;
    QString m_battery_gauge = "\uf091";
    QString m_satellites_visible = "0";
    QString m_gps_hdop = "0.00";

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;
};


QObject *mavlinkTelemetrySingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

#endif
