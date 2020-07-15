/* #################################################################################################################
 * LightTelemetry protocol (LTM)
 *
 * Ghettostation one way telemetry protocol for really low bitrates (1200/2400 bauds).
 *
 * Protocol details: 3 different frames, little endian.
 *   G Frame (GPS position) (2hz @ 1200 bauds , 5hz >= 2400 bauds): 18BYTES
 *    0x24 0x54 0x47 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF  0xFF   0xC0
 *     $     T    G  --------LAT-------- -------LON---------  SPD --------ALT-------- SAT/FIX  CRC
 *   A Frame (Attitude) (5hz @ 1200bauds , 10hz >= 2400bauds): 10BYTES
 *     0x24 0x54 0x41 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xC0
 *      $     T   A   --PITCH-- --ROLL--- -HEADING-  CRC
 *   S Frame (Sensors) (2hz @ 1200bauds, 5hz >= 2400bauds): 11BYTES
 *     0x24 0x54 0x53 0xFF 0xFF  0xFF 0xFF    0xFF    0xFF      0xFF       0xC0
 *      $     T   S   VBAT(mv)  Current(ma)   RSSI  AIRSPEED  ARM/FS/FMOD   CRC
 * ################################################################################################################# */

#include "ltmtelemetry.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#ifndef __windows__
#include <unistd.h>
#endif

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "util.h"
#include "constants.h"

#include "openhd.h"


LTMTelemetry::LTMTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "LTMTelemetry::LTMTelemetry()";

    ltmSocket = new QUdpSocket(this);
    ltmSocket->bind(QHostAddress::Any, 5001);
    connect(ltmSocket, &QUdpSocket::readyRead, this, &LTMTelemetry::processLTMDatagrams);
}


void LTMTelemetry::processLTMDatagrams() {
    QByteArray datagram;

    while (ltmSocket->hasPendingDatagrams()) {
        datagram.resize(int(ltmSocket->pendingDatagramSize()));
        ltmSocket->readDatagram(datagram.data(), datagram.size());
        ltm_read((uint8_t *)datagram.data(), datagram.length());
    }
}


void LTMTelemetry::processLTMMessage() {
    LTMreadIndex = 0;

    if (LTMcmd == LIGHTTELEMETRY_GFRAME)  {
        auto latitude = (double)((int32_t)ltmread_u32())/10000000;
        OpenHD::instance()->set_lat(latitude);

        auto longitude = (double)((int32_t)ltmread_u32())/10000000;
        OpenHD::instance()->set_lon(longitude);

        uint8_t uav_groundspeedms = ltmread_u8();
        auto speed = (float)(uav_groundspeedms * 3.6f); // convert to kmh
        OpenHD::instance()->set_speed(speed);

        auto rel_altitude = (float)((int32_t)ltmread_u32())/100.0f;
        OpenHD::instance()->set_alt_rel(rel_altitude);

        uint8_t ltm_satsfix = ltmread_u8();
        auto sats = (ltm_satsfix >> 2) & 0xFF;
        OpenHD::instance()->set_satellites_visible(sats);

        auto fix = ltm_satsfix & 0b00000011;
    } else if (LTMcmd == LIGHTTELEMETRY_AFRAME)  {
        auto pitch = (int16_t)ltmread_u16();
        OpenHD::instance()->set_pitch(pitch);
        auto roll =  (int16_t)ltmread_u16();
        OpenHD::instance()->set_roll(roll);
        auto heading = (float)((int16_t)ltmread_u16());
        if (heading < 0 ) heading = heading + 360; //convert from -180/180 to 0/360°
        OpenHD::instance()->set_hdg(heading);
    } else if (LTMcmd == LIGHTTELEMETRY_OFRAME)  {
        auto ltm_home_latitude = (double)((int32_t)ltmread_u32())/10000000;
        auto ltm_home_longitude = (double)((int32_t)ltmread_u32())/10000000;
        auto ltm_home_altitude = (float)((int32_t)ltmread_u32())/100.0f;
        auto ltm_osdon = ltmread_u8();
        auto ltm_homefix = ltmread_u8();
    } else if (LTMcmd == LIGHTTELEMETRY_XFRAME)  {
        //HDOP 		uint16 HDOP * 100
        //hw status 	uint8
        //LTM_X_counter 	uint8
        //Disarm Reason 	uint8
        //(unused) 		1byte
        auto hdop = (float)((uint16_t)ltmread_u16())/10000.0f;
        OpenHD::instance()->set_gps_hdop(hdop);
    } else if (LTMcmd == LIGHTTELEMETRY_SFRAME)  {
        //Vbat 			uint16, mV
        //Battery Consumption 	uint16, mAh
        //RSSI 			uchar
        //Airspeed 			uchar, m/s
        //Status 			uchar

        auto battery_voltage = (float)ltmread_u16()/1000.0f;
        auto mah = (float)ltmread_u16()/1000.0f;
        OpenHD::instance()->set_battery_voltage(battery_voltage);

        OpenHD::instance()->set_flight_mah(mah);


        // no current provided?
        //OpenHD::instance()->set_battery_current(ampere);

        QSettings settings;
        auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();
        int battery_percent = lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
        OpenHD::instance()->set_battery_percent(battery_percent);
        QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
        OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);

        auto rssi = ltmread_u8();
        OpenHD::instance()->set_rc_rssi(rssi);

        uint8_t uav_airspeedms = ltmread_u8();
        auto airspeed = (float)(uav_airspeedms * 3.6f); // convert to kmh
        OpenHD::instance()->set_airspeed(airspeed);

        uint8_t ltm_armfsmode = ltmread_u8();
        auto armed = ltm_armfsmode & 0b00000001;
        OpenHD::instance()->set_armed(armed);

        auto ltm_failsafe = (ltm_armfsmode >> 1) & 0b00000001;

        auto _flightmode = (ltm_armfsmode >> 2) & 0b00111111;
        auto flightmode = ltm_mode_from_telem(_flightmode);
        OpenHD::instance()->set_flight_mode(flightmode);
    }
}


void LTMTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}


uint8_t LTMTelemetry::ltmread_u8()  {
    return LTMserialBuffer[LTMreadIndex++];
}


uint16_t LTMTelemetry::ltmread_u16() {
    uint16_t t = ltmread_u8();
    t |= (uint16_t)ltmread_u8()<<8;
    return t;
}


uint32_t LTMTelemetry::ltmread_u32() {
    uint32_t t = ltmread_u16();
    t |= (uint32_t)ltmread_u16()<<16;
    return t;
}


int LTMTelemetry::ltm_read(uint8_t *buf, int buflen) {
    int i;

    for (i = 0; i < buflen; ++i) {
        uint8_t c = buf[i];

        if (c_state == LTM_IDLE) {
            c_state = (c=='$') ? LTM_HEADER_START1 : LTM_IDLE;
        } else if (c_state == LTM_HEADER_START1) {
            c_state = (c=='T') ? LTM_HEADER_START2 : LTM_IDLE;
        } else if (c_state == LTM_HEADER_START2) {
            switch (c) {
                case 'G':
                    LTMframelength = LIGHTTELEMETRY_GFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                case 'A':
                    LTMframelength = LIGHTTELEMETRY_AFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                case 'S':
                    LTMframelength = LIGHTTELEMETRY_SFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                case 'O':
                    LTMframelength = LIGHTTELEMETRY_OFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                case 'N':
                    LTMframelength = LIGHTTELEMETRY_NFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                case 'X':
                    LTMframelength = LIGHTTELEMETRY_XFRAMELENGTH;
                    c_state = LTM_HEADER_MSGTYPE;
                    break;
                default:
                    c_state = LTM_IDLE;
            }
            LTMcmd = c;
            LTMreceiverIndex=0;
        } else if (c_state == LTM_HEADER_MSGTYPE) {

            if (LTMreceiverIndex == 0) {
                LTMrcvChecksum = c;
            } else {
                LTMrcvChecksum ^= c;
            }

            if (LTMreceiverIndex == LTMframelength-4) {   // received checksum byte
                if (LTMrcvChecksum == 0) {
                    processLTMMessage();
                    c_state = LTM_IDLE;
                }
                else { // wrong checksum, drop packet
                    c_state = LTM_IDLE;
                }
            }
            else LTMserialBuffer[LTMreceiverIndex++]=c;
        }
    }

    return 0;
}
