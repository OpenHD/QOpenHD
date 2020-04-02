#include "frskytelemetry.h"
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

FrSkyTelemetry::FrSkyTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "FrSkyTelemetry::FrSkyTelemetry()";
    init();

}

void FrSkyTelemetry::init() {
    qDebug() << "FrSkyTelemetry::init()";
#if defined(__rasp_pi__)
    restartFifo();
#else
    frskySocket = new QUdpSocket(this);
    frskySocket->bind(QHostAddress::Any, 14550);
    connect(frskySocket, &QUdpSocket::readyRead, this, &FrSkyTelemetry::processFrSkyDatagrams);
#endif
}


#if defined(__rasp_pi__)
void FrSkyTelemetry::restartFifo() {
    qDebug() << "FrSkyTelemetry::restartFifo()";
    fifoFuture = QtConcurrent::run(this, &FrSkyTelemetry::processFrSkyFifo);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &FrSkyTelemetry::restartFifo);
    connect(&watcher, &QFutureWatcherBase::finished, this, &FrSkyTelemetry::restartFifo);
    watcher.setFuture(fifoFuture);
}

void FrSkyTelemetry::processFrSkyFifo() {
    uint8_t buf[4096];

    int fifoFP = open(FRSKY_FIFO, O_RDONLY);
    if (fifoFP < 0) {
        QThread::msleep(1000);
        return;
    }

    while (true) {
        int received = read(fifoFP, buf, sizeof(buf));
        if (received < 0) {
            qDebug() << "FrSky fifo returned -1";

            close(fifoFP);
            QThread::msleep(1000);
            return;
        }
        for (int i = 0; i < received; i++) {
            /*if (res) {
                  processFrSkyMessage(msg);
              }*/
        }
    }
    QThread::msleep(1000);
    close(fifoFP);
}
#else
void FrSkyTelemetry::processFrSkyDatagrams() {
    QByteArray datagram;

    while (frskySocket->hasPendingDatagrams()) {
        datagram.resize(int(frskySocket->pendingDatagramSize()));
        frskySocket->readDatagram(datagram.data(), datagram.size());
        typedef QByteArray::Iterator Iterator;

        for (Iterator i = datagram.begin(); i != datagram.end(); i++) {            
            /*if (res) {
                  processFrSkyMessage(msg);
              }*/
        }
    }
}
#endif

void FrSkyTelemetry::processFrSkyMessage() {

}

void FrSkyTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
