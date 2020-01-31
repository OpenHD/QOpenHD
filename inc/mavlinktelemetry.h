#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
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
    static MavlinkTelemetry* instance();

    Q_INVOKABLE QVariantMap getAllParameters();

    Q_PROPERTY(bool loading MEMBER m_loading WRITE set_loading NOTIFY loadingChanged)
    void set_loading(bool loading);

    Q_PROPERTY(bool saving MEMBER m_saving WRITE set_saving NOTIFY savingChanged)
    void set_saving(bool saving);

    Q_PROPERTY(qint64 last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(qint64 last_heartbeat);

    Q_INVOKABLE void setGroundIP(QString address);

    Q_INVOKABLE void fetchParameters();

signals:
    void last_heartbeat_changed(qint64 last_heartbeat);
    void allParametersChanged();

    void loadingChanged(bool loading);
    void savingChanged(bool saving);

public slots:
    void onStarted();

private slots:
    void processMavlinkDatagrams();

    void processMavlinkMessage(mavlink_message_t msg);

private:
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

    qint64 m_last_heartbeat = -1;

    qint64 last_heartbeat_timestamp = 0;

    QTimer* timer = nullptr;

    bool m_loading = false;
    bool m_saving = false;
};

#endif
