#include "mavlinktelemetry.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include <common/mavlink.h>
#include <ardupilotmega/ardupilotmega.h>

#include "util.h"
#include "constants.h"

#include "openhd.h"

MavlinkTelemetry::MavlinkTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "MavlinkTelemetry::MavlinkTelemetry()";
    init();

}

void MavlinkTelemetry::init() {
    qDebug() << "MavlinkTelemetry::init()";
#if defined(__rasp_pi__)
    restartFifo();
#else
    mavlinkSocket = new QUdpSocket(this);
    mavlinkSocket->bind(QHostAddress::Any, 14550);
    connect(mavlinkSocket, &QUdpSocket::readyRead, this, &MavlinkTelemetry::processMavlinkDatagrams);
#endif
}


#if defined(__rasp_pi__)
void MavlinkTelemetry::restartFifo() {
    qDebug() << "MavlinkTelemetry::restartFifo()";
    fifoFuture = QtConcurrent::run(this, &MavlinkTelemetry::processMavlinkFifo);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &MavlinkTelemetry::restartFifo);
    connect(&watcher, &QFutureWatcherBase::finished, this, &MavlinkTelemetry::restartFifo);
    watcher.setFuture(fifoFuture);
}

void MavlinkTelemetry::processMavlinkFifo() {
    uint8_t buf[4096];

    mavlink_message_t msg;

    int fifoFP = open(MAVLINK_FIFO, O_RDONLY);
    if (fifoFP < 0) {
        QThread::msleep(1000);
        return;
    }

    while (true) {
        int received = read(fifoFP, buf, sizeof(buf));
        if (received < 0) {
            qDebug() << "Mavlink fifo returned -1";

            close(fifoFP);
            QThread::msleep(1000);
            return;
        }
        for (int i = 0; i < received; i++) {
            uint8_t c = buf[i];
            uint8_t res = mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &r_mavlink_status);

            if (res) {
                processMavlinkMessage(msg);
            }
        }
    }
    QThread::msleep(1000);
    close(fifoFP);
}
#else
void MavlinkTelemetry::processMavlinkDatagrams() {
    QByteArray datagram;

    while (mavlinkSocket->hasPendingDatagrams()) {
        datagram.resize(int(mavlinkSocket->pendingDatagramSize()));
        mavlinkSocket->readDatagram(datagram.data(), datagram.size());
        typedef QByteArray::Iterator Iterator;
        mavlink_message_t msg;

        for (Iterator i = datagram.begin(); i != datagram.end(); i++) {
            char c = *i;

            uint8_t res = mavlink_parse_char(MAVLINK_COMM_0, (uint8_t)c, &msg, &r_mavlink_status);

            if (res) {
                processMavlinkMessage(msg);
            }
        }
    }
}
#endif

