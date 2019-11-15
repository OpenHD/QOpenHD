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

signals:
    void widgetLocation(QString widgetName, int alignment, int xOffset, int yOffset, bool hCenter, bool vCenter);
private slots:
    void readyRead();

private:
    void init();

    void processCommand(QByteArray buffer);
    void processSetWidgetLocation(nlohmann::json command);


    QUdpSocket *linkSocket = nullptr;
};

#endif
