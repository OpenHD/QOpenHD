#ifndef MAVLINKBASE_H
#define MAVLINKBASE_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>

#include "../util/util.h"

#include "OHDConnection.h"
#include "mavlinkcommand.h"

typedef enum MavlinkState {
    MavlinkStateDisconnected,
    MavlinkStateConnected,
    MavlinkStateGetParameters,
    MavlinkStateIdle
} MavlinkState;


class MavlinkBase: public QObject {
    Q_OBJECT

public:
    explicit MavlinkBase(QObject *parent = nullptr);


    Q_INVOKABLE QVariantMap getAllParameters();

    Q_PROPERTY(bool loading MEMBER m_loading WRITE set_loading NOTIFY loadingChanged)
    void set_loading(bool loading);

    Q_PROPERTY(bool saving MEMBER m_saving WRITE set_saving NOTIFY savingChanged)
    void set_saving(bool saving);

    Q_INVOKABLE void fetchParameters();

    //void sendHeartbeat();
    void sendRC();

    Q_INVOKABLE void get_Mission_Items(int count);
    Q_INVOKABLE void send_Mission_Ack();


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


    //Q_INVOKABLE void setGroundIP(QString address);
protected:
    virtual void onProcessMavlinkMessage(mavlink_message_t msg)=0;

signals:
    void last_heartbeat_changed(qint64 last_heartbeat);
    void last_attitude_changed(qint64 last_attitude);
    void last_battery_changed(qint64 last_battery);
    void last_gps_changed(qint64 last_gps);
    void last_vfr_changed(qint64 last_vfr);
    void setup();
    //void processMavlinkMessage(mavlink_message_t msg);

    void allParametersChanged();

    void loadingChanged(bool loading);
    void savingChanged(bool saving);

    void commandDone();
    void commandFailed();

    void bindError();

public slots:
    void onStarted();    
    void request_Mission_Changed();
    // for RC
    void receive_RC_Update(std::array<uint,19> rcValues);
    void joystick_Present_Changed(bool joystickPresent);
protected:
    void stateLoop();
    void commandStateLoop();
    bool isConnectionLost();
    void resetParamVars();
    void processData(QByteArray data);
    void sendData(mavlink_message_t msg);
    void sendCommand(MavlinkCommand command);   
    void setDataStreamRate(MAV_DATA_STREAM streamType, uint8_t hz);
    void requestAutopilotInfo();

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
    OpenHDUtil m_util;
    quint8 targetSysID;
    quint8 targetCompID;

    std::atomic<bool> m_ground_available;

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
    QTimer* m_rc_timer = nullptr;
    QTimer* m_command_timer = nullptr;
    uint64_t m_last_boot = 0;
    uint64_t m_command_sent_timestamp = 0;
    std::shared_ptr<MavlinkCommand> m_current_command;

    std::array<uint,19> m_rc_values;
    // ---------
private:
    std::unique_ptr<OHDConnection> mOHDConnection;
public:
    int getQOpenHDSysId();
};

#endif
