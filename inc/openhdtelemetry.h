#ifndef OPENHDTELEMETRY_H
#define OPENHDTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "wifibroadcast.h"
#include "constants.h"

class QUdpSocket;

class OpenHDTelemetry: public QObject {
    Q_OBJECT

public:
    explicit OpenHDTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);

private slots:
    void processDatagrams();

    void processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry);
private:
    void init();
    void stateLoop();

    QUdpSocket *telemetrySocket = nullptr;

    QTimer m_stateLoopTimer;

    QString m_last_heartbeat = "N/A";
    qint64 m_last_heartbeat_raw = -1;

    qint64 last_heartbeat_timestamp;
};

#endif
