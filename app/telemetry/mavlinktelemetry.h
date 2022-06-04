#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>
#include <array>

#include <openhd/mavlink.h>

#include "../util/util.h"

#include "mavlinkbase.h"


class QUdpSocket;



class MavlinkTelemetry: public MavlinkBase {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry* instance();

public slots:
    void onSetup();
    void pauseTelemetry(bool toggle);
    void requestSysIdSettings();
    void requested_Flight_Mode_Changed(int mode);
    void requested_ArmDisarm_Changed(int arm_disarm);
    void FC_Reboot_Shutdown_Changed(int reboot_shutdown);

    // channelIdx: value between 0 and 17
    void rc_value_changed(int channelIdx,uint channelValue);

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

signals:
    //void adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo);
    //void deleteMissionWaypoints();

    void update_RC_MavlinkBase(std::array<uint,19> rcValues);

private:
    bool pause_telemetry;
    int m_mode=0;
    int m_arm_disarm=99;
    int m_reboot_shutdown=99;
    int m_total_waypoints=0;
    bool sent_autopilot_request=false;
    int ap_version=0;

    std::array<uint,19> m_rc_values{0};
};

#endif
