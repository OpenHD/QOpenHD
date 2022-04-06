#ifndef GPIOMICROSERVICE_H
#define GPIOMICROSERVICE_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "../app/telemetry/mavlinkbase.h"


class QUdpSocket;


class GPIOMicroservice: public MavlinkBase {
    Q_OBJECT

public:
    explicit GPIOMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);
    static GPIOMicroservice* instance();

public slots:
    void onSetup();
    void onSaveGPIO(QList<int> gpio);

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

    void onCommandDone();
    void onCommandFailed();

private:
    MicroserviceTarget m_target;
};

#endif
