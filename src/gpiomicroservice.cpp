#include "gpiomicroservice.h"
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
#include "powermicroservice.h"

#include "localmessage.h"


GPIOMicroservice::GPIOMicroservice(QObject *parent, MicroserviceTarget target, MavlinkType mavlink_type): MavlinkBase(parent, mavlink_type), m_target(target) {
    qDebug() << "GPIOMicroservice::GPIOMicroservice()";

    targetCompID1 = MAV_COMP_ID_USER2;
    targetCompID2 = targetCompID1;
    targetCompID3 = targetCompID1;

    localPort = 14551;

    #if defined(__rasp_pi__)
    groundAddress = "127.0.0.1";
    #endif

    switch (m_target) {
        case MicroserviceTargetNone:
        targetSysID1 = 0;
        break;
        case MicroserviceTargetAir:
        targetSysID1 = 253;
        connect(OpenHD::instance(), &OpenHD::save_air_gpio, this, &GPIOMicroservice::onSaveGPIO);
        break;
        case MicroserviceTargetGround:
        targetSysID1 = 254;
        connect(OpenHD::instance(), &OpenHD::save_ground_gpio, this, &GPIOMicroservice::onSaveGPIO);
        break;
    }
    targetSysID2 = targetSysID1;

    connect(this, &GPIOMicroservice::setup, this, &GPIOMicroservice::onSetup);
}

void GPIOMicroservice::onSetup() {
    qDebug() << "GPIOMicroservice::onSetup()";

    connect(this, &GPIOMicroservice::processMavlinkMessage, this, &GPIOMicroservice::onProcessMavlinkMessage);

    connect(this, &MavlinkBase::commandDone, this, &GPIOMicroservice::onCommandDone);
    connect(this, &MavlinkBase::commandFailed, this, &GPIOMicroservice::onCommandFailed);

}


void GPIOMicroservice::onSaveGPIO(QList<int> gpio) {
    uint8_t pins = 0;
    for (int i = 0; i < 8; i++) {
        pins |= (gpio[i] & 1) << i;
    }

    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = OPENHD_CMD_SET_GPIOS;
    command.long_param1 = static_cast<float>(pins);
    send_command(command);
}


void GPIOMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
    if (msg.compid != targetCompID1 || msg.sysid != targetSysID1) {
        return;
    }
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

            /* if the boot time of the service at the other end of the link has changed,
               we need to re-fetch the GPIO state */
            if (boot_time != m_last_boot) {
                m_last_boot = boot_time;
                switch (m_target) {
                    case MicroserviceTargetNone:
                        break;
                    case MicroserviceTargetAir:
                        OpenHD::instance()->set_air_gpio_busy(true);
                        break;
                    case MicroserviceTargetGround:
                        OpenHD::instance()->set_air_gpio_busy(true);
                        break;
                }

                MavlinkCommand command(MavlinkCommandTypeLong);
                command.command_id = OPENHD_CMD_GET_GPIOS;
                send_command(command);
            }

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_GPIO_STATE: {
            mavlink_openhd_gpio_state_t gpio_state;
            mavlink_msg_openhd_gpio_state_decode(&msg, &gpio_state);
            uint8_t pins = gpio_state.pins;

            auto gpio5 = pins >> 0 & 1;
            auto gpio6 = pins >> 1 & 1;
            auto gpio12 = pins >> 2 & 1;
            auto gpio13 = pins >> 3 & 1;
            auto gpio16 = pins >> 4 & 1;
            auto gpio19 = pins >> 5 & 1;
            auto gpio26 = pins >> 6 & 1;
            auto gpio32 = pins >> 7 & 1;

            switch (m_target) {
                case MicroserviceTargetNone:
                break;
                case MicroserviceTargetAir:
                OpenHD::instance()->set_air_gpio({gpio5, gpio6, gpio12, gpio13, gpio16, gpio19, gpio26, gpio32});
                break;
                case MicroserviceTargetGround:
                OpenHD::instance()->set_ground_gpio({gpio5, gpio6, gpio12, gpio13, gpio16, gpio19, gpio26, gpio32});
                break;
            }
            break;
        }
        default: {
            printf("GPIOMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}

void GPIOMicroservice::onCommandDone() {
    switch (m_target) {
        case MicroserviceTargetNone:
            break;
        case MicroserviceTargetAir:
            OpenHD::instance()->set_air_gpio_busy(false);
            break;
        case MicroserviceTargetGround:
            OpenHD::instance()->set_air_gpio_busy(false);
            break;
    }
}

void GPIOMicroservice::onCommandFailed() {
    switch (m_target) {
        case MicroserviceTargetNone:
            break;
        case MicroserviceTargetAir:
            OpenHD::instance()->set_air_gpio_busy(false);
            break;
        case MicroserviceTargetGround:
            OpenHD::instance()->set_air_gpio_busy(false);
            break;
    }
    m_last_boot = 0;
}
