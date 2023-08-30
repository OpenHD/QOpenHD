#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "../MavlinkTelemetry.h"
#include "cmdsender.h"

#include "create_cmd_helper.hpp"
#include "../models/fcmavlinksystem.h"

FCAction::FCAction(QObject *parent)
    : QObject{parent}
{

}

FCAction &FCAction::instance()
{
    static FCAction instance;
    return instance;
}

void FCAction::set_fc_sys_id(int fc_sys_id, int fc_comp_id)
{
    m_fc_sys_id=fc_sys_id;
    m_fc_comp_id=fc_comp_id;
}


void FCAction::arm_fc_async(bool arm)
{
    if(!FCMavlinkSystem::instance().is_alive()){
        HUDLogMessagesModel::instance().add_message_info("FC not alive");
        return;
    }
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    const auto command=cmd::helper::create_cmd_arm(fc_sys_id,fc_comp_id,arm);
    auto cb=[this,arm](CmdSender::RunCommandResult result){
        if(!result.opt_ack.has_value()){
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARM - FC not reachable" : "DISARM - FC not reachable");
        }else if(result.is_accepted()){
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARMED FC":"DISARMED FC");
        }else{
            HUDLogMessagesModel::instance().add_message_info(arm ? "ARM not possible":"DISARM not possible");
        }
    };
    CmdSender::instance().send_command_long_async(command,cb);
}

void FCAction::flight_mode_cmd_async(long cmd_msg) {
    if(cmd_msg<0){
        // We get the flight mode command from qml, something is wrong with it
        std::stringstream ss;
        ss<<"Invalid FM "<<cmd_msg;
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        return;
    }
    if(!FCMavlinkSystem::instance().is_alive()){
        HUDLogMessagesModel::instance().add_message_info("FC not alive");
        return;
    }
    if(m_has_currently_runnning_flight_mode_change){
        HUDLogMessagesModel::instance().add_message_info("Busy, please try again later");
        return;
    }
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    auto command=cmd::helper::create_cmd_do_set_flight_mode(fc_sys_id,fc_comp_id,cmd_msg);
    auto cb=[this](CmdSender::RunCommandResult result){
        if(!result.opt_ack.has_value()){
            HUDLogMessagesModel::instance().add_message_info("FC not reachable");
        }else if(result.is_accepted()){
            HUDLogMessagesModel::instance().add_message_info("Flight mode success");
        }else{
            HUDLogMessagesModel::instance().add_message_info("Flight mode unsupported");
        }
        m_has_currently_runnning_flight_mode_change=false;
    };
    m_has_currently_runnning_flight_mode_change=true;
    const auto result=CmdSender::instance().send_command_long_async(command,cb,std::chrono::milliseconds(250),6);
    if(!result){
        HUDLogMessagesModel::instance().add_message_info("Failed, please try again later");
    }
}

void FCAction::request_home_position_from_fc()
{
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    const auto command=cmd::helper::create_cmd_request_message(fc_sys_id,fc_comp_id,MAVLINK_MSG_ID_HOME_POSITION);
    const auto result=CmdSender::instance().send_command_long_blocking(command);
    if(result==CmdSender::CMD_SUCCESS){
        HUDLogMessagesModel::instance().add_message_info("Request home success");
    }else{
        HUDLogMessagesModel::instance().add_message_info("Request home failure");
    }
}

bool FCAction::send_command_reboot(bool reboot)
{
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    auto command=cmd::helper::create_cmd_reboot(fc_sys_id,fc_comp_id,reboot);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}
