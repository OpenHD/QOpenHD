#ifndef VECTORTELEMETRY_H
#define VECTORTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include "util.h"


enum _serial_state {
    IDLE,
    HEADER_START1,
    HEADER_START2,
    HEADER_START3,
    HEADER_START4,
    HEADER_MSGTYPE
};

class QUdpSocket;

class VectorTelemetry: public QObject {
    Q_OBJECT

public:
    explicit VectorTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
    void processVectorDatagrams();

private:
    OpenHDUtil m_util;

    uint8_t votread_u8();
    uint16_t votread_u16();
    uint16_t votbread_u16();
    uint32_t votread_u32();
    uint32_t votbread_u32();
    uint16_t CRC16Worker(uint16_t icrc, uint8_t r0);
    uint16_t CalculateCRC(uint8_t * pPacket, uint8_t Size, uint16_t InitCRC);
    void vot_read(uint8_t *buf, uint8_t buflen);


    void processVectorMessage();

    QUdpSocket *vectorSocket = nullptr;

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;


    enum _serial_state c_state = IDLE;

    uint8_t VOTReceiverIndex;
    uint8_t VOTReadIndex;
    uint16_t VOTRcvChecksum;
};

#endif //VECTORTELEMETRY_H
