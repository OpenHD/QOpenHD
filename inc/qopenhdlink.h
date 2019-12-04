#ifndef QOpenHDLink_H
#define QOpenHDLink_H

#include <QObject>
#include <QtQuick>

#include "constants.h"
#include <lib/json.hpp>


class QUdpSocket;

class QOpenHDLink: public QObject {
    Q_OBJECT

public:
    explicit QOpenHDLink(QObject *parent = nullptr);

    Q_INVOKABLE void setWidgetLocation(QString widgetName, int alignment, int xOffset, int yOffset, bool hCenter, bool vCenter);
    Q_INVOKABLE void setWidgetEnabled(QString widgetName, bool enabled);

    Q_INVOKABLE void setGroundIP(QHostAddress address);


signals:
    void widgetLocation(QString widgetName, int alignment, int xOffset, int yOffset, bool hCenter, bool vCenter);
    void widgetEnabled(QString widgetName, bool enabled);

private slots:
    void readyRead();

private:
    void init();

    QHostAddress groundAddress;

    void processCommand(QByteArray buffer);
    void processSetWidgetLocation(nlohmann::json command);
    void processSetWidgetEnabled(nlohmann::json commandData);

    QUdpSocket *linkSocket = nullptr;
};

#endif
