#ifndef MAVLINKBASE_H
#define MAVLINKBASE_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"


class QUdpSocket;

typedef enum MavlinkType {
    MavlinkTypeUDP,
    MavlinkTypeTCP
} MavlinkType;

typedef enum MicroserviceTarget {
    MicroserviceTargetGround,
    MicroserviceTargetAir,
    MicroserviceTargetNone
} MicroserviceTarget;

typedef enum MavlinkState {
    MavlinkStateDisconnected,
    MavlinkStateConnected,
    MavlinkStateGetParameters,
    MavlinkStateIdle
} MavlinkState;

class MavlinkBase: public QObject {
    Q_OBJECT

public:
    explicit MavlinkBase(QObject *parent = nullptr, MavlinkType mavlink_type = MavlinkTypeUDP);


    Q_INVOKABLE QVariantMap getAllParameters();

    Q_PROPERTY(bool loading MEMBER m_loading WRITE set_loading NOTIFY loadingChanged)
    void set_loading(bool loading);

    Q_PROPERTY(bool saving MEMBER m_saving WRITE set_saving NOTIFY savingChanged)
    void set_saving(bool saving);

    Q_INVOKABLE void fetchParameters();


    Q_PROPERTY(qint64 last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(qint64 last_heartbeat);

    Q_INVOKABLE void setGroundIP(QString address);

signals:
    void last_heartbeat_changed(qint64 last_heartbeat);
    void setup();
    void processMavlinkMessage(mavlink_message_t msg);

    void allParametersChanged();

    void loadingChanged(bool loading);
    void savingChanged(bool saving);

public slots:
    void onStarted();

protected slots:
    void processMavlinkUDPDatagrams();
    void processMavlinkTCPData();

    void onTCPDisconnected();
    void onTCPConnected();


protected:
    void stateLoop();
    bool isConnectionLost();
    void resetParamVars();
    void processData(QByteArray data);
    void sendData(char* data, int len);

    void reconnectTCP();

    QVariantMap m_allParameters;

    MavlinkState state = MavlinkStateDisconnected;

    uint16_t parameterCount = 0;
    uint16_t parameterIndex = 0;

    qint64 parameterLastReceivedTime;

    qint64 initialConnectTimer;

    bool m_loading = false;
    bool m_saving = false;

protected:
    quint8 targetSysID;
    quint8 targetCompID;
    quint16 localPort = 14550;

    QString groundAddress = "192.168.2.1";
    quint16 groundUDPPort = 14550;
    quint16 groundTCPPort = 5761;

    std::atomic<bool> m_ground_available;
    MavlinkType m_mavlink_type;
    QAbstractSocket *mavlinkSocket = nullptr;

    mavlink_status_t r_mavlink_status;

    qint64 m_last_heartbeat = -1;

    qint64 last_heartbeat_timestamp = 0;

    QTimer* timer = nullptr;
    QTimer* tcpReconnectTimer = nullptr;
};

#endif
