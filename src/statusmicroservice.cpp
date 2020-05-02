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


QList<StatusMessage> StatusMicroservice::getAllMessages() {
    return m_messages;
}


void StatusMicroservice::resetMessages() {
    m_messages.clear();
}


void StatusMicroservice::setOpenHDVersion(QString openHDVersion) {
    m_openHDVersion = openHDVersion;
    emit openHDVersionChanged(m_openHDVersion);
}


void StatusMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
    if (msg.compid != targetCompID || msg.sysid != targetSysID) {
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

            if (boot_time != m_last_boot) {
                m_last_boot = boot_time;

                MavlinkCommand c(true);
                c.command_id = OPENHD_CMD_GET_VERSION;
                send_command(c);
            }

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE: {
            mavlink_openhd_version_message_t version_message;
            mavlink_msg_openhd_version_message_decode(&msg, &version_message);

            QByteArray openhd_version(version_message.version, 30);
            if (!openhd_version.contains('\0')) {
               openhd_version.append('\0');
            }

            setOpenHDVersion(openhd_version);

            /*
             * Now that the initial state is loaded, reset the message list and load all known
             * messages from the service on the air or ground
             */
            resetMessages();

            MavlinkCommand c(true);
            c.command_id = OPENHD_CMD_GET_STATUS_MESSAGES;
            send_command(c);

            break;
        }
        case MAVLINK_MSG_ID_OPENHD_STATUS_MESSAGE: {
            mavlink_openhd_status_message_t status_message;
            mavlink_msg_openhd_status_message_decode(&msg, &status_message);

            StatusMessage t;
            t.sysid = msg.sysid;
            t.compid = msg.compid;
            t.message = status_message.text;
            t.severity = static_cast<MAV_SEVERITY>(status_message.severity);
            t.timestamp = status_message.timestamp;

            m_messages.append(t);

            std::sort(m_messages.begin(), m_messages.end(), [](const StatusMessage a, const StatusMessage b) -> bool { return a.timestamp < b.timestamp; });

            emit statusMessage(msg.sysid, status_message.text, status_message.severity, status_message.timestamp);

            break;
        }
        default: {
            printf("StatusMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
            break;
        }
    }
}
