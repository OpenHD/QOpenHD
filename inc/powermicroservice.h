#ifndef POWERMICROSERVICE_H
#define POWERMICROSERVICE_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"

class QUdpSocket;

class PowerMicroservice : public MavlinkBase {
    Q_OBJECT

public:
    explicit PowerMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);

public slots:
    void onSetup();
    void onShutdown();
    void onReboot();

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

private:
    MicroserviceTarget m_target;

    QString m_battery_percent = "0%";
    QString m_battery_gauge = "\uf091";

    float m_vin_raw  = -1; // Unit: V,   example: 11.54
    float m_vout_raw = -1; // Unit: V,   example: 5.02
    float m_iout_raw = -1; // Unit: A,   example: 1.3
    float m_vbat_raw = -1; // Unit: V,   example: 3.45

    bool m_vbat_is_lifepo4 = false;
};

#endif // POWERMICROSERVICE_H
