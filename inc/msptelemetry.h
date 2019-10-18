#ifndef MSPTELEMETRY_H
#define MSPTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"


class QUdpSocket;

class MSPTelemetry: public QObject {
    Q_OBJECT

public:
    explicit MSPTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
#if defined(__rasp_pi__)
    void processMSPFifo();
    void restartFifo();
#else
    void processMSPDatagrams();
#endif

private:
    void init();


    void processMSPMessage();

#if defined(__rasp_pi__)
    QFuture<void> fifoFuture;
    QFutureWatcher<void> watcher;
#else
    QUdpSocket *mspSocket = nullptr;
#endif

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;

};

#endif //MSPTELEMETRY_H
