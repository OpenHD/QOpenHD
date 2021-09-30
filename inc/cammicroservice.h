#ifndef CAMMICROSERVICE_H
#define CAMMICROSERVICE_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"


class QUdpSocket;


class CamMicroservice: public MavlinkBase {
    Q_OBJECT

public:
    explicit CamMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);
    static CamMicroservice* instance();

public slots:
    void onSetup();
    void onSaveCamBright(int bright);

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

    void onCommandDone();
    void onCommandFailed();

private:
    MicroserviceTarget m_target;
};

#endif
