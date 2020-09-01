#include "smartporttelemetry.h"
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


#define START_STOP 0x7e
#define DATA_FRAME 0x10

//Frsky DATA ID's
#define FR_ID_ALTITUDE 0x0100 //ALT_FIRST_ID
#define FR_ID_VARIO 0x0110 //VARIO_FIRST_ID
#define FR_ID_ALTITUDE 0x0100 //ALT_FIRST_ID
#define FR_ID_VARIO 0x0110 //VARIO_FIRST_ID
#define FR_ID_VFAS 0x0210 //VFAS_FIRST_ID
#define FR_ID_CURRENT 0x0200 //CURR_FIRST_ID
#define FR_ID_CELLS 0x0300 //CELLS_FIRST_ID
#define FR_ID_CELLS_LAST 0x030F //CELLS_LAST_ID
#define FR_ID_T1 0x0400 //T1_FIRST_ID
#define FR_ID_T2 0x0410 //T2_FIRST_ID
#define FR_ID_RPM 0x0500 //RPM_FIRST_ID
#define FR_ID_FUEL 0x0600 //FUEL_FIRST_ID
#define FR_ID_ACCX 0x0700 //ACCX_FIRST_ID
#define FR_ID_ACCY 0x0710 //ACCY_FIRST_ID
#define FR_ID_ACCZ 0x0720 //ACCZ_FIRST_ID
#define FR_ID_LATLONG 0x0800 //GPS_LONG_LATI_FIRST_ID
#define FR_ID_GPS_ALT 0x0820 //GPS_ALT_FIRST_ID
#define FR_ID_SPEED 0x0830 //GPS_SPEED_FIRST_ID
#define FR_ID_GPS_COURSE 0x0840 //GPS_COURS_FIRST_ID
#define FR_ID_GPS_TIME_DATE 0x0850 //GPS_TIME_DATE_FIRST_ID
#define FR_ID_GPS_SAT 0x0860 //GPS satellite count and fix state (own definition)
#define FR_ID_A3_FIRST 0x0900 //A3_FIRST_ID
#define FR_ID_A4_FIRST 0x0910 //A4_FIRST_ID
#define FR_ID_AIR_SPEED_FIRST 0x0A00 //AIR_SPEED_FIRST_ID
#define FR_ID_RSSI 0xF101 // used by the radio system
#define FR_ID_ADC1 0xF102 //ADC1_ID
#define FR_ID_ADC2 0xF103 //ADC2_ID
#define FR_ID_RXBATT 0xF104 // used by the radio system
#define FR_ID_SWR 0xF105 // used by the radio system
#define FR_ID_FIRMWARE 0xF106 // used by the radio system
#define FR_ID_VFAS 0x0210 //VFAS_FIRST_ID


SmartportTelemetry::SmartportTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "SmartportTelemetry::SmartportTelemetry()";

    smartportSocket = new QUdpSocket(this);
    smartportSocket->bind(QHostAddress::Any, 5010);
    connect(smartportSocket, &QUdpSocket::readyRead, this, &SmartportTelemetry::processSmartportDatagrams);
}


void SmartportTelemetry::processSmartportDatagrams() {
    QByteArray datagram;

    while (smartportSocket->hasPendingDatagrams()) {
        datagram.resize(int(smartportSocket->pendingDatagramSize()));
        smartportSocket->readDatagram(datagram.data(), datagram.size());
        smartport_read((uint8_t*)datagram.data(), datagram.length());
    }
}


