#include "ohdaction.h"

#include "create_cmd_helper.hpp"
#include "../util/openhd_defines.hpp"
#include "impl/cmdsender.h"

#include "../models/aohdsystem.h"

OHDAction::OHDAction(QObject *parent)
    : QObject{parent}
{

}

OHDAction& OHDAction::instance()
{
    static OHDAction instance;
    return instance;
}

void OHDAction::request_openhd_version_async()
{
    if(AOHDSystem::instanceAir().is_alive()){
        auto cmd_air=cmd::helper::create_cmd_request_openhd_version(OHD_SYS_ID_AIR,0);
        CmdSender::instance().send_command_long_async(cmd_air,nullptr);
    }
    if(AOHDSystem::instanceGround().is_alive()){
        auto cmd_gnd=cmd::helper::create_cmd_request_openhd_version(OHD_SYS_ID_GROUND,0);
        CmdSender::instance().send_command_long_async(cmd_gnd,nullptr);
    }
}

bool OHDAction::send_command_reboot_air(bool reboot)
{
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_AIR,0,reboot);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_reboot_gnd(bool reboot)
{
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_GROUND,0,reboot);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_analyze_channels_blocking()
{
    mavlink_command_long_t cmd{};
    cmd.target_system=OHD_SYS_ID_GROUND;
    cmd.target_component=OHD_COMP_ID_LINK_PARAM;
    cmd.command=OPENHD_CMD_INITIATE_CHANNEL_ANALYZE;
    const auto res=CmdSender::instance().send_command_long_blocking(cmd);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_start_scan_channels_blocking(int freq_bands, int channel_widths)
{
    mavlink_command_long_t cmd{};
    cmd.target_system=OHD_SYS_ID_GROUND;
    cmd.target_component=OHD_COMP_ID_LINK_PARAM;
    cmd.command=OPENHD_CMD_INITIATE_CHANNEL_SEARCH;
    cmd.param1=static_cast<float>(freq_bands);
    cmd.param2=static_cast<float>(channel_widths);
    const auto res=CmdSender::instance().send_command_long_blocking(cmd);
    return res==CmdSender::Result::CMD_SUCCESS;
}
