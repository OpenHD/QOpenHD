#include "mavlinktelemetry.h"
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

#include <openhd/mavlink.h>

#include "util.h"
#include "constants.h"

#include "openhd.h"
#include "openhdpower.h"

#include "localmessage.h"

#define MAVLINK_LOCAL_PORT 14550

MavlinkTelemetry::MavlinkTelemetry(QObject *parent): QObject(parent), m_ground_available(false) {
    qDebug() << "MavlinkTelemetry::MavlinkTelemetry()";
    init();
}

void MavlinkTelemetry::init() {
    qDebug() << "MavlinkTelemetry::init()";

    mavlinkSocket = new QUdpSocket(this);
    mavlinkSocket->bind(QHostAddress::Any, MAVLINK_LOCAL_PORT);
    connect(mavlinkSocket, &QUdpSocket::readyRead, this, &MavlinkTelemetry::processMavlinkDatagrams);

    QFuture<void> future = QtConcurrent::run(this, &MavlinkTelemetry::stateLoop);
}


void MavlinkTelemetry::setGroundIP(QString address) {
    groundAddress = address;
}

void MavlinkTelemetry::set_loading(bool loading) {
    m_loading = loading;
    emit loadingChanged(m_loading);
}

void MavlinkTelemetry::set_saving(bool saving) {
    m_saving = saving;
    emit savingChanged(m_saving);
}