void SmartportTelemetry::processSmartportMessage(uint8_t *b) {
    tSPortData tel;

    tel.id = (uint16_t)b[1];
    tel.id <<= 8u;
    tel.id += (uint16_t)b[0];

    tel.data.b[0] = b[2];
    tel.data.b[1] = b[3];
    tel.data.b[2] = b[4];
    tel.data.b[3] = b[5];

    tel.crc = b[6];

    switch (tel.id) {
        case FR_ID_VFAS: {
            auto battery_voltage = (float)tel.data.u16 / 100.0;
            OpenHD::instance()->set_battery_voltage(battery_voltage);
            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();
            int battery_percent = m_util.lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            OpenHD::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_percent);
            OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);
            break;
        }
        case FR_ID_LATLONG: {
            if (tel.data.u32 & 0x80000000) {
                float longitude = (float)(tel.data.u32 & 0x3fffffff);
                longitude /= 600000;
                if (tel.data.u32 & 0x40000000) {
                    longitude = -longitude;
                }
                OpenHD::instance()->set_lon(longitude);
            } else {
                float latitude = (float)(tel.data.u32 & 0x3fffffff);
                latitude /= 600000;
                if (tel.data.u32 & 0x40000000) {
                    latitude = -latitude;
                }
                OpenHD::instance()->set_lat(latitude);
            }
            break;
        }
        case FR_ID_GPS_ALT: {
            auto msl_altitude = (float)(tel.data.i32) / 100.0;
            OpenHD::instance()->set_alt_msl(msl_altitude);
            break;
        }
        case FR_ID_SPEED: {
            auto speed = (float)(tel.data.u32) / 2000.0;
            OpenHD::instance()->set_speed(speed);
            break;
        }
        case FR_ID_GPS_COURSE: {
            auto heading = (float)( tel.data.u32 ) / 100.0;
            OpenHD::instance()->set_hdg(heading);
            break;
        }
        case FR_ID_T1: {
            // iNac, CF flight modes / arm
            //u16Modes = tel->d.data.u16; // see inav smartport.c //printf( "T1: %x", tel->d.data.u32 );
            break;
        }
        case FR_ID_T2: {
            // iNav, CF sat fix / home
            //auto fix = (uint8_t)( tel.data.u32 / 1000 );
            auto sats = (uint8_t)( tel.data.u32 % 1000 );
            OpenHD::instance()->set_satellites_visible(sats);
            break;
        }
        case FR_ID_GPS_SAT: {
            // car ctrl sat fix
            //auto fix = (uint8_t)( tel.data.u16 % 10 );
            auto sats = (uint8_t)( tel.data.u16 / 10 ); //printf( "Sat: %x", tel->d.data.u32 );
            OpenHD::instance()->set_satellites_visible(sats);
            break;
        }
        case FR_ID_RSSI: {
            //auto rssi = (uint8_t)tel.data.u8; //printf( "RSSI: %x - %x", u8UavRssi, tel->d.data.u32 );
            break;
        }
        case FR_ID_RXBATT: {
            //auto rx_batt = (float)(tel.data.u8);
            //rx_batt *= 3.3 / 255.0 * 4.0;
            break;
        }
        case FR_ID_SWR: {
            //auto swr = (uint8_t)(tel.data.u32);
            break;
        }
        case FR_ID_ADC1: {
            //double adc1 = (float)tel.data.u8;
            //adc1 *= 3.3 / 255.0;
            break;
        }
        case FR_ID_ADC2: {
            //double adc2 = (float)tel.data.u8;
            //adc2 = 3.3 / 255.0;
            break;
        }
        case FR_ID_ALTITUDE: {
            auto rel_altitude = (float)(tel.data.i32) / 100.0;
            OpenHD::instance()->set_alt_rel(rel_altitude);
            break;
        }
        case FR_ID_VARIO: {
            //auto vario = (float)( tel.data.i32 ) / 100;
            break;
        }
        case FR_ID_ACCX: {
            auto x = tel.data.i16;
            OpenHD::instance()->set_vx(x);
            break;
        }
        case FR_ID_ACCY: {
            auto y = tel.data.i16;
            OpenHD::instance()->set_vy(y);
            break;
        }
        case FR_ID_ACCZ: {
            auto z = tel.data.i16;
            OpenHD::instance()->set_vz(z);
            break;
        }
        case FR_ID_CURRENT: {
            auto ampere = (float)tel.data.u16 / 10.0;  // this is guessed
            OpenHD::instance()->set_battery_current(ampere);
            break;
        }
        case FR_ID_CELLS: {
            break;
        }
        case FR_ID_CELLS_LAST: {
            break;
        }
        case FR_ID_RPM: {
            break;
        }
        case FR_ID_FUEL: {
            break;
        }
        case FR_ID_GPS_TIME_DATE: {
            break;
        }
        case FR_ID_A3_FIRST: {
            break;
        }
        case FR_ID_A4_FIRST: {
            break;
        }
        case FR_ID_AIR_SPEED_FIRST: {
            break;
        }
        case FR_ID_FIRMWARE: {
            break;
        }
        default: {
            //printf( "\r\nsmartport unknown id: %x , %x", (uint16_t)tel.id, tel.data.u32 );
            break;
        }
    }
}


void SmartportTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}


void SmartportTelemetry::smartport_read(uint8_t *buf, int buflen) {
    static uint8_t s = 0;
    static uint8_t e = 0;
    static uint8_t tBuffer[7];
    uint8_t b;
    int i;

    for (i = 0; i < buflen; i++) {
        b = *buf++;
        if ((e == 0) && (b == 0x7d)) {
            e = 1;
            continue;
        }
        if (e == 1) {
            e = 0;
            b = b + 0x20;
        }

        if (s == 0) {
            if (b == DATA_FRAME) {
                s++;
            }
        }
        else if (s <= 6) {
            tBuffer[s-1] = b;
            s++;
        } else {
            tBuffer[6] = b;
            if (0 != u8CheckCrcSPORT(tBuffer)) {
                processSmartportMessage(tBuffer);
            }
            s = 0;
        }
    }
}


uint8_t SmartportTelemetry::u8CheckCrcSPORT(uint8_t *b) {
    uint16_t u16Crc = DATA_FRAME;

    int i;

    for (i = 0; i < 6; i++) {
        u16Crc += b[i];
        u16Crc += u16Crc >> 8;
        u16Crc &= 0x00ff;
    }

    if ((uint8_t)(0xFF - u16Crc) == b[6]) {
        return 1u;
    } else {
        return 0u;
    }
}
