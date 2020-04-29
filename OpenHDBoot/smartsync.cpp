#include "smartsync.h"

#include <QtNetwork>


SmartSync::SmartSync(QObject *parent): QObject(parent) {
    qDebug() << "SmartSync::SmartSync()";
}

void SmartSync::onStarted() {
    qDebug() << "SmartSync::onStarted()";

    smartSyncSocket = new QUdpSocket(this);
    smartSyncSocket->bind(QHostAddress::Any, 50001);
    connect(smartSyncSocket, &QUdpSocket::readyRead, this, &SmartSync::processDatagrams);
}


void SmartSync::processDatagrams() {
    QByteArray datagram;
    smartsync_status_t status;

    while (smartSyncSocket->hasPendingDatagrams()) {
        datagram.resize(int(smartSyncSocket->pendingDatagramSize()));
        smartSyncSocket->readDatagram(datagram.data(), datagram.size());

        if (datagram.size() == sizeof(smartsync_status_t)) {
            memcpy(&status, datagram.constData(), datagram.size());
            processSmartSyncMessage(status);
        }
    }
}


void SmartSync::processSmartSyncMessage(smartsync_status_t status) {
    setState(status.state);

    switch (m_state) {
        case SmartSyncStateWaiting: {
            setMessage("Waiting...");
            break;
        }
        case SmartSyncStateTransferring: {
            setMessage("Transferring...");
            break;
        }
        case SmartSyncStateFinished: {
            setMessage("Finished");
            break;
        }
        case SmartSyncStateError: {
            setMessage("Error, see log");
            break;
        }
        default: {
            break;
        }
    }
}


void SmartSync::setMessage(QString message) {
    m_message = message;
    emit messageChanged(m_message);
}


void SmartSync::setState(int state) {
    m_state = state;
    emit stateChanged(m_state);
}


void SmartSync::setProgress(int progress) {
    m_progress = progress;
    emit progressChanged(m_progress);
}
