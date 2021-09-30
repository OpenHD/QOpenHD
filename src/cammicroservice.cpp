#include "cammicroservice.h"
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


CamMicroservice::CamMicroservice(QObject *parent, MicroserviceTarget target, MavlinkType mavlink_type): MavlinkBase(parent, mavlink_type), m_target(target) {
    qDebug() << "CamMicroservice::CamMicroservice()";

    targetCompID = MAV_COMP_ID_USER2;

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
        connect(OpenHD::instance(), &OpenHD::save_cam_bright, this, &CamMicroservice::onSaveCamBright);
        break;
    case MicroserviceTargetGround:
        targetSysID = 254;
        //no ground cams :) so nothing here
        break;
    }

    connect(this, &CamMicroservice::setup, this, &CamMicroservice::onSetup);
}

void CamMicroservice::onSetup() {
    qDebug() << "CamMicroservice::onSetup()";

    connect(this, &CamMicroservice::processMavlinkMessage, this, &CamMicroservice::onProcessMavlinkMessage);

    connect(this, &MavlinkBase::commandDone, this, &CamMicroservice::onCommandDone);
    connect(this, &MavlinkBase::commandFailed, this, &CamMicroservice::onCommandFailed);

}


void CamMicroservice::onSaveCamBright(int bright) {

    qDebug() << "-----------onsaveCamBright-----------";
    LocalMessage::instance()->showMessage("Brightness being changed...", 6);

    MavlinkCommand command(MavlinkCommandTypeLong);
    command.command_id = OPENHD_CMD_SET_CAMERA_SETTINGS;
    command.long_param1 = static_cast<float>(bright);
    sendCommand(command);
}


void CamMicroservice::onProcessMavlinkMessage(mavlink_message_t msg) {
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
               we need to re-fetch the cam state */
        if (boot_time != m_last_boot) {
            m_last_boot = boot_time;
            switch (m_target) {
            case MicroserviceTargetNone:
                break;
            case MicroserviceTargetAir:
                OpenHD::instance()->set_cam_busy(true);
                break;
            case MicroserviceTargetGround:
                OpenHD::instance()->set_cam_busy(true);
                break;
            }

            MavlinkCommand command(MavlinkCommandTypeLong);
            command.command_id = OPENHD_CMD_GET_CAMERA_SETTINGS;
            qDebug() << "CamMicroservice::get cam settings";
            sendCommand(command);
        }

        break;
    }
    case MAVLINK_MSG_ID_OPENHD_CAMERA_SETTINGS: {
        mavlink_openhd_camera_settings_t cam;
        mavlink_msg_openhd_camera_settings_decode(&msg, &cam);

        switch (m_target) {
        case MicroserviceTargetNone:
            break;
        case MicroserviceTargetAir:
            OpenHD::instance()->set_cam_bright(cam.brightness);
            qDebug() << "CamMicroservice::set_cam_bright target air";
            break;
        case MicroserviceTargetGround:
            //this would only be reached in error as there are no ground cams
            qDebug() << "CamMicroservice::set_cam_bright target ground";
            break;
        }
        break;
    }
    default: {
        printf("CamMicroservice received unmatched message with ID %d, sequence: %d from component %d of system %d\n", msg.msgid, msg.seq, msg.compid, msg.sysid);
        break;
    }
    }
}

void CamMicroservice::onCommandDone() {
    switch (m_target) {
    case MicroserviceTargetNone:
        break;
    case MicroserviceTargetAir:
        OpenHD::instance()->set_cam_busy(false);
        break;
    case MicroserviceTargetGround:
        OpenHD::instance()->set_cam_busy(false);
        break;
    }
}

void CamMicroservice::onCommandFailed() {
    switch (m_target) {
    case MicroserviceTargetNone:
        break;
    case MicroserviceTargetAir:
        OpenHD::instance()->set_cam_busy(false);
        break;
    case MicroserviceTargetGround:
        OpenHD::instance()->set_cam_busy(false);
        break;
    }
    m_last_boot = 0;
}
