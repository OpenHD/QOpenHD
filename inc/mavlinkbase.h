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

typedef enum MavlinkCommandState {
    MavlinkCommandStateReady,
    MavlinkCommandStateSend,
    MavlinkCommandStateWaitACK,
    MavlinkCommandStateDone,
    MavlinkCommandStateFailed
} MavlinkCommandState;

class MavlinkCommand  {
public:
    bool is_long_cmd = false;
    uint16_t command_id = 0;
    uint8_t retry_count = 0;
};

class LongMavlinkCommand: public MavlinkCommand  {
public:
    uint8_t confirmation = 0;
    float param1 = 0;
    float param2 = 0;
    float param3 = 0;
    float param4 = 0;
    float param5 = 0;
    float param6 = 0;
    float param7 = 0;
};

class IntMavlinkCommand: public MavlinkCommand  {
public:
    uint8_t frame = 0;
    uint8_t current = 0;
    uint8_t autocontinue = 0;
    float param1 = 0;
    float param2 = 0;
    float param3 = 0;
    float param4 = 0;
    int   param5 = 0;
    int   param6 = 0;
    float param7 = 0;
};

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

    void commandDone();
    void commandFailed();

public slots:
    void onStarted();

protected slots:
    void processMavlinkUDPDatagrams();
    void processMavlinkTCPData();

    void onTCPDisconnected();
    void onTCPConnected();


protected:
    void stateLoop();
    void commandStateLoop();
    bool isConnectionLost();
    void resetParamVars();
    void processData(QByteArray data);
    void sendData(char* data, int len);
    void send_command(MavlinkCommand command);

    void reconnectTCP();

    QVariantMap m_allParameters;

    MavlinkState state = MavlinkStateDisconnected;
    MavlinkCommandState m_command_state = MavlinkCommandStateReady;

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

    QString groundAddress;
    quint16 groundUDPPort = 14550;
    quint16 groundTCPPort = 5761;

    std::atomic<bool> m_ground_available;
    MavlinkType m_mavlink_type;
    QAbstractSocket *mavlinkSocket = nullptr;

    mavlink_status_t r_mavlink_status;

    qint64 m_last_heartbeat = -1;

    qint64 last_heartbeat_timestamp = 0;

    QTimer* timer = nullptr;
    QTimer* m_command_timer = nullptr;
    QTimer* tcpReconnectTimer = nullptr;

    uint64_t m_last_boot = 0;

    uint64_t m_command_sent_timestamp = 0;

    std::shared_ptr<MavlinkCommand> m_current_command;
};

#endif
