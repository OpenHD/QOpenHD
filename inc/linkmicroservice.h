#ifndef LINKMICROSERVICE_H
#define LINKMICROSERVICE_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"


class QUdpSocket;


class LinkMicroservice: public MavlinkBase {
    Q_OBJECT

public:
    explicit LinkMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);
    static LinkMicroservice* instance();

public slots:
    void onSetup();
    void onSaveFreq(int freq);

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

    void onCommandDone();
    void onCommandFailed();

private:
    MicroserviceTarget m_target;
};

#endif
