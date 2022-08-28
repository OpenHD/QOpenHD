#ifndef MAVLINKTELEMETRY_H
#define MAVLINKTELEMETRY_H

#include <QObject>
#include <QtQuick>
#include <array>

#include "mavlink_include.h"

#include "../util/util.h"
#include "OHDConnection.h"


class MavlinkTelemetry : public QObject{
    Q_OBJECT
public:
    explicit MavlinkTelemetry(QObject *parent = nullptr);
    static MavlinkTelemetry& instance();
private:
    void onProcessMavlinkMessage(mavlink_message_t msg);
private:
    int pingSequenceNumber=0;
    int64_t lastTimeSyncOut=0;
public:
     Q_INVOKABLE void pingAllSystems();
    // one shot, result not quaranteed
    Q_INVOKABLE void request_openhd_version(){
        mOHDConnection->request_openhd_version();
    }
public:
    std::unique_ptr<OHDConnection> mOHDConnection;
    void sendData(mavlink_message_t msg);
};

#endif
