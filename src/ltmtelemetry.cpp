#include "ltmtelemetry.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "util.h"
#include "constants.h"

#include "openhd.h"

LTMTelemetry::LTMTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "LTMTelemetry::LTMTelemetry()";
    init();

}

void LTMTelemetry::init() {
    qDebug() << "LTMTelemetry::init()";
#if defined(__rasp_pi__)
    restartFifo();
#else
    ltmSocket = new QUdpSocket(this);
    ltmSocket->bind(QHostAddress::Any, 14550);
    connect(ltmSocket, &QUdpSocket::readyRead, this, &LTMTelemetry::processLTMDatagrams);
#endif
}


#if defined(__rasp_pi__)
void LTMTelemetry::restartFifo() {
    qDebug() << "LTMTelemetry::restartFifo()";
    fifoFuture = QtConcurrent::run(this, &LTMTelemetry::processLTMFifo);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &LTMTelemetry::restartFifo);
    connect(&watcher, &QFutureWatcherBase::finished, this, &LTMTelemetry::restartFifo);
    watcher.setFuture(fifoFuture);
}

void LTMTelemetry::processLTMFifo() {
    uint8_t buf[4096];

    int fifoFP = open(LTM_FIFO, O_RDONLY);
    if (fifoFP < 0) {
        QThread::msleep(1000);
        return;
    }

    while (true) {
        int received = read(fifoFP, buf, sizeof(buf));
        if (received < 0) {
            qDebug() << "LTM fifo returned -1";

            close(fifoFP);
            QThread::msleep(1000);
            return;
        }
        for (int i = 0; i < received; i++) {
            //if (res) {
            //    processLTMMessage(msg);
            //}
        }
    }
    QThread::msleep(1000);
    close(fifoFP);
}
#else
void LTMTelemetry::processLTMDatagrams() {
    QByteArray datagram;

    while (ltmSocket->hasPendingDatagrams()) {
        datagram.resize(int(ltmSocket->pendingDatagramSize()));
        ltmSocket->readDatagram(datagram.data(), datagram.size());
        typedef QByteArray::Iterator Iterator;

        for (Iterator i = datagram.begin(); i != datagram.end(); i++) {            
            //if (res) {
            //    processLTMMessage(msg);
            //}
        }
    }
}
#endif

void LTMTelemetry::processLTMMessage() {

}

void LTMTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
