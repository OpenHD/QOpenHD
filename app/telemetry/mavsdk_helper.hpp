#ifndef MAVSDK_HELPER_H
#define MAVSDK_HELPER_H

#include "mavsdk_include.h"
#include <string>
#include <chrono>

namespace mavsdk::helper{


static std::string to_string(const mavsdk::MavlinkPassthrough::Result& res){
    std::stringstream ss;
    ss<<res;
    return ss.str();
}
static std::string to_string2(const std::string& p1,const mavsdk::MavlinkPassthrough::Result& res){
    std::stringstream ss;
    ss<<p1<<res;
    return ss.str();
}

static bool set_message_update_rate(int message_type,std::chrono::milliseconds interval_ms,std::shared_ptr<mavsdk::MavlinkPassthrough>& pass_through){
    mavsdk::MavlinkPassthrough::CommandLong cmd;
    cmd.command = MAV_CMD_SET_MESSAGE_INTERVAL;
    cmd.target_sysid= pass_through->get_target_sysid();
    cmd.target_compid=pass_through->get_target_compid();
    cmd.param1=message_type; // affects artificial horizon update rate
    const int interval_us=std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::milliseconds(interval_ms)).count();
    cmd.param2=interval_us;
    const auto res=pass_through->send_command_long(cmd);
    return res==mavsdk::MavlinkPassthrough::Result::Success;
}

static bool set_all_message_update_rates(std::shared_ptr<mavsdk::MavlinkPassthrough>& pass_through){
    // broadcast home every 2 seconds
    set_message_update_rate(MAVLINK_MSG_ID_ATTITUDE,std::chrono::seconds(2),pass_through);

    // artificial horizon - 50Hz
    set_message_update_rate(MAVLINK_MSG_ID_ATTITUDE,std::chrono::milliseconds(20),pass_through);

    // location every 500ms
    set_message_update_rate(MAVLINK_MSG_ID_GLOBAL_POSITION_INT,std::chrono::milliseconds(500),pass_through);
    return false;
}

}

#endif // MAVSDK_HELPER_H
