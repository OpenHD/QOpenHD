#include "msptelemetry.h"
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

MSPTelemetry::MSPTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "MSPTelemetry::MSPTelemetry()";
    init();

}

void MSPTelemetry::init() {
    qDebug() << "MSPTelemetry::init()";
#if defined(__rasp_pi__)
    restartFifo();
#else
    mspSocket = new QUdpSocket(this);
    mspSocket->bind(QHostAddress::Any, 14550);
    connect(mspSocket, &QUdpSocket::readyRead, this, &MSPTelemetry::processMSPDatagrams);
#endif
}


#if defined(__rasp_pi__)
void MSPTelemetry::restartFifo() {
    qDebug() << "MSPTelemetry::restartFifo()";
    fifoFuture = QtConcurrent::run(this, &MSPTelemetry::processMSPFifo);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &MSPTelemetry::restartFifo);
    connect(&watcher, &QFutureWatcherBase::finished, this, &MSPTelemetry::restartFifo);
    watcher.setFuture(fifoFuture);
}

void MSPTelemetry::processMSPFifo() {
    uint8_t buf[4096];

    int fifoFP = open(MSP_FIFO, O_RDONLY);
    if (fifoFP < 0) {
        QThread::msleep(1000);
        return;
    }

    while (true) {
        int received = read(fifoFP, buf, sizeof(buf));
        if (received < 0) {
            qDebug() << "MSP fifo returned -1";

            close(fifoFP);
            QThread::msleep(1000);
            return;
        }
        for (int i = 0; i < received; i++) {
            //if (res) {
            //    processMSPMessage(msg);
            //}
        }
    }
    QThread::msleep(1000);
    close(fifoFP);
}
#else
void MSPTelemetry::processMSPDatagrams() {
    QByteArray datagram;

    while (mspSocket->hasPendingDatagrams()) {
        datagram.resize(int(mspSocket->pendingDatagramSize()));
        mspSocket->readDatagram(datagram.data(), datagram.size());
        typedef QByteArray::Iterator Iterator;

        for (Iterator i = datagram.begin(); i != datagram.end(); i++) {            
            //if (res) {
            //    processMSPMessage(msg);
            //}
        }
    }
}
#endif

void MSPTelemetry::processMSPMessage() {

}

void MSPTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
