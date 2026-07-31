#include "ohdaction.h"

#include "create_cmd_helper.hpp"
#include "../tutil/openhd_defines.hpp"
#include "impl/cmdsender.h"
#include <QMetaObject>
#include <cstring>

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
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_AIR,MAV_COMP_ID_ONBOARD_COMPUTER,reboot,true);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_reboot_gnd(bool reboot)
{
    auto command=cmd::helper::create_cmd_reboot(OHD_SYS_ID_GROUND,MAV_COMP_ID_ONBOARD_COMPUTER,reboot,true);
    const auto res=CmdSender::instance().send_command_long_blocking(command);
    return res==CmdSender::Result::CMD_SUCCESS;
}

bool OHDAction::send_command_format_air_sd_card()
{
    return format_air_storage(1);
}

bool OHDAction::format_air_storage(int storageId)
{
    if(m_format_air_sd_card_busy){
        return false;
    }
    mavlink_command_long_t command{};
    command.target_system=OHD_SYS_ID_AIR;
    command.target_component=MAV_COMP_ID_ONBOARD_COMPUTER;
    command.command=MAV_CMD_STORAGE_FORMAT;
    command.param1=static_cast<float>(storageId);
    command.param2=1.0F; // MAVLink format confirmation

    m_format_air_sd_card_busy=true;
    m_format_air_sd_card_status="Requesting SD card format";
    emit formatAirSdCardStatusChanged();
    const bool queued=CmdSender::instance().send_command_long_async(
        command,[this](CmdSender::RunCommandResult result){
            QMetaObject::invokeMethod(this,[this,result](){
                m_format_air_sd_card_busy=false;
                if(!result.opt_ack.has_value()){
                    m_format_air_sd_card_status="No response from air unit";
                }else if(result.opt_ack->result==MAV_RESULT_ACCEPTED){
                    m_format_air_sd_card_status="Storage format complete";
                    refresh_air_storage();
                }else{
                    m_format_air_sd_card_status="SD card format failed";
                }
                emit formatAirSdCardStatusChanged();
            },Qt::QueuedConnection);
        });
    if(!queued){
        m_format_air_sd_card_busy=false;
        m_format_air_sd_card_status="Could not queue SD card format command";
        emit formatAirSdCardStatusChanged();
    }
    return queued;
}

bool OHDAction::send_storage_action(int action, int storageId,
                                    const QString& runningText)
{
    if(m_format_air_sd_card_busy){
        return false;
    }
    mavlink_command_long_t command{};
    command.target_system=OHD_SYS_ID_AIR;
    command.target_component=MAV_COMP_ID_ONBOARD_COMPUTER;
    command.command=OPENHD_CMD_STORAGE_MANAGE;
    command.param1=static_cast<float>(action);
    command.param2=static_cast<float>(storageId);
    command.param3=action==1 ? 0.0F : 1.0F;

    m_format_air_sd_card_busy=true;
    m_format_air_sd_card_status=runningText;
    emit formatAirSdCardStatusChanged();
    const bool queued=CmdSender::instance().send_command_long_async(
        command,[this,action](CmdSender::RunCommandResult result){
            QMetaObject::invokeMethod(this,[this,result,action](){
                m_format_air_sd_card_busy=false;
                if(!result.opt_ack.has_value()){
                    m_format_air_sd_card_status="No response from air unit";
                }else if(result.opt_ack->result==MAV_RESULT_ACCEPTED){
                    m_format_air_sd_card_status="Storage operation complete";
                    if(action!=1){
                        refresh_air_storage();
                    }
                }else{
                    m_format_air_sd_card_status="Storage operation failed";
                }
                emit formatAirSdCardStatusChanged();
            },Qt::QueuedConnection);
        });
    if(!queued){
        m_format_air_sd_card_busy=false;
        m_format_air_sd_card_status="Could not queue storage command";
        emit formatAirSdCardStatusChanged();
    }
    return queued;
}

bool OHDAction::refresh_air_storage()
{
    m_air_storage_devices.clear();
    emit airStorageDevicesChanged();
    return send_storage_action(1,0,"Refreshing storage devices");
}

bool OHDAction::repartition_air_storage(int storageId)
{
    return send_storage_action(2,storageId,"Repartitioning storage device");
}

bool OHDAction::mount_air_storage_for_recording(int storageId)
{
    return send_storage_action(3,storageId,"Mounting partition at /Video");
}

bool OHDAction::process_message(const mavlink_message_t &message)
{
    if(message.msgid!=MAVLINK_MSG_ID_STORAGE_INFORMATION ||
       message.sysid!=OHD_SYS_ID_AIR ||
       message.compid!=MAV_COMP_ID_ONBOARD_COMPUTER){
        return false;
    }
    mavlink_storage_information_t storage{};
    mavlink_msg_storage_information_decode(&message,&storage);
    const QString encodedName=QString::fromLatin1(
        storage.name,static_cast<int>(strnlen(storage.name,sizeof(storage.name))));
    if(!encodedName.startsWith("D ") && !encodedName.startsWith("P ")){
        return false;
    }
    const bool isDisk=encodedName.startsWith("D ");
    const bool mountedAtVideo=
        (storage.storage_usage & STORAGE_USAGE_FLAG_VIDEO)!=0;
    QVariantMap item;
    item["id"]=static_cast<int>(storage.storage_id);
    item["device"]=encodedName.mid(2);
    item["kind"]=isDisk ? "disk" : "partition";
    item["totalMiB"]=storage.total_capacity;
    item["freeMiB"]=storage.available_capacity;
    item["mountedAtVideo"]=mountedAtVideo;
    item["formatted"]=storage.status!=STORAGE_STATUS_UNFORMATTED;
    item["canFormat"]=!isDisk;
    item["canRepartition"]=isDisk;
    item["canMount"]=!isDisk && storage.status!=STORAGE_STATUS_UNFORMATTED;

    bool replaced=false;
    for(int i=0;i<m_air_storage_devices.size();++i){
        if(m_air_storage_devices[i].toMap().value("id").toInt()==storage.storage_id){
            m_air_storage_devices[i]=item;
            replaced=true;
            break;
        }
    }
    if(!replaced){
        m_air_storage_devices.push_back(item);
    }
    emit airStorageDevicesChanged();
    return true;
}

bool OHDAction::send_command_analyze_channels_blocking(int freq_bands)
{
    mavlink_command_long_t cmd{};
    cmd.target_system=OHD_SYS_ID_GROUND;
    cmd.target_component=MAV_COMP_ID_ONBOARD_COMPUTER;
    cmd.command=OPENHD_CMD_INITIATE_CHANNEL_ANALYZE;
    cmd.param1=static_cast<float>(freq_bands);
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
