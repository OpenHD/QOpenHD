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

typedef enum MavlinkCommandType {
    MavlinkCommandTypeLong,
    MavlinkCommandTypeInt
} MavlinkCommandType;

class MavlinkCommand  {
public:
    MavlinkCommand(MavlinkCommandType command_type) : m_command_type(command_type) {}
    MavlinkCommandType m_command_type;
    uint16_t command_id = 0;
    uint8_t retry_count = 0;

    uint8_t long_confirmation = 0;
    float long_param1 = 0;
    float long_param2 = 0;
    float long_param3 = 0;
    float long_param4 = 0;
    float long_param5 = 0;
    float long_param6 = 0;
    float long_param7 = 0;


    uint8_t int_frame = 0;
    uint8_t int_current = 0;
    uint8_t int_autocontinue = 0;
    float int_param1 = 0;
    float int_param2 = 0;
    float int_param3 = 0;
    float int_param4 = 0;
    int   int_param5 = 0;
    int   int_param6 = 0;
    float int_param7 = 0;
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

    void sendHeartbeat();


    Q_PROPERTY(qint64 last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(qint64 last_heartbeat);

    Q_PROPERTY(qint64 last_attitude MEMBER m_last_attitude WRITE set_last_attitude NOTIFY last_attitude_changed)
    void set_last_attitude(qint64 last_attitude);

    Q_PROPERTY(qint64 last_battery MEMBER m_last_battery WRITE set_last_battery NOTIFY last_battery_changed)
    void set_last_battery(qint64 last_battery);

    Q_PROPERTY(qint64 last_gps MEMBER m_last_gps WRITE set_last_gps NOTIFY last_gps_changed)
    void set_last_gps(qint64 last_gps);

    Q_PROPERTY(qint64 last_vfr MEMBER m_last_vfr WRITE set_last_vfr NOTIFY last_vfr_changed)
    void set_last_vfr(qint64 last_vfr);


    Q_INVOKABLE void setGroundIP(QString address);

signals:
    void last_heartbeat_changed(qint64 last_heartbeat);
    void last_attitude_changed(qint64 last_attitude);
    void last_battery_changed(qint64 last_battery);
    void last_gps_changed(qint64 last_gps);
    void last_vfr_changed(qint64 last_vfr);
    void setup();
    void processMavlinkMessage(mavlink_message_t msg);

    void allParametersChanged();

    void loadingChanged(bool loading);
    void savingChanged(bool saving);

    void commandDone();
    void commandFailed();

    void bindError();

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
    void sendCommand(MavlinkCommand command);
    void setDataStreamRate(MAV_DATA_STREAM streamType, uint8_t hz);

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
    quint8 targetSysID1;
    quint8 targetSysID2;
    quint8 targetCompID1;
    quint8 targetCompID2;
    quint8 targetCompID3;

    quint16 localPort = 14550;

    QString groundAddress;
    quint16 groundUDPPort = 14550;
    quint16 groundTCPPort = 5761;

    std::atomic<bool> m_ground_available;
    MavlinkType m_mavlink_type;
    QAbstractSocket *mavlinkSocket = nullptr;

    mavlink_status_t r_mavlink_status;

    qint64 m_last_heartbeat = -1;
    qint64 m_last_attitude = -1;
    qint64 m_last_battery = -1;
    qint64 m_last_gps = -1;
    qint64 m_last_vfr = -1;

    qint64 last_heartbeat_timestamp = 0;
    qint64 last_battery_timestamp = 0;
    qint64 last_gps_timestamp = 0;
    qint64 last_vfr_timestamp = 0;
    qint64 last_attitude_timestamp = 0;

    QTimer* timer = nullptr;
    QTimer* m_heartbeat_timer = nullptr;

    QTimer* m_command_timer = nullptr;
    QTimer* tcpReconnectTimer = nullptr;

    uint64_t m_last_boot = 0;

    uint64_t m_command_sent_timestamp = 0;

    std::shared_ptr<MavlinkCommand> m_current_command;
};

#endif
