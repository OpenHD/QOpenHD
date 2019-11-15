#include "qopenhdlink.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#include <lib/json.hpp>

#define LINK_PORT 6000


QOpenHDLink::QOpenHDLink(QObject *parent):
    QObject(parent)
    {
    qDebug() << "QOpenHDLink::QOpenHDLink()";

    init();
}



void QOpenHDLink::init() {
    qDebug() << "QOpenHDLink::init()";

    linkSocket = new QUdpSocket(this);
    linkSocket->bind(LINK_PORT);

    connect(linkSocket, &QTcpSocket::readyRead, this, &QOpenHDLink::readyRead);

}


void QOpenHDLink::readyRead() {
    QByteArray datagram;

    while (linkSocket->hasPendingDatagrams()) {
        datagram.resize(int(linkSocket->pendingDatagramSize()));

        linkSocket->readDatagram(datagram.data(), datagram.size());
        processCommand(datagram);
    }
}


void QOpenHDLink::setWidgetLocation(QString widgetName, int alignment, int xOffset, int yOffset, bool hCenter, bool vCenter) {
    nlohmann::json j = {
      {"cmd", "setWidgetLocation"},
      {"widgetName", widgetName.toStdString()},
      {"alignment", alignment},
      {"xOffset", xOffset},
      {"yOffset", yOffset},
      {"hCenter", hCenter},
      {"vCenter", vCenter}
    };

    std::string serialized_string = j.dump();
    auto buf = QByteArray(serialized_string.c_str());
    if (linkSocket->state() != QUdpSocket::ConnectedState) {
        linkSocket->connectToHost("192.168.2.1", LINK_PORT);
    }
    linkSocket->writeDatagram(buf);
}


void QOpenHDLink::processCommand(QByteArray buffer) {
    try {
        auto commandData = nlohmann::json::parse(buffer);
        if (commandData.count("cmd") == 1) {
            std::string cmd = commandData["cmd"];

            if (cmd == "setWidgetLocation") {
                processSetWidgetLocation(commandData);
            }
        }
    } catch (std::exception &e) {
        // not much we can do about it but we definitely don't want a crash here,
        // we may consider show warning messages in the local message panel though
        qDebug() << "exception: " << e.what();
    }
}


void QOpenHDLink::processSetWidgetLocation(nlohmann::json commandData) {
    std::string widgetName = commandData["widgetName"];

    int alignment = commandData["alignment"];
    int xOffset = commandData["xOffset"];
    int yOffset = commandData["yOffset"];
    bool hCenter = commandData["hCenter"];
    bool vCenter = commandData["vCenter"];

    emit widgetLocation(QString(widgetName.c_str()), alignment, xOffset, yOffset, hCenter, vCenter);
}
