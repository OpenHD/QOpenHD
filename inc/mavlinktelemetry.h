#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>


#include <openhd/mavlink.h>
#include "constants.h"

#include "util.h"

#include "mavlinkbase.h"


class QUdpSocket;



class MavlinkTelemetry: public MavlinkBase {
    Q_OBJECT

public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry* instance();

public slots:
    void onSetup();
    void pauseTelemetry(bool toggle);

private slots:
    void onProcessMavlinkMessage(mavlink_message_t msg);

private:
    bool pause_telemetry;
};

#endif
