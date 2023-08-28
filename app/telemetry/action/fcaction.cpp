#include "fcaction.h"
#include "qdebug.h"

#include "../../logging/hudlogmessagesmodel.h"
#include "../MavlinkTelemetry.h"

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


static mavlink_command_long_t create_cmd_arm(int fc_sys_id,int fc_comp_id,bool arm){
    mavlink_command_long_t cmd{};
    cmd.command=MAV_CMD_COMPONENT_ARM_DISARM;
    cmd.target_system=fc_sys_id;
    cmd.target_component=fc_comp_id;
    //cmd.confirmation=false;
    cmd.param1=arm ? 1 : 0;
    cmd.param2=0; // do not force
    return cmd;
}

static mavlink_command_long_t create_cmd_request_message(int fc_sys_id,int fc_comp_id,int requested_message_id){
    mavlink_command_long_t cmd{};
    cmd.command=MAV_CMD_REQUEST_MESSAGE;
    cmd.target_system=fc_sys_id;
    cmd.target_component=fc_comp_id;
    //cmd.confirmation=false;
    cmd.param1=requested_message_id;
    return cmd;
}

static mavlink_command_long_t create_cmd_do_set_flight_mode(int fc_sys_id,int fc_comp_id,int mode){
    mavlink_command_long_t cmd{};
    cmd.command = MAV_CMD_DO_SET_MODE;

    cmd.target_system= fc_sys_id;
    cmd.target_component=fc_comp_id;

    cmd.param1=MAV_MODE_FLAG_CUSTOM_MODE_ENABLED;
    cmd.param2=mode;
    cmd.param3=0;
    cmd.param4=0;
    cmd.param5=0;
    cmd.param6=0;
    cmd.param7=0;
    return cmd;
}

void FCAction::arm_fc_async(bool arm)
{
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    const auto command=create_cmd_arm(fc_sys_id,fc_comp_id,arm);
    const auto result=MavlinkTelemetry::instance().send_command_long_blocking(command);
    if(result==-1){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return;
    }
    if(result==-2){
        HUDLogMessagesModel::instance().add_message_info("Failed to reach FC");
        return;
    }
    assert(result==0);
    std::stringstream ss;
    if(arm){
        ss<<"FC armed";
    }else{
        ss<<"FC disarmed";
    }
    HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
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
    auto command=create_cmd_do_set_flight_mode(fc_sys_id,fc_comp_id,cmd_msg);
    const auto result=MavlinkTelemetry::instance().send_command_long_blocking(command);
    if(result==-1){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return;
    }
    if(result==-2){
        HUDLogMessagesModel::instance().add_message_info("Failed to reach FC");
        return;
    }
    std::stringstream ss;
    ss<<"Flight mode success";
    HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
}

void FCAction::request_home_position_from_fc()
{
    const auto fc_sys_id=m_fc_sys_id;
    const auto fc_comp_id=m_fc_comp_id;
    const auto command=create_cmd_request_message(fc_sys_id,fc_comp_id,MAVLINK_MSG_ID_HOME_POSITION);
    const auto result=MavlinkTelemetry::instance().send_command_long_blocking(command);
    if(result==-1){
        HUDLogMessagesModel::instance().add_message_info("No FC");
        return;
    }
    if(result==-2){
        HUDLogMessagesModel::instance().add_message_info("Failed to reach FC");
        return;
    }
    //HUDLogMessagesModel::instance().add_message_info("Request home success");
}
