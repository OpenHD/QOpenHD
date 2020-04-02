/* #################################################################################################################
/ Vector Open Telemetry Revision 0
// NOTES:
// 1) UART protocol is 8N1 (8 bits, no parity bit, 1 stop bit), 57600 baud, 3.3V input/outputs levels (input is NOT 5V tolerant!)
// 2) all fields BIG-ENDIAN byte order
// 3) The VECTOR_OPEN_TELEMETRY packet is sent as frequently as every 80mS, but timing will vary considerably
// 4) To enable telemetry output on the Vector's UART port, select the "Open Telm" option
//    for the "Configure the UART port for" stick menu item, under the ""EagleEyes and Telemetry" OSD menu

// Vector UART Pinout (using standard Vector "BUS" cable colors):
// Yellow: RX (Receive data TO the Vector - note that this connection is not needed)
// Orange: TX (Transmit data FROM the Vector)
// Black: Ground
// Red: 5V Out, 150mA max (from Vector PSU or backup power input - do not exceed 1A total load on Vector PSU! Don't connect this wire unless the device receiving the telemetry requires power from the Vector)
// IMPORTANT: NEVER connect the telemetry cable to any Vector port other than UART!  Doing so can damage your equipment!

/*THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION. NO WARRANTIES,
 * WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
 * TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
 * IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
 * CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 *
 * ################################################################################################################# */



#include "vectortelemetry.h"
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

#define VOTFrameLength 97 // 97 bytes
#define VOT_REVISION 0
#define VOT_SC1  0xB0
#define VOT_SC2  0x1E
#define VOT_SC3  0xDE
#define VOT_SC4  0xAD
#define VOT_CRC_Init 0xFFFF


typedef struct {
    uint32_t StartCode;            //  0xB01EDEAD
    uint32_t TimestampMS;          // -not used- timestamp in milliseconds
    signed long BaroAltitudecm;    // -fl baro_altitude- zero referenced (from home position) barometric altitude in cm
    uint16_t AirspeedKPHX10;       // -fl airspeed- KPH * 10, requires optional pitot sensor
    int16_t ClimbRateMSX100;       // -fl vario - meters/second * 100
    uint16_t RPM;                  // -not used- requires optional RPM sensor
    int16_t PitchDegrees;          // -i16 pitch-
    int16_t RollDegrees;           // -i16 roll-
    int16_t YawDegrees;            // -fl heading-
    int16_t AccelXCentiGrav;       // -not used-
    int16_t AccelYCentiGrav;       // -not used-
    int16_t AccelZCentiGrav;       // -not used-
    uint16_t PackVoltageX100;      // -fl voltage-
    uint16_t VideoTxVoltageX100;   // -fl vtxvoltage
    uint16_t CameraVoltageX100;    // -fl camvoltage
    uint16_t RxVoltageX100;	       // -fl rxvoltage
    uint16_t PackCurrentX10;       // -fl ampere-
    int16_t TempDegreesCX10;       // -i16 temp- degrees C * 10, from optional temperature sensor
    uint16_t mAHConsumed;          // -u16 mahconsumed-
    uint16_t CompassDegrees;       // -u16 compassdegrees used- either magnetic compass reading (if compass enabled) or filtered GPS course over ground if not
    uint8_t RSSIPercent;           // -u8 rssi-
    uint8_t LQPercent;             // -u8 LQ-
    signed long LatitudeX1E7;      // -dbl latitude- (degrees * 10,000,000 )
    signed long LongitudeX1E7;     // -dbl longitude- (degrees * 10,000,000 )
    uint32_t DistanceFromHomeMX10; // -fl distance- horizontal GPS distance from home point, in meters X 10 (decimeters)
    uint16_t GroundspeedKPHX10;    // -fl speed- ( km/h * 10 )
    uint16_t CourseDegrees;        // -u16 coursedegrees- GPS course over ground, in degrees
    signed long GPSAltitudecm;     // -fl altitude- ( GPS altitude, using WGS-84 ellipsoid, cm)
    uint8_t HDOPx10;               // -fl hdop- GPS HDOP * 10
    uint8_t SatsInUse;             // -u8 sats- satellites used for navigation
    uint8_t PresentFlightMode;     // -u8 uav_flightmode- present flight mode, as defined in VECTOR_FLIGHT_MODES
    uint8_t RFU[24];               // -not used- reserved for future use
    uint16_t CRC;
} VOT_td_t; //97 bytes


VectorTelemetry::VectorTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "VectorTelemetry::VectorTelemetry()";
    init();

}

void VectorTelemetry::init() {
    qDebug() << "VectorTelemetry::init()";
    vectorSocket = new QUdpSocket(this);
    // port defined in global_functions.sh on ground
    vectorSocket->bind(QHostAddress::Any, 5011);
    connect(vectorSocket, &QUdpSocket::readyRead, this, &VectorTelemetry::processVectorDatagrams);
}


