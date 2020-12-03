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
    static OpenHDTelemetry* instance();


    Q_PROPERTY(qint64 last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(qint64 last_heartbeat);

signals:
    void last_heartbeat_changed(qint64 last_heartbeat);

public slots:
    void onStarted();

private slots:
    void processDatagrams();

    void processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry);
private:
    void stateLoop();

    QUdpSocket *telemetrySocket = nullptr;

    QTimer* timer = nullptr;

    qint64 m_last_heartbeat = -1;

    qint64 last_heartbeat_timestamp = 0;
};

#endif
