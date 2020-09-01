#ifndef LTMTELEMETRY_H
#define LTMTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include "util.h"

#define LIGHTTELEMETRY_START1 0x24 //$ Header byte 1
#define LIGHTTELEMETRY_START2 0x54 //T Header byte 2
#define LIGHTTELEMETRY_GFRAME 0x47 //G GPS frame: GPS + Baro altitude data (Lat, Lon, Speed, Alt, Sats, Sat fix)
#define LIGHTTELEMETRY_AFRAME 0x41 //A Attitude frame: Attitude data (Roll, Pitch, Heading)
#define LIGHTTELEMETRY_SFRAME 0x53 //S Status frame: Sensors/Status data (VBat, Consumed current, Rssi, Airspeed, Arm status, Failsafe status, Flight mode)
#define LIGHTTELEMETRY_OFRAME 0x4f //O Origin frame: (Lat, Lon, Alt, OSD on, home fix)
#define LIGHTTELEMETRY_NFRAME 0x53 //N Navigation frame
#define LIGHTTELEMETRY_XFRAME 0x4f //X GPS eXtra frame: (GPS HDOP value, hw_status (failed sensor))

// complete length including headers and checksum
#define LIGHTTELEMETRY_GFRAMELENGTH 18
#define LIGHTTELEMETRY_AFRAMELENGTH 10
#define LIGHTTELEMETRY_SFRAMELENGTH 11
#define LIGHTTELEMETRY_OFRAMELENGTH 18
#define LIGHTTELEMETRY_NFRAMELENGTH 10
#define LIGHTTELEMETRY_XFRAMELENGTH 10


enum ltm_serial_state {
    LTM_IDLE,
    LTM_HEADER_START1,
    LTM_HEADER_START2,
    LTM_HEADER_MSGTYPE,
    LTM_HEADER_DATA
};


class QUdpSocket;

class LTMTelemetry: public QObject {
    Q_OBJECT

public:
    explicit LTMTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
    void processLTMDatagrams();

private:
    OpenHDUtil m_util;

    int ltm_read(uint8_t *buf, int buflen);
    uint8_t ltmread_u8();
    uint16_t ltmread_u16();
    uint32_t ltmread_u32();

    void processLTMMessage();

    QUdpSocket *ltmSocket = nullptr;

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;


    enum ltm_serial_state c_state = LTM_IDLE;

    uint8_t LTMserialBuffer[LIGHTTELEMETRY_GFRAMELENGTH-4];
    uint8_t LTMreceiverIndex;
    uint8_t LTMcmd;
    uint8_t LTMrcvChecksum;
    uint8_t LTMreadIndex;
    uint8_t LTMframelength;

};

#endif //LTMTELEMETRY_H
