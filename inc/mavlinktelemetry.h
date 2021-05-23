#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"
#include "ADSBVehicle.h"


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

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

signals:
    void adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo);

private:
    bool pause_telemetry;

    int m_mode=0;

    int m_arm_disarm=99;

    int m_reboot_shutdown=99;
};

#endif