void MavlinkTelemetry::processMavlinkDatagrams() {
    QByteArray datagram;

    while (mavlinkSocket->hasPendingDatagrams()) {
        m_ground_available = true;

        datagram.resize(int(mavlinkSocket->pendingDatagramSize()));
        QHostAddress _groundAddress;
        quint16 _groundPort;
        mavlinkSocket->readDatagram(datagram.data(), datagram.size(), &_groundAddress, &_groundPort);
        groundPort = _groundPort;
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


QVariantMap MavlinkTelemetry::getAllParameters() {
    return m_allParameters;
}


void MavlinkTelemetry::fetchParameters() {
    qDebug() << "MavlinkTelemetry::fetchParameters()";
    mavlink_message_t msg;
    mavlink_msg_param_request_list_pack(255, MAV_COMP_ID_MISSIONPLANNER, &msg, 1, MAV_COMP_ID_AUTOPILOT1);

    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    int len = mavlink_msg_to_send_buffer(buffer, &msg);

    mavlinkSocket->writeDatagram((char*)buffer, len, QHostAddress(groundAddress), groundPort);
}


bool MavlinkTelemetry::isConnectionLost() {
    // we want to know if a heartbeat has been received (not -1, the default)
    // but not in the last 5 seconds.
    if (m_last_heartbeat_raw > -1 && m_last_heartbeat_raw < 5000) {
        return false;
    }
    return true;
}

void MavlinkTelemetry::resetParamVars() {
    m_allParameters.clear();
    parameterCount = 0;
    parameterIndex = 0;
    initialConnectTimer = -1;
    // give the MavlinkStateGetParameters state a chance to receive a parameter
    // before timing out
    parameterLastReceivedTime = QDateTime::currentMSecsSinceEpoch();
}


void MavlinkTelemetry::stateLoop() {

    resetParamVars();

    while (true) {
        QThread::msleep(200);

        QMutexLocker locker(&stateLock);

        qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
        m_last_heartbeat_raw = current_timestamp - last_heartbeat_timestamp;
        set_last_heartbeat(QString(tr("%1ms").arg(m_last_heartbeat_raw)));

        switch (state) {
            case MavlinkStateDisconnected: {
                set_loading(false);
                set_saving(false);
                if (m_ground_available) {
                    state = MavlinkStateConnected;
                }

                continue;
            }
            case MavlinkStateConnected: {
                if (initialConnectTimer == -1) {
                    initialConnectTimer = QDateTime::currentMSecsSinceEpoch();
                } else if (current_timestamp - initialConnectTimer < 5000) {
                    state = MavlinkStateGetParameters;
                    resetParamVars();
                    fetchParameters();
                    LocalMessage::instance()->showMessage("Connecting to drone", 2);
                }

                continue;
            }
            case MavlinkStateGetParameters: {
                set_loading(true);
                set_saving(false);
                qint64 currentTime = QDateTime::currentMSecsSinceEpoch();

                if (isConnectionLost()) {
                    resetParamVars();
                    m_ground_available = false;
                    state = MavlinkStateDisconnected;
                    LocalMessage::instance()->showMessage("Connection to drone lost (E1)", 4);

                    continue;
                }

                if ((parameterCount != 0) && parameterIndex == (parameterCount - 1)) {
                    emit allParametersChanged();
                    state = MavlinkStateIdle;

                    continue;
                }


                if (currentTime - parameterLastReceivedTime > 7000) {
                    resetParamVars();
                    m_ground_available = false;
                    state = MavlinkStateDisconnected;
                    LocalMessage::instance()->showMessage("Connection to drone lost (E2)", 4);

                    continue;
                }

                continue;
            }
            case MavlinkStateIdle: {
                set_loading(false);

                if (isConnectionLost()) {
                    resetParamVars();
                    m_ground_available = false;
                    state = MavlinkStateDisconnected;
                    LocalMessage::instance()->showMessage("Connection to drone lost (E3)", 4);

                    continue;
                }

                break;
            }
        }
    }
}


void MavlinkTelemetry::processMavlinkMessage(mavlink_message_t msg) {
    /* QGC sends its own heartbeats with compid 0 (fixed)
     * and sysid 255 (configurable). We want to ignore these
     * because they cause UI glitches like the flight mode
     * appearing to change and the armed status flipping back
     * and forth.
     */
    if (msg.compid != MAV_COMP_ID_AUTOPILOT1 && msg.compid != MAV_COMP_ID_SYSTEM_CONTROL) {
        return;
    }
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
                    QMutexLocker locker(&stateLock);

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

            int battery_percent = lipo_battery_voltage_to_percent(battery_cells, battery_voltage_raw);
            OpenHD::instance()->set_battery_percent(QString("%1%").arg(battery_percent));
            QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
            OpenHD::instance()->set_battery_gauge(battery_gauge_glyph);
            break;
        }

        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            break;
        }
        case MAVLINK_MSG_ID_PARAM_VALUE:{
            QMutexLocker locker(&stateLock);

            mavlink_param_value_t param;
            mavlink_msg_param_value_decode(&msg, &param);

            parameterCount = param.param_count;
            parameterIndex = param.param_index;

            parameterLastReceivedTime = QDateTime::currentMSecsSinceEpoch();

            m_allParameters.insert(QString(param.param_id), QVariant(param.param_value));
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
            //qDebug() << "Pitch:" <<  attitude.pitch*57.2958;

            OpenHD::instance()->set_roll_raw((float)attitude.roll *57.2958);
            //qDebug() << "Roll:" <<  attitude.roll*57.2958;
            break;
        }
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED:{
            break;
        }
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t global_position;
            mavlink_msg_global_position_int_decode(&msg, &global_position);

            OpenHD::instance()->set_lat(tr("%1").arg((double)global_position.lat / 10000000.0, 2, 'f', 6, '1'));
            OpenHD::instance()->set_lat_raw((double)global_position.lat / 10000000.0);
            OpenHD::instance()->set_lon(tr("%1").arg((double)global_position.lon / 10000000.0, 2, 'f', 6, '1'));
            OpenHD::instance()->set_lon_raw((double)global_position.lon / 10000000.0);

            OpenHD::instance()->set_boot_time(tr("%1").arg(global_position.time_boot_ms));

            OpenHD::instance()->set_alt_rel(tr("%1").arg(global_position.relative_alt/1000.0, 1, 'f', 0, '0'));
            // qDebug() << "Altitude relative " << alt_rel;
            OpenHD::instance()->set_alt_msl(tr("%1").arg(global_position.alt/1000.0, 1, 'f', 0, '0'));

            // FOR INAV heading does not /100
            OpenHD::instance()->set_hdg(tr("%1").arg(global_position.hdg/100.0, 1, 'f', 0, '0'));
            OpenHD::instance()->set_hdg_raw((double)global_position.hdg / 100.0);

            OpenHD::instance()->set_vx((int)(global_position.vx/100.0));
            OpenHD::instance()->set_vy((int)(global_position.vy/100.0));
            OpenHD::instance()->set_vz((int)(global_position.vz/100.0));

            OpenHD::instance()->calculate_home_distance();
            OpenHD::instance()->calculate_home_course();

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

            OpenHD::instance()->set_throttle(vfr_hud.throttle);

            //td->airspeed = mavlink_msg_vfr_hud_get_airspeed(&msg)*3.6f;

            auto speed = vfr_hud.groundspeed*3.6;
            OpenHD::instance()->set_speed(tr("%1").arg(speed, 1, 'f', 0, '0'));
            // qDebug() << "Speed- ground " << speed;

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
                    // qDebug() << "Battery cell voltage " << cell << " :" << cell_voltage;
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
            OpenHD::instance()->set_homelat_raw((double)home_position.latitude / 10000000.0);
            OpenHD::instance()->set_homelat(tr("%1").arg((double)home_position.latitude / 10000000.0, 2, 'f', 6, '1'));
            OpenHD::instance()->set_homelon_raw((double)home_position.longitude / 10000000.0);
            OpenHD::instance()->set_homelon(tr("%1").arg((double)home_position.longitude / 10000000.0, 2, 'f', 6, '1'));

            OpenHD::instance()->calculate_home_distance();
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
        case MAVLINK_MSG_ID_OPENHD_GROUND_POWER: {
            mavlink_openhd_ground_power_t ground_power;
            mavlink_msg_openhd_ground_power_decode(&msg, &ground_power);
            qDebug() << "MAVLINK_MSG_ID_OPENHD_GROUND_POWER";

            OpenHDPower::instance()->set_vin_raw(ground_power.vin);
            OpenHDPower::instance()->set_vout_raw(ground_power.vout);
            OpenHDPower::instance()->set_vbat_raw(ground_power.vbat);
            OpenHDPower::instance()->set_iout_raw(ground_power.iout);

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
