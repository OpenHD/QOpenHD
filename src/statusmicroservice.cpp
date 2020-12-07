#include "statusmicroservice.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QProcess>
#include <QProcessEnvironment>

#include <openhd/mavlink.h>


StatusMicroservice::StatusMicroservice(QObject *parent, MicroserviceTarget target, MavlinkType mavlink_type): MavlinkBase(parent, mavlink_type), m_target(target) {
    qDebug() << "StatusMicroservice::StatusMicroservice()";

    targetCompID = MAV_COMP_ID_USER3;
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
        break;
        case MicroserviceTargetGround:
        targetSysID = 254;
        break;
    }

    connect(this, &StatusMicroservice::setup, this, &StatusMicroservice::onSetup);
}


void StatusMicroservice::onSetup() {
    qDebug() << "StatusMicroservice::onSetup()";

    connect(this, &StatusMicroservice::processMavlinkMessage, this, &StatusMicroservice::onProcessMavlinkMessage);
}


void StatusMicroservice::setOpenHDVersion(QString openHDVersion) {
    m_openHDVersion = openHDVersion;
    emit openHDVersionChanged(m_openHDVersion);
}


void StatusMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
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
                m_last_timestamp = 0;

                MavlinkCommand command(MavlinkCommandTypeLong);
                command.command_id = OPENHD_CMD_GET_VERSION;
                sendCommand(command);
            }

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE: {
            mavlink_openhd_version_message_t version_message;
            mavlink_msg_openhd_version_message_decode(&msg, &version_message);

            // the microservice code ensures that there is always a null at the end of this array
            // before sending the message, so we can rely on there being one and use QString directly
            QString openhd_version(version_message.version);


            setOpenHDVersion(openhd_version);

            /*
             * Now that the initial state is loaded, load all known
             * messages from the service on the air or ground
             */
            MavlinkCommand command(MavlinkCommandTypeLong);
            command.command_id = OPENHD_CMD_GET_STATUS_MESSAGES;
            sendCommand(command);

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_STATUS_MESSAGE: {
            mavlink_openhd_status_message_t status_message;
            mavlink_msg_openhd_status_message_decode(&msg, &status_message);

            StatusMessage t;
            t.sysid = msg.sysid;
            t.compid = msg.compid;
            t.message = status_message.text;
            t.severity = status_message.severity;
            t.timestamp = status_message.timestamp;

            if (m_last_boot != 0 && t.timestamp > m_last_timestamp) {
                m_last_timestamp = t.timestamp;
                StatusLogModel::instance()->addMessage(t);
                emit statusMessage(msg.sysid, status_message.text, status_message.severity, status_message.timestamp);
            }

            break;
        }
        default: {
            printf("StatusMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}
