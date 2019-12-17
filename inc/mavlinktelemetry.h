#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <common/mavlink.h>
#include <ardupilotmega/ardupilotmega.h>
#include "constants.h"


class QUdpSocket;

class MavlinkTelemetry: public QObject {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

    Q_INVOKABLE void setGroundIP(QString address);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
#if defined(__rasp_pi__)
    void processMavlinkFifo();
    void restartFifo();
#else
    void processMavlinkDatagrams();
#endif
    void processMavlinkMessage(mavlink_message_t msg);

private:
    void init();
    void stateLoop();

    QString groundAddress;

#if defined(__rasp_pi__)
    QFuture<void> fifoFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *mavlinkSocket = nullptr;
#endif
    mavlink_status_t r_mavlink_status;

    QString m_last_heartbeat = "N/A";
    qint64 m_last_heartbeat_raw = -1;

    qint64 last_heartbeat_timestamp;

};

#endif
