#include "synchronizedsettings.h"

#include "../models/aohdsystem.h"
#include "mavlinksettingsmodel.h"

#include "../../util/WorkaroundMessageBox.h"
#include "../logging/hudlogmessagesmodel.h"
#include "../logging/logmessagesmodel.h"
#include <qsettings.h>
#include <sstream>


SynchronizedSettings::SynchronizedSettings(QObject *parent)
    : QObject{parent}
{
    m_request_message_helper=std::make_unique<RequestMessageHelper>();
}

SynchronizedSettings& SynchronizedSettings::instance()
{
    static SynchronizedSettings tmp;
    return tmp;
}

void SynchronizedSettings::fetch_channels_if_needed()
{
    if(m_has_fetched_channels){
        qDebug()<<"Already fetched";
        return;
    }
    m_request_message_helper->request_message(OHD_SYS_ID_GROUND,MAV_COMP_ID_ONBOARD_COMPUTER,MAVLINK_MSG_ID_OPENHD_WIFBROADCAST_SUPPORTED_CHANNELS);
    QTimer::singleShot(1000, this, &SynchronizedSettings::update_channels_on_success);
    QTimer::singleShot(2000, this, &SynchronizedSettings::update_channels_on_success);
}


void SynchronizedSettings::xx_tmp()
{
    set_has_fetched_channels(true);
}

void SynchronizedSettings::update_channels_on_success()
{
    const auto channel_message_opt=m_request_message_helper->get_last_requested_message();
    if(!channel_message_opt.has_value()){
        return;
    }
    if(m_has_fetched_channels){
        return;
    }
    const auto channel_message=channel_message_opt.value();
    mavlink_openhd_wifbroadcast_supported_channels_t tmp{};
    mavlink_msg_openhd_wifbroadcast_supported_channels_decode(&channel_message,&tmp);
    m_supported_channels.resize(0);
    for(int i=0;i<60;i++){
        if(tmp.channels[i]!=0){
            m_supported_channels.push_back(tmp.channels[i]);
        }
    }
    if(!m_supported_channels.empty()){
        set_has_fetched_channels(true);
    }
}


void SynchronizedSettings::validate_and_set_channel_mhz(int channel_mhz)
{
    if(channel_mhz<=1000){
        set_curr_channel_mhz(-1);
    }else{
        set_curr_channel_mhz(channel_mhz);
    }
}

void SynchronizedSettings::validate_and_set_channel_width_mhz(int channel_width_mhz)
{
    if(channel_width_mhz==20 || channel_width_mhz==40){
        set_curr_channel_width_mhz(channel_width_mhz);
    }else{
        set_curr_channel_width_mhz(-1);
    }
}

int SynchronizedSettings::get_param_int_air_and_ground_value(QString param_id)
{
    qDebug()<<"get_param_air_and_ground_value "<<param_id;

    const auto value_ground_opt=MavlinkSettingsModel::instanceGround().try_get_param_int_impl(param_id);
    if(!value_ground_opt.has_value()){
        WorkaroundMessageBox::makePopupMessage("Cannot fetch param from ground",5);
        return -1;
    }
    const auto value_ground=value_ground_opt.value();
    // Now that we have the value from the ground, fetch the value from the air
    const auto value_air_opt=MavlinkSettingsModel::instanceAir().try_get_param_int_impl(param_id);
    if(!value_air_opt.has_value()){
        WorkaroundMessageBox::makePopupMessage("Cannot fetch param from air",5);
        return value_ground;
    }
    const auto value_air=value_air_opt.value();
    if(value_air!=value_ground){
         WorkaroundMessageBox::makePopupMessage("Air and ground are out of sync - this can happen after a channel scan. Reboot Ground to Fix.");
         return value_ground;
    }
    return value_ground;
}


void SynchronizedSettings::change_param_air_and_ground(QString param_id,int value,bool allow_changing_without_connected_air_unit,bool log_to_hud)
{
    qDebug()<<"SynchronizedSettings::change_param_air_and_ground: "<<param_id<<":"<<value<<" no-sync:"<<allow_changing_without_connected_air_unit;

    // sanity checking
    const bool air_and_ground_alive=AOHDSystem::instanceAir().is_alive() && AOHDSystem::instanceGround().is_alive();
    if(allow_changing_without_connected_air_unit){
        if(!AOHDSystem::instanceGround().is_alive()){
            WorkaroundMessageBox::makePopupMessage("Precondition: OpenHD ground running and alive not given. Change not possible.",5);
            return;
        }
    }else{
        if(!air_and_ground_alive){
            WorkaroundMessageBox::makePopupMessage("Precondition: Air and Ground running and alive not given. Change not possible.",5);
            return;
        }
    }
    const MavlinkSettingsModel::ExtraRetransmitParams extra_retransmit_params{std::chrono::milliseconds(100),10};
    // First change it on the air and wait for ack - if failed, return. MAVSDK does 3 retransmission(s) until acked so it is really unlikely that
    // we set the value and all 3 ack's are lost (which would be the generals problem and then the frequenies are out of sync).
    const auto air_success=MavlinkSettingsModel::instanceAir().try_set_param_int_impl(param_id,value,extra_retransmit_params);
    if(!(air_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        if(allow_changing_without_connected_air_unit){
            std::stringstream ss;
            ss<<"No air unit connected - changing ground only to "<<value<<"Mhz";
            WorkaroundMessageBox::makePopupMessage(ss.str().c_str(),5);
        }else{
            std::stringstream ss;
            ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
            if(log_to_hud){
                HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
            }else{
                WorkaroundMessageBox::makePopupMessage(ss.str().c_str(),10);
            }
            return;
        }
    }
    // we have changed the value on air, now change the ground
    // It is highly unlikely that fauls - if it does, we have an issue ! (2 generals problem)
    const auto ground_success=MavlinkSettingsModel::instanceGround().try_set_param_int_impl(param_id,value);
    if(!(ground_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
        ss<<"\nAir and ground are out of sync";
        WorkaroundMessageBox::makePopupMessage(ss.str().c_str(),10);
        return;
    }
    if(!allow_changing_without_connected_air_unit){
        std::stringstream ss;
        ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value<<" ,might take up to 3 seconds until applied";
        if(log_to_hud){
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }else{
            WorkaroundMessageBox::makePopupMessage(ss.str().c_str(),5);
        }
    }
}

int SynchronizedSettings::get_next_frequency_item(int index)
{
    if(index<10)return index+1;
    return -1;
}

QString SynchronizedSettings::get_next_frequency_item_description()
{
    return "TODO";
}

void SynchronizedSettings::log_result_message(const std::string &result_message, bool use_hud)
{
    if(use_hud){
        HUDLogMessagesModel::instance().add_message_info(result_message.c_str());
    }else{
       WorkaroundMessageBox::makePopupMessage(result_message.c_str());
    }
}

