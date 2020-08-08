#include "qopenhdlink.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "constants.h"

#if defined(ENABLE_LINK)
#include <nlohmann/json.hpp>
#endif

#define LINK_PORT 6000


QOpenHDLink::QOpenHDLink(QObject *parent):
    QObject(parent)
    {
    qDebug() << "QOpenHDLink::QOpenHDLink()";

#if defined(ENABLE_LINK)
    linkSocket = new QUdpSocket(this);
    linkSocket->bind(LINK_PORT);

    connect(linkSocket, &QUdpSocket::readyRead, this, &QOpenHDLink::readyRead);
#endif
}


void QOpenHDLink::setGroundIP(QString address) {
    groundAddress = address;
}


void QOpenHDLink::readyRead() {
#if defined(ENABLE_LINK)
    QByteArray datagram;

    while (linkSocket->hasPendingDatagrams()) {
        datagram.resize(int(linkSocket->pendingDatagramSize()));

        linkSocket->readDatagram(datagram.data(), datagram.size());
        processCommand(datagram);
    }
#endif
}


void QOpenHDLink::setWidgetLocation(QString widgetName, int alignment, int xOffset, int yOffset, bool hCenter, bool vCenter) {
#if defined(ENABLE_LINK)
#if !defined(__rasp_pi__)
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
    linkSocket->writeDatagram(buf, QHostAddress(groundAddress), LINK_PORT);
#endif
#endif
}

void QOpenHDLink::setWidgetEnabled(QString widgetName, bool enabled) {
#if defined(ENABLE_LINK)
#if !defined(__rasp_pi__)
    nlohmann::json j = {
      {"cmd", "setWidgetEnabled"},
      {"widgetName", widgetName.toStdString()},
      {"enabled", enabled}
    };

    std::string serialized_string = j.dump();
    auto buf = QByteArray(serialized_string.c_str());
    linkSocket->writeDatagram(buf, QHostAddress(groundAddress), LINK_PORT);
#endif
#endif
}

void QOpenHDLink::processCommand(QByteArray buffer) {
#if defined(ENABLE_LINK)
    try {
        auto commandData = nlohmann::json::parse(buffer.toStdString());
        if (commandData.count("cmd") == 1) {
            std::string cmd = commandData["cmd"];

            if (cmd == "setWidgetLocation") {
                processSetWidgetLocation(commandData);
            }

            if (cmd == "setWidgetEnabled") {
                processSetWidgetEnabled(commandData);
            }
        }
    } catch (std::exception &e) {
        /* not much we can do about it but we definitely don't want a crash here,
           we may consider show warning messages in the local message panel though */
        qDebug() << "exception: " << e.what();
    }
#endif
}


void QOpenHDLink::processSetWidgetLocation(nlohmann::json commandData) {
#if defined(ENABLE_LINK)
    std::string widgetName = commandData["widgetName"];

    int alignment = commandData["alignment"];
    int xOffset = commandData["xOffset"];
    int yOffset = commandData["yOffset"];
    bool hCenter = commandData["hCenter"];
    bool vCenter = commandData["vCenter"];

    emit widgetLocation(QString(widgetName.c_str()), alignment, xOffset, yOffset, hCenter, vCenter);
#endif
}

void QOpenHDLink::processSetWidgetEnabled(nlohmann::json commandData) {
#if defined(ENABLE_LINK)
    std::string widgetName = commandData["widgetName"];

    bool enabled = commandData["enabled"];

    emit widgetEnabled(QString(widgetName.c_str()), enabled);
#endif
}
