#ifndef SMARTPORTTELEMETRY_H
#define SMARTPORTTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include "util.h"


typedef struct {
    uint16_t id;
    union {
        uint32_t u32;
        int32_t i32;
        uint16_t u16;
        int16_t i16;
        uint8_t u8;
        uint8_t b[4];
        int8_t i8;
        float f;
    } data;
    uint8_t crc;
} tSPortData;


class QUdpSocket;

class SmartportTelemetry: public QObject {
    Q_OBJECT

public:
    explicit SmartportTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
    void processSmartportDatagrams();

private:
    OpenHDUtil m_util;

    void smartport_read(uint8_t *buf, int buflen);
    uint8_t u8CheckCrcSPORT(uint8_t *t);

    void processSmartportMessage(uint8_t *b);

    QUdpSocket *smartportSocket = nullptr;

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;

};

#endif //SMARTPORTTELEMETRY_H
