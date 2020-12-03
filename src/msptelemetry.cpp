#include "msptelemetry.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#ifndef __windows__
#include <unistd.h>
#endif

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "util.h"
#include "constants.h"

#include "openhd.h"

MSPTelemetry::MSPTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "MSPTelemetry::MSPTelemetry()";

    mspSocket = new QUdpSocket(this);
    mspSocket->bind(QHostAddress::Any, 14550);
    connect(mspSocket, &QUdpSocket::readyRead, this, &MSPTelemetry::processMSPDatagrams);
}


void MSPTelemetry::processMSPDatagrams() {
    QByteArray datagram;

    while (mspSocket->hasPendingDatagrams()) {
        datagram.resize(int(mspSocket->pendingDatagramSize()));
        mspSocket->readDatagram(datagram.data(), datagram.size());
        typedef QByteArray::Iterator Iterator;

        for (Iterator i = datagram.begin(); i != datagram.end(); i++) {            
            /*if (res) {
                  processMSPMessage(msg);
              }*/
        }
    }
}

void MSPTelemetry::processMSPMessage() {

}

void MSPTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
