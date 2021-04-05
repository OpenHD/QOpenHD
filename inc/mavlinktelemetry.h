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

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

signals:
    void adsbVehicleUpdate(const ADSBVehicle::VehicleInfo_t vehicleInfo);

private:
    bool pause_telemetry;

    int m_mode=0;
};

#endif
