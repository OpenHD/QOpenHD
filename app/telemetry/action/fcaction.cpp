#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "../MavlinkTelemetry.h"
#include "cmdsender.h"

#include "create_cmd_helper.hpp"

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
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    const auto command=cmd::helper::create_cmd_arm(fc_sys_id,fc_comp_id,arm);
    CmdSender::instance().send_command_long_async(command,nullptr);
}

void FCAction::flight_mode_cmd(long cmd_msg) {
    if(cmd_msg<0){
        // We get the flight mode command from qml, something is wrong with it
        std::stringstream ss;
        ss<<"Invalid FM "<<cmd_msg;
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        return;
    }
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    auto command=cmd::helper::create_cmd_do_set_flight_mode(fc_sys_id,fc_comp_id,cmd_msg);
    const auto result=CmdSender::instance().send_command_long_blocking(command);
    if(result==CmdSender::Result::QUEUE_FULL){
        HUDLogMessagesModel::instance().add_message_info("Failed, please try again later");
    }else if(result==CmdSender::Result::CMD_SUCCESS){
        std::stringstream ss;
        ss<<"Flight mode success";
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
    }else if(result==CmdSender::CMD_DENIED){
        HUDLogMessagesModel::instance().add_message_info("Flight mode unsupported");
    }else{
        HUDLogMessagesModel::instance().add_message_info("FC not reachable");
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
