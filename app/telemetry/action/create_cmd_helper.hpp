#ifndef CMD_HELPER_H
#define CMD_HELPER_H

#include "../tutil/mavlink_include.h"

// Here we have various util methods to create mavlink_command_long_t commands
namespace cmd::helper{

// @Param: companion_computer: If set to true the message generated is for openhd
// otherwise,it is for the FC
static mavlink_command_long_t create_cmd_reboot(int target_sysid,int target_compid,bool reboot,bool companion_computer){
    mavlink_command_long_t cmd{};
    cmd.target_system=target_sysid;
    cmd.target_component=target_compid;
    cmd.command=MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN;
    if(companion_computer){
        cmd.param2=(reboot ? 1 : 2);
    }else{
        cmd.param1=(reboot ? 1 : 2);
    }
    return cmd;
}

static mavlink_command_long_t create_cmd_request_message(int target_sysid,int target_compid,int message_id){
    mavlink_command_long_t command{};
    command.command=MAV_CMD_REQUEST_MESSAGE;
    command.target_system=target_sysid;
    command.target_component=target_compid;
    command.param1=static_cast<float>(message_id);
    return command;
}

static mavlink_command_long_t create_cmd_request_openhd_version(int target_sysid,int target_compid){
    return create_cmd_request_message(target_sysid,target_compid,MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE);
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

static mavlink_command_long_t create_cmd_set_msg_interval(int target_system,int target_component,int msg_type,int interval_us){
    mavlink_command_long_t command{};
    command.target_system=target_system;
    command.target_component=target_component;
    command.command=MAV_CMD_SET_MESSAGE_INTERVAL;
    command.confirmation=0;
    command.param1=msg_type;
    command.param2=interval_us;
    return command;
}

}

#endif // CMD_HELPER_H
