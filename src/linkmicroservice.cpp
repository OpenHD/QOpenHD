#include "linkmicroservice.h"
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

#include "localmessage.h"


LinkMicroservice::LinkMicroservice(QObject *parent, MicroserviceTarget target, MavlinkType mavlink_type): MavlinkBase(parent, mavlink_type), m_target(target) {
    qDebug() << "LinkMicroservice::LinkMicroservice()";

    targetCompID = MAV_COMP_ID_USER2;

    localPort = 14551;

    #if defined(__rasp_pi__)|| defined(__jetson__)
    groundAddress = "127.0.0.1";
    #endif

    switch (m_target) {
        case MicroserviceTargetNone:
        targetSysID = 0;
        break;
        case MicroserviceTargetAir:
        targetSysID = 253;
        connect(OpenHD::instance(), &OpenHD::save_air_freq, this, &LinkMicroservice::onSaveFreq);
        break;
        case MicroserviceTargetGround:
        targetSysID = 254;
        connect(OpenHD::instance(), &OpenHD::save_gnd_freq, this, &LinkMicroservice::onSaveFreq);
        break;
    }

    connect(this, &LinkMicroservice::setup, this, &LinkMicroservice::onSetup);
}

void LinkMicroservice::onSetup() {
    qDebug() << "LinkMicroservice::onSetup()";

    connect(this, &LinkMicroservice::processMavlinkMessage, this, &LinkMicroservice::onProcessMavlinkMessage);

    connect(this, &MavlinkBase::commandDone, this, &LinkMicroservice::onCommandDone);
    connect(this, &MavlinkBase::commandFailed, this, &LinkMicroservice::onCommandFailed);

}


void LinkMicroservice::onSaveFreq(int freq) {

    qDebug() << "-----------onsaveFreq-----------";
    LocalMessage::instance()->showMessage("Frequency being changed...", 6);

    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = OPENHD_CMD_SET_FREQS;
    command.long_param1 = static_cast<float>(freq);
    sendCommand(command);
}


void LinkMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
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
               we need to re-fetch the Link state */
            if (boot_time != m_last_boot) {
                m_last_boot = boot_time;
                switch (m_target) {
                    case MicroserviceTargetNone:
                        break;
                    case MicroserviceTargetAir:
                        OpenHD::instance()->set_air_freq_busy(true);
                        break;
                    case MicroserviceTargetGround:
                        OpenHD::instance()->set_air_freq_busy(true);
                        break;
                }

                MavlinkCommand command(MavlinkCommandTypeLong);
                command.command_id = OPENHD_CMD_GET_FREQS;
                sendCommand(command);
            }

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_WIFI_STATUS: {
            mavlink_openhd_wifi_status_t link;
            mavlink_msg_openhd_wifi_status_decode(&msg, &link);

            switch (m_target) {
                case MicroserviceTargetNone:
                break;
                case MicroserviceTargetAir:
                OpenHD::instance()->set_air_freq(link.wifi_freq);
                break;
                case MicroserviceTargetGround:
                OpenHD::instance()->set_gnd_freq(link.wifi_freq);
                break;
            }
            break;
        }
        default: {
            printf("LinkMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}

void LinkMicroservice::onCommandDone() {
    switch (m_target) {
        case MicroserviceTargetNone:
            break;
        case MicroserviceTargetAir:
            OpenHD::instance()->set_air_freq_busy(false);
            break;
        case MicroserviceTargetGround:
            OpenHD::instance()->set_air_freq_busy(false);
            break;
    }
}

void LinkMicroservice::onCommandFailed() {
    switch (m_target) {
        case MicroserviceTargetNone:
            break;
        case MicroserviceTargetAir:
            OpenHD::instance()->set_air_freq_busy(false);
            break;
        case MicroserviceTargetGround:
            OpenHD::instance()->set_air_freq_busy(false);
            break;
    }
    m_last_boot = 0;
}
