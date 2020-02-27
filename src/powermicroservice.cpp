#include "powermicroservice.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>

#include <openhd/mavlink.h>

#include "util.h"
#include "constants.h"

#include "openhd.h"


PowerMicroservice::PowerMicroservice(QObject *parent, MicroserviceTarget target, MavlinkType mavlink_type): MavlinkBase(parent, mavlink_type), m_target(target) {
    qDebug() << "PowerMicroservice::PowerMicroservice()";

    targetCompID = MAV_COMP_ID_USER1;
    localPort = 14551;

    switch (m_target) {
        case MicroserviceTargetNone:
        targetSysID = 0;
        break;
        case MicroserviceTargetAir:
        targetSysID = 253;
        connect(OpenHD::instance(), &OpenHD::air_shutdown, this, &PowerMicroservice::onShutdown);
        connect(OpenHD::instance(), &OpenHD::air_reboot, this, &PowerMicroservice::onReboot);
        break;
        case MicroserviceTargetGround:
        targetSysID = 254;
        connect(OpenHD::instance(), &OpenHD::ground_shutdown, this, &PowerMicroservice::onShutdown);
        connect(OpenHD::instance(), &OpenHD::ground_reboot, this, &PowerMicroservice::onReboot);
        break;
    }

    connect(this, &PowerMicroservice::setup, this, &PowerMicroservice::onSetup);
}

void PowerMicroservice::onSetup() {
    qDebug() << "PowerMicroservice::onSetup()";

    connect(this, &PowerMicroservice::processMavlinkMessage, this, &PowerMicroservice::onProcessMavlinkMessage);
}


void PowerMicroservice::onShutdown() {
    mavlink_message_t msg;
    mavlink_msg_command_long_pack(255, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID, targetCompID, OPENHD_CMD_POWER_SHUTDOWN, 0, 0, 0, 0, 0, 0, 0, 0);

    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    int len = mavlink_msg_to_send_buffer(buffer, &msg);

    sendData((char*)buffer, len);
}


void PowerMicroservice::onReboot() {
    mavlink_message_t msg;
    mavlink_msg_command_long_pack(255, MAV_COMP_ID_MISSIONPLANNER, &msg, targetSysID, targetCompID, OPENHD_CMD_POWER_REBOOT, 0, 0, 0, 0, 0, 0, 0, 0);

    uint8_t buffer[MAVLINK_MAX_PACKET_LEN];
    int len = mavlink_msg_to_send_buffer(buffer, &msg);

    sendData((char*)buffer, len);
}


void PowerMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
    if (msg.compid != targetCompID || msg.sysid != targetSysID) {
        return;
    }
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
            break;
        }
        case MAVLINK_MSG_ID_OPENHD_GROUND_POWER: {
            mavlink_openhd_ground_power_t ground_power;
            mavlink_msg_openhd_ground_power_decode(&msg, &ground_power);

            OpenHD::instance()->set_ground_vin(ground_power.vin);
            OpenHD::instance()->set_ground_vout(ground_power.vout);
            OpenHD::instance()->set_ground_vbat(ground_power.vbat);
            OpenHD::instance()->set_ground_iout(ground_power.iout);

            auto battery_cells = 1; //settings.value("battery_cells", QVariant(3)).toInt();

            //int battery_percent = lifepo4_battery_voltage_to_percent(battery_cells, m_vbat_raw);
            //set_battery_percent(QString("%1%").arg(battery_percent));
            //QString battery_gauge_glyph = battery_gauge_glyph_from_percentage(battery_percent);
            //set_battery_gauge(battery_gauge_glyph);

            break;
        }
        default: {
            printf("PowerMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}
