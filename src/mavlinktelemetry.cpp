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

#if defined(ENABLE_SPEECH)
    m_speech = new QTextToSpeech(this);
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
                set_armed(true);
            } else {
                set_armed(false);
            }
            auto custom_mode = heartbeat.custom_mode;

            auto uav_type = heartbeat.type;
            switch (uav_type) {
                case MAV_TYPE_GENERIC: {
                    break;
                }
                case MAV_TYPE_FIXED_WING: {
                    auto plane_mode = plane_mode_from_enum((PLANE_MODE)custom_mode);
                    set_flight_mode(plane_mode);
                    break;
                }
                case MAV_TYPE_GROUND_ROVER: {
                    auto rover_mode = rover_mode_from_enum((ROVER_MODE)custom_mode);
                    set_flight_mode(rover_mode);
                    break;
                }
                case MAV_TYPE_COAXIAL:
                case MAV_TYPE_HELICOPTER:
                case MAV_TYPE_HEXAROTOR:
                case MAV_TYPE_OCTOROTOR:
                case MAV_TYPE_TRICOPTER:
                case MAV_TYPE_QUADROTOR: {
                    auto copter_mode = copter_mode_from_enum((COPTER_MODE)custom_mode);
                    set_flight_mode(copter_mode);
                    break;
                }
                case MAV_TYPE_SURFACE_BOAT:
                case MAV_TYPE_SUBMARINE: {
                    auto sub_mode = sub_mode_from_enum((SUB_MODE)custom_mode);
                    set_flight_mode(sub_mode);
                    break;
                }
                case MAV_TYPE_ANTENNA_TRACKER: {
                    auto tracker_mode = tracker_mode_from_enum((TRACKER_MODE)custom_mode);
                    //set_tracker_mode(tracker_mode);
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

            set_battery_voltage_raw((double)sys_status.voltage_battery / 1000.0);
            set_battery_voltage(tr("%1%2").arg(m_battery_voltage_raw, 3, 'f', 1, '0').arg("V"));
            set_battery_current(tr("%1%2").arg((double)sys_status.current_battery / 1000.0, 3, 'f', 1, '0').arg("A"));

            QSettings settings;
            auto battery_cells = settings.value("battery_cells", QVariant(3)).toInt();

            int battery_percent = battery_voltage_to_percent(battery_cells, m_battery_voltage_raw);
            set_battery_percent(QString("%1%").arg(battery_percent));
            QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
            set_battery_gauge(battery_gauge_glyph);
            break;
        }
        case MAVLINK_MSG_ID_SYSTEM_TIME:
            break;
        case MAVLINK_MSG_ID_PARAM_VALUE:
            break;
        case MAVLINK_MSG_ID_GPS_RAW_INT:
            mavlink_gps_raw_int_t gps_status;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_status);
            set_satellites_visible(tr("%1").arg(gps_status.satellites_visible));
            set_gps_hdop(tr("%1").arg((double)gps_status.eph / 100.0));

            break;
        case MAVLINK_MSG_ID_GPS_STATUS: {
            break;
        }
        case MAVLINK_MSG_ID_RAW_IMU:
        case MAVLINK_MSG_ID_SCALED_PRESSURE:
        case MAVLINK_MSG_ID_ATTITUDE:
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:
            break;
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

            set_homelat(tr("%1").arg((double)global_position.lat / 10000000.0, 2, 'f', 6, '1'));
            set_homelon(tr("%1").arg((double)global_position.lon / 10000000.0, 2, 'f', 6, '1'));

            set_boot_time(tr("%1").arg(global_position.time_boot_ms));

            set_alt_rel(tr("%1").arg(global_position.relative_alt/1000.0));
            set_alt_msl(tr("%1").arg(global_position.alt/1000.0));

            // FOR INAV heading does not /100
            set_hdg(tr("%1").arg(global_position.hdg/100.0));

            set_vx(tr("%1").arg(global_position.vx/100.0));
            set_vy(tr("%1").arg(global_position.vy/100.0));
            set_vz(tr("%1").arg(global_position.vz/100.0));

            break;
        }
        case MAVLINK_MSG_ID_RC_CHANNELS_RAW:
            break;
        case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:
        case MAVLINK_MSG_ID_MISSION_CURRENT:
        case MAVLINK_MSG_ID_GPS_GLOBAL_ORIGIN:
        case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:
            break;
        case MAVLINK_MSG_ID_RC_CHANNELS:
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
        case MAVLINK_MSG_ID_VFR_HUD:
        case MAVLINK_MSG_ID_TIMESYNC:
            break;
        case MAVLINK_MSG_ID_POWER_STATUS:
        case MAVLINK_MSG_ID_TERRAIN_REPORT:
            break;
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
        case MAVLINK_MSG_ID_VIBRATION:
            break;
        case MAVLINK_MSG_ID_HOME_POSITION:
            break;
        case MAVLINK_MSG_ID_STATUSTEXT: {
            mavlink_statustext_t statustext;
            mavlink_msg_statustext_decode(&msg, &statustext);
            QSettings settings;
            auto enable_speech = settings.value("enable_speech", QVariant(0));
            auto speak_error = false;
            int level = 0;
            switch (statustext.severity) {
                case MAV_SEVERITY_EMERGENCY:
                    qDebug() << "EMER:" << statustext.text;
                    level = 7;
                    speak_error = true;
                    break;
                case MAV_SEVERITY_ALERT:
                    qDebug() << "ALERT:" <<  statustext.text;
                    level = 6;
                    speak_error = true;
                    break;
                case MAV_SEVERITY_CRITICAL:
                    qDebug() << "CRIT:" <<  statustext.text;
                    level = 5;
                    speak_error = true;
                    break;
                case MAV_SEVERITY_ERROR:
                    qDebug() << "ERROR:" <<  statustext.text;
                    level = 4;
                    speak_error = true;
                    break;
                case MAV_SEVERITY_WARNING:
                    qDebug() << "WARN:" <<  statustext.text;
                    level = 3;
                    speak_error = true;
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

#if defined(ENABLE_SPEECH)
            if (enable_speech == 1 && speak_error) {
                m_speech->say(statustext.text);
            }
#endif
            emit messageReceived(statustext.text, level);
            break;
        }
        default: {
            printf("Received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }

    emit mavlink_msg_received(msg);
}

void MavlinkTelemetry::set_boot_time(QString boot_time) {
    m_boot_time = boot_time;
    emit boot_time_changed(m_boot_time);
}

void MavlinkTelemetry::set_alt_rel(QString alt_rel) {
    m_alt_rel = alt_rel;
    emit alt_rel_changed(m_alt_rel);
}

void MavlinkTelemetry::set_alt_msl(QString alt_msl) {
    m_alt_msl = alt_msl;
    emit alt_msl_changed(m_alt_msl);
}

void MavlinkTelemetry::set_vx(QString vx) {
    m_vx = vx;
    emit vx_changed(m_vx);
}

void MavlinkTelemetry::set_vy(QString vy) {
    m_vy = vy;
    emit vy_changed(m_vy);
}

void MavlinkTelemetry::set_vz(QString vz) {
    m_vz = vz;
    emit vz_changed(m_vz);
}

void MavlinkTelemetry::set_hdg(QString hdg) {
    m_hdg = hdg;
    emit hdg_changed(m_hdg);
}

void MavlinkTelemetry::set_armed(bool armed) {
#if defined(ENABLE_SPEECH)
    QSettings settings;
    auto enable_speech = settings.value("enable_speech", QVariant(0));

    if (enable_speech == 1) {
        if (armed && !m_armed) {
            m_speech->say("armed");
        } else if (!armed && m_armed) {
            m_speech->say("disarmed");
        }
    }
#endif

    m_armed = armed;
    emit armed_changed(m_armed);
}

void MavlinkTelemetry::set_flight_mode(QString flight_mode) {
#if defined(ENABLE_SPEECH)
    if (m_flight_mode != flight_mode) {
        m_speech->say(tr("%1 flight mode").arg(flight_mode));
    }
#endif
    m_flight_mode = flight_mode;

    emit flight_mode_changed(m_flight_mode);
}

void MavlinkTelemetry::set_homelat(QString homelat) {
    m_homelat = homelat;
    emit homelat_changed(m_homelat);
}

void MavlinkTelemetry::set_homelon(QString homelon) {
    m_homelon = homelon;
    emit homelon_changed(m_homelon);
}

void MavlinkTelemetry::set_battery_percent(QString battery_percent) {
    m_battery_percent = battery_percent;
    emit battery_percent_changed(m_battery_percent);
}

void MavlinkTelemetry::set_battery_voltage(QString battery_voltage) {
    m_battery_voltage = battery_voltage;
    emit battery_voltage_changed(m_battery_voltage);
}

void MavlinkTelemetry::set_battery_voltage_raw(double battery_voltage_raw) {
    m_battery_voltage_raw = battery_voltage_raw;
    emit battery_voltage_raw_changed(m_battery_voltage_raw);
}

void MavlinkTelemetry::set_battery_current(QString battery_current) {
    m_battery_current = battery_current;
    emit battery_current_changed(m_battery_current);
}

void MavlinkTelemetry::set_battery_gauge(QString battery_gauge) {
    m_battery_gauge = battery_gauge;
    emit battery_gauge_changed(m_battery_gauge);
}

void MavlinkTelemetry::set_satellites_visible(QString satellites_visible) {
    m_satellites_visible = satellites_visible;
    emit satellites_visible_changed(m_satellites_visible);
}

void MavlinkTelemetry::set_gps_hdop(QString gps_hdop) {
    m_gps_hdop = gps_hdop;
    emit gps_hdop_changed(m_gps_hdop);
}

void MavlinkTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}

void MavlinkTelemetry::set_pitch_raw(double pitch_raw) {
    m_pitch_raw = pitch_raw;
    emit pitch_raw_changed(m_pitch_raw);
}

void MavlinkTelemetry::set_roll_raw(double roll_raw) {
    m_roll_raw = roll_raw;
    emit roll_raw_changed(m_roll_raw);
}

void MavlinkTelemetry::set_yaw_raw(double yaw_raw) {
    m_yaw_raw = yaw_raw;
    emit yaw_raw_changed(m_yaw_raw);
}

QObject *mavlinkTelemetrySingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    MavlinkTelemetry *s = new MavlinkTelemetry();
    return s;
}
