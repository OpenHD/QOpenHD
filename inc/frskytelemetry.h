#ifndef FRSKYTELEMETRY_H
#define FRSKYTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"


class QUdpSocket;

class FrSkyTelemetry: public QObject {
    Q_OBJECT

public:
    explicit FrSkyTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
#if defined(__rasp_pi__)
    void processFrSkyFifo();
    void restartFifo();
#else
    void processFrSkyDatagrams();
#endif

private:
    void init();


    void processFrSkyMessage();

#if defined(__rasp_pi__)
    QFuture<void> fifoFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *frskySocket = nullptr;
#endif

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;

};

#endif //FRSKYTELEMETRY_H