void VectorTelemetry::processVectorDatagrams() {
    QByteArray datagram;

    while (vectorSocket->hasPendingDatagrams()) {
        datagram.resize(int(vectorSocket->pendingDatagramSize()));
        vectorSocket->readDatagram(datagram.data(), datagram.size());
        vot_read((uint8_t*)datagram.data(), datagram.length());
    }
}


void VectorTelemetry::processVectorMessage() {
    uint16_t dummy16;
    uint32_t dummy32;

    VOTReadIndex = 0;

    dummy32 = (uint32_t)votread_u32(); // StartCode
    dummy32 = (uint32_t)votread_u32(); // TimeStamp
    auto rel_altitude = (float)(signed long) votbread_u32() / 100.0f; // BaroAltitudecm

    OpenHD::instance()->set_alt_rel(rel_altitude);

    auto airspeed  = (float)(uint16_t)votbread_u16() / 10.0f; // airspeed
    OpenHD::instance()->set_airspeed(airspeed);

    auto vario = (float)(uint16_t)votbread_u16() / 100.0f; // ClimbRateMSX100 -not used- meters/second * 100
    auto rpm = (uint16_t)votbread_u16(); // RPM - requires optional RPM sensor

    auto pitch = (int16_t)votbread_u16(); // PitchDegrees-pitch-
    OpenHD::instance()->set_pitch(pitch);

    auto roll = (int16_t)votbread_u16(); // RollDegrees-roll-
    OpenHD::instance()->set_roll(roll);

    auto heading = (float)(int16_t)votbread_u16(); // YawDegrees-heading-
    OpenHD::instance()->set_hdg(heading);

    auto x  = (int16_t)votbread_u16(); // AccelXCentiGrav-not used-
    auto y  = (int16_t)votbread_u16(); // AccelZCentiGrav -not used-
    auto z  = (int16_t)votbread_u16(); // AccelXCentiGrav-not used-
    OpenHD::instance()->set_vx(x);
    OpenHD::instance()->set_vy(y);
    OpenHD::instance()->set_vz(z);

    auto battery_voltage = (float)(uint16_t)votbread_u16() / 100.0f; // PackVoltageX100 -voltage-
    auto vtxvoltage      = (float)(uint16_t)votbread_u16() / 100.0f; // VideoTxVoltageX100-vtxvoltage-
    auto camvoltage      = (float)(uint16_t)votbread_u16() / 100.0f; // CameraVoltageX100-camvoltage-
    auto rxvoltage       = (float)(uint16_t)votbread_u16() / 100.0f; // RxVoltageX100-rxvoltage-
    auto ampere          = (float)(uint16_t)votbread_u16() / 10.0f;  // PackCurrentX10-ampere-
    OpenHD::instance()->set_battery_voltage(battery_voltage);
    OpenHD::instance()->set_battery_current(ampere);


    QSettings settings;
    auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();
    int battery_percent = lipo_battery_voltage_to_percent(battery_cells, battery_voltage);
    OpenHD::instance()->set_battery_percent(battery_percent);
    QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
    OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);


    dummy16 = (uint16_t)votbread_u16(); // TempDegreesCX10-- degrees C * 10, from optional temperature sensor
    dummy16 = (uint16_t)votbread_u16(); // mAHConsumed-not used-
    dummy16 = (uint16_t)votbread_u16(); // CompassDegrees-not used- either magnetic compass reading (if compass enabled) or filtered GPS course over ground if not
    auto rssi = (uint8_t)votread_u8();  // RSSIPercent-rssi-
    auto lq   = (uint8_t)votread_u8();  // LQPercent-not used-

    auto latitude = (double)(int32_t)votbread_u32() / 10000000; // -latitude- (degrees * 10,000,000 )
    OpenHD::instance()->set_lat(latitude);

    auto longitude = (double)(int32_t)votbread_u32() / 10000000; // -longitude- (degrees * 10,000,000 )
    OpenHD::instance()->set_lon(longitude);


    // qopenhd doesn't use these because we calculate home when the drone is armed based on current location
    auto distance = (float)(uint32_t)votbread_u32() / 10.0f; // DistanceFromHomeMX10 horizontal GPS distance from home point, in meters X 10 (decimeters)

    auto speed = (float)(uint16_t)votbread_u16() / 10.0f; // -speed- ( km/h * 10 )
    OpenHD::instance()->set_speed(speed);

    auto coursedegrees = (uint16_t)votbread_u16(); // CourseDegrees -not used- GPS course over ground, in degrees
    auto gps_altitude = (float)(int32_t)votbread_u32() / 100.0f; // -altitude- ( GPS altitude, using WGS-84 ellipsoid, cm)
    OpenHD::instance()->set_alt_msl(gps_altitude);


    auto hdop = (float)(uint8_t)votread_u8(); // -HDOPx10- GPS HDOP * 10
    auto sats = (uint8_t)votread_u8(); // -SatsInUse- satellites used for navigation
    OpenHD::instance()->set_gps_hdop(hdop);
    OpenHD::instance()->set_satellites_visible(sats);


    auto _flightmode = (uint8_t)votread_u8(); // PresentFlightMode -uav_flightmode- present flight mode, as defined in VECTOR_FLIGHT_MODES
    QString flightmode = vot_mode_from_telemetry(_flightmode);
    OpenHD::instance()->set_flight_mode(flightmode);

    OpenHD::instance()->calculate_home_distance();
    OpenHD::instance()->calculate_home_course();

    VOTReadIndex = 0;
}


void VectorTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}



static union {
   uint8_t SerialBuffer[sizeof(VOT_td_t)];
   VOT_td_t td;  //unfortunately, this doesn't work because of the damn Endians..
} v;


uint8_t VectorTelemetry::votread_u8()  {
    return v.SerialBuffer[VOTReadIndex++];
}


uint16_t VectorTelemetry::votread_u16() {
    uint16_t t = votread_u8();
    t |= (uint16_t)votread_u8()<<8;
    return t;
}


uint16_t VectorTelemetry::votbread_u16() {
    uint16_t t = votread_u8()<<8;
    t |= votread_u8();
    return t;
}


uint32_t VectorTelemetry::votread_u32() {
    uint32_t t = votread_u16();
    t |= (uint32_t)votread_u16()<<16;
    return t;
}

uint32_t VectorTelemetry::votbread_u32() {
    uint32_t t = votbread_u16()<<16;
    t |= votbread_u16();
    return t;
}


// sample code for calculating the CRC
// OpenTelem.CRC == CalculateCRC((UINT8 *)&OpenTelem, offsetof(VECTOR_OPEN_TELEMETRY, CRC), VTELEM_CRC_INIT);

uint16_t VectorTelemetry::CRC16Worker(uint16_t icrc, uint8_t r0) {
    union {
        uint16_t crc16; // 16-bit CRC
        struct {
            uint8_t crcl, crch;
        } s;
    } u;

    uint8_t a1; // scratch byte
    u.crc16 = icrc;
    r0 = r0 ^ u.s.crch;
    a1 = u.s.crcl;
    u.s.crch = r0;
    u.s.crch = (u.s.crch << 4) | (u.s.crch >> 4);
    u.s.crcl = u.s.crch ^ r0;
    u.crc16 &= 0x0ff0;
    r0 ^= u.s.crch;
    a1 ^= u.s.crcl;
    u.crc16 <<= 1;
    u.s.crcl ^= r0;
    u.s.crch ^= a1;
    return (u.crc16);
}


uint16_t VectorTelemetry::CalculateCRC(uint8_t * pPacket, uint8_t Size, uint16_t InitCRC) {
    uint16_t i;
    uint16_t CRC;
    CRC = InitCRC;
    for (i = 0; i < Size; i++) {
        CRC = CRC16Worker(CRC, pPacket[i]);
    }
    return CRC;
}


void VectorTelemetry::vot_read(uint8_t *buf, uint8_t buflen) {
    int i;
    uint8_t c;
    uint16_t cs;

    for (i = 0; i < buflen; ++i) {
        uint8_t c = buf[i];

        if (c_state == IDLE) {
            c_state = (c == VOT_SC1) ? HEADER_START1 : IDLE;
            VOTReceiverIndex=0;
        } else if (c_state == HEADER_START1) {
            c_state = (c == VOT_SC2) ? HEADER_START2 : IDLE;
        } else if (c_state == HEADER_START2) {
            c_state = (c == VOT_SC3) ? HEADER_START3 : IDLE;
        } else if (c_state == HEADER_START3) {
            c_state = (c == VOT_SC4) ? HEADER_START4 : IDLE;
        } else if (c_state == HEADER_START4) {
            c_state = HEADER_MSGTYPE;
        }

        if (c_state != IDLE) {
            v.SerialBuffer[VOTReceiverIndex++] = c;
            if (VOTReceiverIndex == VOTFrameLength) {
                // received checksum word little endian
                VOTRcvChecksum = CalculateCRC((uint8_t *)&v.SerialBuffer[0], 95, 0xFFFF);
                cs = (uint16_t)(v.SerialBuffer[VOTFrameLength-1] << 8) + v.SerialBuffer[VOTFrameLength-2];
                if (VOTRcvChecksum == cs) {
                    processVectorMessage();
                    c_state = IDLE;
                } else  {
                    // wrong checksum, drop packet
                    c_state = IDLE;
                }
            } else {

            }
        }
    } //next i
    return;
}
