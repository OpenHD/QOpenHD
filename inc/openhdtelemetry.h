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
#if defined(__rasp_pi__)
    void processSHM();
    void restartSHM();
#else
    void processDatagrams();
#endif
    void processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry);
private:
    void init();
#if defined(__rasp_pi__)
    QFuture<void> shmFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *telemetrySocket = nullptr;
#endif

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;

#if defined(__rasp_pi__)
    wifibroadcast_rx_status_t *rx_status = nullptr;
    wifibroadcast_rx_status_t_osd *rx_status_osd = nullptr;
    wifibroadcast_rx_status_t_rc *rx_status_rc = nullptr;
    wifibroadcast_rx_status_t_uplink *rx_status_uplink = nullptr;
    wifibroadcast_rx_status_t_sysair *rx_status_sysair = nullptr;
#endif
};

#endif
