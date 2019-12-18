#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <common/mavlink.h>
#include <ardupilotmega/ardupilotmega.h>
#include "constants.h"

#include "util.h"


class QUdpSocket;


typedef enum MavlinkState {
    MavlinkStateDisconnected,
    MavlinkStateConnected,
    MavlinkStateGetParameters,
    MavlinkStateIdle
} MavlinkState;


class MavlinkTelemetry: public QObject {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap getAllParameters();

    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

    Q_INVOKABLE void setGroundIP(QString address);

    Q_INVOKABLE void fetchParameters();

signals:
    void last_heartbeat_changed(QString last_heartbeat);
    void allParametersChanged();


private slots:
    void processMavlinkDatagrams();

    void processMavlinkMessage(mavlink_message_t msg);

private:
    void init();
    void stateLoop();
    bool isConnectionLost();
    void resetParamVars();

    QString groundAddress;
    quint16 groundPort = 14550;

    QVariantMap m_allParameters;

    MavlinkState state = MavlinkStateDisconnected;

    std::atomic<bool> m_ground_available;
    uint16_t parameterCount = 0;
    uint16_t parameterIndex = 0;

    qint64 parameterLastReceivedTime;

    qint64 initialConnectTimer;

    QUdpSocket *mavlinkSocket = nullptr;

    mavlink_status_t r_mavlink_status;

    QString m_last_heartbeat = "N/A";
    qint64 m_last_heartbeat_raw = -1;

    qint64 last_heartbeat_timestamp;

    QMutex stateLock;

};

#endif
