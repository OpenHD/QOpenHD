#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>
#include <array>

#include "mavlink_include.h"

#include "../util/util.h"
#include "OHDConnection.h"
#include "mavlinkcommand.h"


class MavlinkTelemetry : public QObject{
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry* instance();

// Stuff that used to be in mavlink base ---------------- begin
private:
    void sendCommand(MavlinkCommand command);
    bool isConnectionLost();
    OpenHDUtil m_util;
    quint8 targetSysID;
    quint8 targetCompID;
    uint64_t m_last_boot = 0;
    qint64 m_last_heartbeat = -1;
    qint64 m_last_attitude = -1;
    qint64 m_last_battery = -1;
    qint64 m_last_gps = -1;
    qint64 m_last_vfr = -1;
    qint64 last_heartbeat_timestamp = 0;
    qint64 last_battery_timestamp = 0;
    qint64 last_gps_timestamp = 0;
    qint64 last_vfr_timestamp = 0;
    qint64 last_attitude_timestamp = 0;
public:
    void sendRC();
    void setDataStreamRate(MAV_DATA_STREAM streamType, uint8_t hz);
    void requestAutopilotInfo();
    Q_INVOKABLE void get_Mission_Items(int count);
    Q_INVOKABLE void send_Mission_Ack();
    //
    Q_PROPERTY(qint64 last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(qint64 last_heartbeat);
    Q_PROPERTY(qint64 last_attitude MEMBER m_last_attitude WRITE set_last_attitude NOTIFY last_attitude_changed)
    void set_last_attitude(qint64 last_attitude);
    Q_PROPERTY(qint64 last_battery MEMBER m_last_battery WRITE set_last_battery NOTIFY last_battery_changed)
    void set_last_battery(qint64 last_battery);
    Q_PROPERTY(qint64 last_gps MEMBER m_last_gps WRITE set_last_gps NOTIFY last_gps_changed)
    void set_last_gps(qint64 last_gps);
    Q_PROPERTY(qint64 last_vfr MEMBER m_last_vfr WRITE set_last_vfr NOTIFY last_vfr_changed)
    void set_last_vfr(qint64 last_vfr);
signals:
    void last_heartbeat_changed(qint64 last_heartbeat);
    void last_attitude_changed(qint64 last_attitude);
    void last_battery_changed(qint64 last_battery);
    void last_gps_changed(qint64 last_gps);
    void last_vfr_changed(qint64 last_vfr);
// Stuff that used to be in mavlink base ---------------- end
public slots:
    void pauseTelemetry(bool toggle);
    void requested_Flight_Mode_Changed(int mode);
    void requested_ArmDisarm_Changed(int arm_disarm);
    void FC_Reboot_Shutdown_Changed(int reboot_shutdown);
    // channelIdx: value between 0 and ??
    void rc_value_changed(int channelIdx,uint channelValue);
    void request_Mission_Changed();
private:
    void onProcessMavlinkMessage(mavlink_message_t msg);

signals:
    void update_RC_MavlinkBase(std::array<uint,19> rcValues);
private:
    bool pause_telemetry=false;
    int m_mode=0;
    int m_arm_disarm=99;
    int m_reboot_shutdown=99;
    int m_total_waypoints=0;
    bool sent_autopilot_request=false;
    int ap_version=0;

    std::array<uint,19> m_rc_values{0};
    int pingSequenceNumber=0;
public:
     Q_INVOKABLE void pingAllSystems();
     Q_INVOKABLE void requestAllParameters();
    // one shot, result not quaranteed
    Q_INVOKABLE void request_openhd_version(){
        mOHDConnection->request_openhd_version();
    }
public:
    std::unique_ptr<OHDConnection> mOHDConnection;
    void sendData(mavlink_message_t msg);
};

#endif
