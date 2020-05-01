#ifndef STATUSMICROSERVICE_H
#define STATUSMICROSERVICE_H

#include <QObject>
#include <QtQuick>
#include <QProcess>
#include <QProcessEnvironment>

#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"

class QUdpSocket;

// matches struct defined in OpenHDMicroservice::StatusMicroservice
struct StatusMessage {
    QString message;
    int sysid;
    int compid;
    MAV_SEVERITY severity;
    uint64_t timestamp;
};


class StatusMicroservice : public MavlinkBase {
    Q_OBJECT

public:
    explicit StatusMicroservice(QObject *parent = nullptr, MicroserviceTarget target = MicroserviceTargetNone, MavlinkType mavlink_type = MavlinkTypeUDP);

    Q_INVOKABLE QList<StatusMessage> getAllMessages();

    Q_INVOKABLE void resetMessages();

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

    QList<StatusMessage> m_messages;

    QString m_openHDVersion = "N/A";
};

#endif // STATUSRMICROSERVICE_H
