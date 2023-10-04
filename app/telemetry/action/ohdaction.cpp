#include "ohdaction.h"

#include "create_cmd_helper.hpp"
#include "../util/openhd_defines.hpp"
#include "impl/cmdsender.h"

//#include "../models/aohdsystem.h"

OHDAction::OHDAction(QObject *parent)
    : QObject{parent}
{

}

OHDAction& OHDAction::instance()
{
    static OHDAction instance;
    return instance;
}

bool OHDAction::send_command_reboot_air(bool reboot)
{
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_AIR,MAV_COMP_ID_ONBOARD_COMPUTER,reboot);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_reboot_gnd(bool reboot)
{
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_GROUND,MAV_COMP_ID_ONBOARD_COMPUTER,reboot);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_analyze_channels_blocking()
{
    mavlink_command_long_t cmd{};
    cmd.target_system=OHD_SYS_ID_GROUND;
    cmd.target_component=MAV_COMP_ID_ONBOARD_COMPUTER;
    cmd.command=OPENHD_CMD_INITIATE_CHANNEL_ANALYZE;
    const auto res=CmdSender::instance().send_command_long_blocking(cmd);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_start_scan_channels_blocking(int freq_bands, int channel_widths)
{
    mavlink_command_long_t cmd{};
    cmd.target_system=OHD_SYS_ID_GROUND;
    cmd.target_component=MAV_COMP_ID_ONBOARD_COMPUTER;
    cmd.command=OPENHD_CMD_INITIATE_CHANNEL_SEARCH;
    cmd.param1=static_cast<float>(freq_bands);
    cmd.param2=static_cast<float>(channel_widths);
    const auto res=CmdSender::instance().send_command_long_blocking(cmd);
    return res==CmdSender::Result::CMD_SUCCESS;
}
