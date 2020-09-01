#ifndef FRSKYTELEMETRY_H
#define FRSKYTELEMETRY_H

#include <QObject>
#include <QtQuick>

#include "constants.h"

#include "util.h"

typedef struct {
    int sm_state;
    uint8_t pkg[64];
    int pkg_pos;
} frsky_state_t;


class QUdpSocket;

class FrSkyTelemetry: public QObject {
    Q_OBJECT

public:
    explicit FrSkyTelemetry(QObject *parent = nullptr);


    Q_PROPERTY(QString last_heartbeat MEMBER m_last_heartbeat WRITE set_last_heartbeat NOTIFY last_heartbeat_changed)
    void set_last_heartbeat(QString last_heartbeat);

signals:
    void last_heartbeat_changed(QString last_heartbeat);


private slots:
    void processFrSkyDatagrams();

private:
    OpenHDUtil m_util;

    void frsky_interpret_packet();
    void frsky_parse_buffer(uint8_t *buf, int buflen);

    void processFrSkyMessage();

    QUdpSocket *frskySocket = nullptr;

    QString m_last_heartbeat = "N/A";
    qint64 last_heartbeat_timestamp;

    frsky_state_t state;

    // temporary state to account for the way the FrSky protocol works
    double _lon = 0;
    double _lat = 0;
    double _speed = 0;
    char ew = '0';
    char ns = '0';
};

#endif //FRSKYTELEMETRY_H