void MavlinkTelemetry::processMavlinkMessage(mavlink_message_t msg) {
    switch (msg.msgid) {
            case MAVLINK_MSG_ID_HEARTBEAT: {
                    mavlink_heartbeat_t heartbeat;
                    mavlink_msg_heartbeat_decode(&msg, &heartbeat);
                    //MAV_STATE state = (MAV_STATE)heartbeat.system_status;
                    MAV_MODE_FLAG mode = (MAV_MODE_FLAG)heartbeat.base_mode;

                    if (mode & MAV_MODE_FLAG_SAFETY_ARMED) {
                        // armed
                        OpenHD::instance()->set_armed(true);
                        } else {
                        OpenHD::instance()->set_armed(false);
                    }

                    auto custom_mode = heartbeat.custom_mode;

                    auto uav_type = heartbeat.type;

                    switch (uav_type) {
                        case MAV_TYPE_GENERIC: {
                        break;
                        }
                        case MAV_TYPE_FIXED_WING: {
                            auto plane_mode = plane_mode_from_enum((PLANE_MODE)custom_mode);
                            OpenHD::instance()->set_flight_mode(plane_mode);
                        break;
                        }
                        case MAV_TYPE_GROUND_ROVER: {
                            auto rover_mode = rover_mode_from_enum((ROVER_MODE)custom_mode);
                            OpenHD::instance()->set_flight_mode(rover_mode);
                        break;
                        }
                        case MAV_TYPE_QUADROTOR: {
                            auto copter_mode = copter_mode_from_enum((COPTER_MODE)custom_mode);
                            OpenHD::instance()->set_flight_mode(copter_mode);
                        break;
                        }
                        case MAV_TYPE_SUBMARINE: {
                            auto sub_mode = sub_mode_from_enum((SUB_MODE)custom_mode);
                            OpenHD::instance()->set_flight_mode(sub_mode);
                        break;
                        }
                        case MAV_TYPE_ANTENNA_TRACKER: {
                            auto tracker_mode = tracker_mode_from_enum((TRACKER_MODE)custom_mode);
                            //OpenHD::instance()->set_tracker_mode(tracker_mode);
                        break;
                        }
                        default: {
                            // do nothing
                        }
                    }

                    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

                    set_last_heartbeat(QString(tr("%1s").arg(current_timestamp - last_heartbeat_timestamp)));
                    last_heartbeat_timestamp = current_timestamp;
                    break;
                }

        case MAVLINK_MSG_ID_SYS_STATUS: {
            mavlink_sys_status_t sys_status;
            mavlink_msg_sys_status_decode(&msg, &sys_status);

            auto battery_voltage_raw = (double)sys_status.voltage_battery / 1000.0;
            OpenHD::instance()->set_battery_voltage_raw(battery_voltage_raw);
            OpenHD::instance()->set_battery_voltage(tr("%1%2").arg(battery_voltage_raw, 3, 'f', 1, '0').arg("V"));
            OpenHD::instance()->set_battery_current(tr("%1%2").arg((double)sys_status.current_battery / 1000.0, 3, 'f', 1, '0').arg("A"));

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = battery_voltage_to_percent(battery_cells, battery_voltage_raw);
            OpenHD::instance()->set_battery_percent(QString("%1%").arg(battery_percent));
            QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
            OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            break;
        }
        case MAVLINK_MSG_ID_PARAM_VALUE:{
            break;
        }
        case MAVLINK_MSG_ID_GPS_RAW_INT:{
            mavlink_gps_raw_int_t gps_status;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
            OpenHD::instance()->set_satellites_visible(tr("%1").arg(gps_status.satellites_visible));
            OpenHD::instance()->set_gps_hdop(tr("%1").arg((double)gps_status.eph / 100.0));
            break;
        }
        case MAVLINK_MSG_ID_GPS_STATUS: {
            break;
        }
        case MAVLINK_MSG_ID_RAW_IMU:{
            break;
        }
        case MAVLINK_MSG_ID_SCALED_PRESSURE:{
            break;
        }
        case MAVLINK_MSG_ID_ATTITUDE:{
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode (&msg, &attitude);

            OpenHD::instance()->set_pitch_raw((float)attitude.pitch *57.2958);
            qDebug() << "Pitch:" <<  attitude.pitch*57.2958;

            OpenHD::instance()->set_roll_raw((float)attitude.roll *57.2958);
            qDebug() << "Roll:" <<  attitude.roll*57.2958;
            break;
        }
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
            break;
        }
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

            OpenHD::instance()->set_lat(tr("%1").arg((double)global_position.lat / 10000000.0, 2, 'f', 6, '1'));
            OpenHD::instance()->set_lon(tr("%1").arg((double)global_position.lon / 10000000.0, 2, 'f', 6, '1'));

            OpenHD::instance()->set_boot_time(tr("%1").arg(global_position.time_boot_ms));

            OpenHD::instance()->set_alt_rel(tr("%1").arg(global_position.relative_alt/1000.0));
          //  qDebug() << "Altitude relative " << alt_rel;
            OpenHD::instance()->set_alt_msl(tr("%1").arg(global_position.alt/1000.0));

            // FOR INAV heading does not /100
            OpenHD::instance()->set_hdg(tr("%1").arg(global_position.hdg/100.0));

            OpenHD::instance()->set_vx(tr("%1").arg(global_position.vx/100.0));
            OpenHD::instance()->set_vy(tr("%1").arg(global_position.vy/100.0));
            OpenHD::instance()->set_vz(tr("%1").arg(global_position.vz/100.0));

            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:{
            break;
        }
        case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:{
            break;
        }
        case MAVLINK_MSG_ID_MISSION_CURRENT:{
            break;
        }
        case MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN:{
            break;
        }
        case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:{
            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS:{
            mavlink_rc_channels_t rc_channels;
            mavlink_msg_rc_channels_decode(&msg, &rc_channels);
            /*qDebug() << "RC: " << rc_channels.chan1_raw
                                           << rc_channels.chan2_raw
                                           << rc_channels.chan3_raw
                                           << rc_channels.chan4_raw
                                           << rc_channels.chan5_raw
                                           << rc_channels.chan6_raw
                                           << rc_channels.chan7_raw
                                           << rc_channels.chan8_raw
                                           << rc_channels.chan9_raw
                                           << rc_channels.chan10_raw;*/
            break;
        }
        case MAVLINK_MSG_ID_VFR_HUD:{
            mavlink_vfr_hud_t vfr_hud;
            mavlink_msg_vfr_hud_decode (&msg, &vfr_hud);

            //OpenHD::instance()->set_throttle(tr("%1").arg(vfr_hud.throttle));
            break;
        }
        case MAVLINK_MSG_ID_TIMESYNC:{
            break;
        }
        case MAVLINK_MSG_ID_POWER_STATUS:{
            break;
        }
        case MAVLINK_MSG_ID_TERRAIN_REPORT:{
            break;
        }
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery_status;
            mavlink_msg_battery_status_decode(&msg, &battery_status);
            int total_voltage = 0;
            for (int cell = 0; cell < 10; cell++) {
                int cell_voltage  = battery_status.voltages[cell];
                if (cell_voltage != UINT16_MAX) {
                    qDebug() << "Battery cell voltage " << cell << " :" << cell_voltage;

                    total_voltage += cell_voltage;
                }
            }
            break;
        }
        case MAVLINK_MSG_ID_VIBRATION:{
            break;
        }
        case MAVLINK_MSG_ID_HOME_POSITION:{
            mavlink_home_position_t home_position;
            mavlink_msg_home_position_decode(&msg, &home_position);
            OpenHD::instance()->set_homelat(tr("%1").arg((double)home_position.latitude / 10000000.0, 2, 'f', 6, '1'));
            OpenHD::instance()->set_homelon(tr("%1").arg((double)home_position.longitude / 10000000.0, 2, 'f', 6, '1'));
            break;
        }
        case MAVLINK_MSG_ID_STATUSTEXT: {
            mavlink_statustext_t statustext;
            mavlink_msg_statustext_decode(&msg, &statustext);
            int level = 0;
            switch (statustext.severity) {
                case MAV_SEVERITY_EMERGENCY:
                    qDebug() << "EMER:" << statustext.text;
                    level = 7;
                    break;
                case MAV_SEVERITY_ALERT:
                    qDebug() << "ALERT:" <<  statustext.text;
                    level = 6;
                    break;
                case MAV_SEVERITY_CRITICAL:
                    qDebug() << "CRIT:" <<  statustext.text;
                    level = 5;
                    break;
                case MAV_SEVERITY_ERROR:
                    qDebug() << "ERROR:" <<  statustext.text;
                    level = 4;
                    break;
                case MAV_SEVERITY_WARNING:
                    qDebug() << "WARN:" <<  statustext.text;
                    level = 3;
                    break;
                case MAV_SEVERITY_NOTICE:
                    level = 2;
                    break;
                case MAV_SEVERITY_INFO:
                    level = 1;
                    break;
                case MAV_SEVERITY_DEBUG:
                    level = 0;
                    break;
                default:
                    break;
            }

            OpenHD::instance()->messageReceived(statustext.text, level);
            break;
        }
        default: {
            printf("Received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}

void MavlinkTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
