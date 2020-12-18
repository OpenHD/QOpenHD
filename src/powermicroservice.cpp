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

    #if defined(__rasp_pi__)
    groundAddress = "127.0.0.1";
    #endif

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
    shutdown();
}


void PowerMicroservice::onReboot() {
    reboot();
}

void PowerMicroservice::shutdown() {
    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = OPENHD_CMD_POWER_SHUTDOWN;
    sendCommand(command);
}

void PowerMicroservice::reboot() {
    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = OPENHD_CMD_POWER_REBOOT;
    sendCommand(command);
}


void PowerMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
            break;
        }
        case MAVLINK_MSG_ID_SYSTEM_TIME:{
            mavlink_system_time_t sys_time;
            mavlink_msg_system_time_decode(&msg, &sys_time);
            uint32_t boot_time = sys_time.time_boot_ms;

            if (boot_time != m_last_boot) {
                m_last_boot = boot_time;
            }

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_POWER: {
            mavlink_openhd_power_t power;
            mavlink_msg_openhd_power_decode(&msg, &power);

            switch (m_target) {
                case MicroserviceTargetAir: {
                    OpenHD::instance()->set_air_vout(power.vout);
                    OpenHD::instance()->set_air_iout(power.iout);
                    break;
                }
                case MicroserviceTargetGround: {
                    OpenHD::instance()->set_ground_vin(power.vin);
                    OpenHD::instance()->set_ground_vout(power.vout);
                    OpenHD::instance()->set_ground_vbat(power.vbat);
                    OpenHD::instance()->set_ground_iout(power.iout);

                    QSettings settings;
                    auto ground_battery_cells = settings.value("ground_battery_cells", QVariant(3)).toInt();

                    int ground_battery_percent = m_util.lipo_battery_voltage_to_percent(ground_battery_cells, power.vbat);
                    OpenHD::instance()->set_ground_battery_percent(ground_battery_percent);
                    QString ground_battery_gauge_glyph = m_util.battery_gauge_glyph_from_percentage(ground_battery_percent);
                    OpenHD::instance()->set_ground_battery_gauge(ground_battery_gauge_glyph);

                    break;
                }
                default: {
                    break;
                }
            }

            break;
        }
        default: {
            printf("PowerMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}
