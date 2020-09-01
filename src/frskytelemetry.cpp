#include "frskytelemetry.h"
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



// Data Ids (bp = before decimal point; af = after decimal point)
// Official data IDs
#define ID_GPS_ALTITUDE_BP 0x01
#define ID_GPS_ALTITUDE_AP 0x09
#define ID_TEMPRATURE1 0x02
#define ID_RPM 0x03
#define ID_FUEL_LEVEL 0x04
#define ID_TEMPRATURE2 0x05
#define ID_VOLT 0x06
#define ID_ALTITUDE_BP 0x10
#define ID_ALTITUDE_AP 0x21
#define ID_GPS_SPEED_BP 0x11
#define ID_GPS_SPEED_AP 0x19
#define ID_LONGITUDE_BP 0x12
#define ID_LONGITUDE_AP 0x1A
#define ID_E_W 0x22
#define ID_LATITUDE_BP 0x13
#define ID_LATITUDE_AP 0x1B
#define ID_N_S 0x23
#define ID_COURSE_BP 0x14
#define ID_COURSE_AP 0x1C
#define ID_DATE_MONTH 0x15
#define ID_YEAR 0x16
#define ID_HOUR_MINUTE 0x17
#define ID_SECOND 0x18
#define ID_ACC_X 0x24
#define ID_ACC_Y 0x25
#define ID_ACC_Z 0x26
#define ID_VOLTAGE_AMP 0x39
#define ID_VOLTAGE_AMP_BP 0x3A
#define ID_VOLTAGE_AMP_AP 0x3B
#define ID_CURRENT 0x28
// User defined data IDs
#define ID_GYRO_X 0x40
#define ID_GYRO_Y 0x41
#define ID_GYRO_Z 0x42
#define ID_VERT_SPEED 0x30 //opentx vario


FrSkyTelemetry::FrSkyTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "FrSkyTelemetry::FrSkyTelemetry()";

    frskySocket = new QUdpSocket(this);
    frskySocket->bind(QHostAddress::Any, 5002);
    connect(frskySocket, &QUdpSocket::readyRead, this, &FrSkyTelemetry::processFrSkyDatagrams);
}


void FrSkyTelemetry::processFrSkyDatagrams() {
    QByteArray datagram;

    while (frskySocket->hasPendingDatagrams()) {
        datagram.resize(int(frskySocket->pendingDatagramSize()));
        frskySocket->readDatagram(datagram.data(), datagram.size());
        frsky_parse_buffer((uint8_t*)datagram.data(), datagram.length());
    }
}


void FrSkyTelemetry::processFrSkyMessage() {
    uint16_t data;

    data = *(uint16_t*)(state.pkg+1);
    switch(state.pkg[0]) {
        case ID_VOLTAGE_AMP: {
            // no idea what this is here for, it was commented out in the old OSD
            //uint16_t val = (state.pkg[2] >> 8) | ((state.pkg[1] & 0xf) << 8);
            //float battery = 3.0f * val / 500.0f;
            //td->voltage = battery;
            auto battery_voltage = data / 10.0f;

            OpenHD::instance()->set_battery_voltage(battery_voltage);

            // no current provided? is it in the 3rd byte of state.pkg?
            //OpenHD::instance()->set_battery_current(ampere);

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = m_util.lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
            OpenHD::instance()->set_battery_percent(battery_percent);
            QString battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(battery_percent);
            OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);

            break;
        }
        case ID_ALTITUDE_BP: {
            auto rel_altitude = data;
            OpenHD::instance()->set_alt_rel(rel_altitude);
            break;
        }
        case ID_ALTITUDE_AP: {
            // this was commented out in the old OSD
            //td->baro_altitude += data/100;
            break;
        }
        case ID_GPS_ALTITUDE_BP: {
            auto gps_altitude = data;
            OpenHD::instance()->set_alt_msl(gps_altitude);
            break;
        }
        case ID_LONGITUDE_BP: {
            _lon = data / 100;
            _lon += 1.0 * (data - _lon * 100) / 60;
            OpenHD::instance()->set_lon((ew == 'E' ? 1 : -1) * _lon);
            break;
        }
        case ID_LONGITUDE_AP: {
            _lon +=  1.0 * data / 60 / 10000;
            OpenHD::instance()->set_lon((ew == 'E' ? 1 : -1) * _lon);
            break;
        }
        case ID_LATITUDE_BP: {
            _lat = data / 100;
            _lat += 1.0 * (data - _lat * 100) / 60;
            OpenHD::instance()->set_lat((ns == 'N' ? 1 : -1) * _lat);
            break;
        }
        case ID_LATITUDE_AP: {
            _lat +=  1.0 * data / 60 / 10000;
            OpenHD::instance()->set_lat((ns == 'N' ? 1 : -1) * _lat);
            break;
        }
        case ID_COURSE_BP: {
            auto heading = data;
            OpenHD::instance()->set_hdg(heading);
            break;
        }
        case ID_GPS_SPEED_BP: {
            _speed = 1.0 * data / 0.0194384449;
            OpenHD::instance()->set_speed((int)_speed);
            break;
        }
        case ID_GPS_SPEED_AP: {
            _speed += 1.0 * data / 1.94384449; //now we are in cm/s
            _speed = _speed / 100 / 1000 * 3600; //now we are in km/h
            OpenHD::instance()->set_speed((int)_speed);
            break;
        }
        case ID_ACC_X: {
            auto x = data;
            OpenHD::instance()->set_vx(x);
            break;
        }
        case ID_ACC_Y: {
            auto y = data;
            OpenHD::instance()->set_vy(y);
            break;
        }
        case ID_ACC_Z: {
            auto z = data;
            OpenHD::instance()->set_vz(z);
            break;
        }
        case ID_E_W: {
            ew = (char)data;
            break;
        }
        case ID_N_S: {
            ns = (char)data;
            break;
        }
        default: {
            break;
        }
    }
}


void FrSkyTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}


void FrSkyTelemetry::frsky_parse_buffer(uint8_t *buf, int buflen) {
    int i;

    for (i = 0; i < buflen; ++i) {
        uint8_t ch = buf[i];
        switch(state.sm_state) {
            case 0: {
                if (ch == 0x5e)
                    state.sm_state = 1;
                break;
            }
            case 1: {
                if (ch == 0x5e)
                    state.sm_state = 2;
                else
                    state.sm_state = 0;
                break;
            }
            case 2: {
                if (ch == 0x5e) {
                    state.pkg_pos = 0;
                    processFrSkyMessage();
                }
                else {
                    if(state.pkg_pos >= sizeof(state.pkg)) {
                        state.pkg_pos = 0;
                        state.sm_state = 0;
                    } else {
                        state.pkg[state.pkg_pos] = ch;
                        state.pkg_pos++;
                    }
                }
                break;
            }
            default: {
                state.sm_state = 0;
                break;
            }
        }
    }
}
