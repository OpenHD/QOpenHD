#ifndef STATUSMICROSERVICE_H
#define STATUSMICROSERVICE_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "../../inc/telemetry/mavlinkbase.h"

#include "../../inc/telemetry/statuslogmodel.h"

class QUdpSocket;

class StatusMicroservice : public MavlinkBase {
    Q_OBJECT

public:
    explicit StatusMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);

    Q_PROPERTY(QString openHDVersion MEMBER m_openHDVersion WRITE setOpenHDVersion NOTIFY openHDVersionChanged)
    void setOpenHDVersion(QString openHDVersion);


signals:
    void statusMessage(int sysid, QString message, int level, unsigned long long timestamp);

    void openHDVersionChanged(QString openHDVersion);

public slots:
    void onSetup();

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

private:
    MicroserviceTarget m_target;

    uint64_t m_last_timestamp = 0;

    QString m_openHDVersion = "Checking...";
};

#endif // STATUSMICROSERVICE_H
