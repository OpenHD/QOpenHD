#include "synchronizedsettings.h"

#include "../models/aohdsystem.h"
#include "mavlinksettingsmodel.h"

#include "../../util/WorkaroundMessageBox.h"
#include <sstream>


SynchronizedSettings::SynchronizedSettings(QObject *parent)
    : QObject{parent}
{

}

SynchronizedSettings& SynchronizedSettings::instance()
{
    static SynchronizedSettings tmp;
    return tmp;
}

int SynchronizedSettings::get_param_int_air_and_ground_value(QString param_id)
{
    qDebug()<<"get_param_air_and_ground_value "<<param_id;

    const auto value_ground_opt=MavlinkSettingsModel::instanceGround().try_get_param_int_impl(param_id);
    if(!value_ground_opt.has_value()){
        workaround::MessageBox::instance().set_text_and_show("Cannot fetch param from ground");
        return -1;
    }
    const auto value_ground=value_ground_opt.value();
    // Now that we have the value from the ground, fetch the value from the air
    const auto value_air_opt=MavlinkSettingsModel::instanceAir().try_get_param_int_impl(param_id);
    if(!value_air_opt.has_value()){
        workaround::MessageBox::instance().set_text_and_show("Cannot fetch param from air");
        return value_ground;
    }
    const auto value_air=value_air_opt.value();
    if(value_air!=value_ground){
         workaround::MessageBox::instance().set_text_and_show("Air and ground are out of sync - this should never happen. Please report");
         return value_ground;
    }
    return value_ground;
}


void SynchronizedSettings::change_param_air_and_ground(QString param_id,int value)
{
    qDebug()<<"SynchronizedSettings::change_param_air_and_ground: "<<param_id<<":"<<value;
    // sanity checking
    const bool air_and_ground_alive=AOHDSystem::instanceAir().is_alive() && AOHDSystem::instanceGround().is_alive();
    if(!air_and_ground_alive){
        workaround::MessageBox::instance().set_text_and_show("Precondition: Air and Ground running and alive not given. Change not possible.");
        return;
    }
    const MavlinkSettingsModel::ExtraRetransmitParams extra_retransmit_params{std::chrono::milliseconds(100),10};
    // First change it on the air and wait for ack - if failed, return. MAVSDK does 3 retransmission(s) until acked so it is really unlikely that
    // we set the value and all 3 ack's are lost (which would be the generals problem and then the frequenies are out of sync).
    const auto air_success=MavlinkSettingsModel::instanceAir().try_set_param_int_impl(param_id,value,extra_retransmit_params);
    if(!(air_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
        workaround::MessageBox::instance().set_text_and_show(ss.str().c_str());
        return;
    }
    // we have changed the value on air, now change the ground
    // It is highly unlikely that fauls - if it does, we have an issue ! (2 generals problem)
    const auto ground_success=MavlinkSettingsModel::instanceGround().try_set_param_int_impl(param_id,value);
    if(!(ground_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
        ss<<"\nAir and ground are out of sync";
        workaround::makePopupMessage(ss.str().c_str());
        return;
    }
    std::stringstream ss;
    ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value<<" ,might take up to 3 seconds until applied";
    workaround:: makePopupMessage(ss.str().c_str());
}

void SynchronizedSettings::change_param_air_only_mcs(int value)
{
    const bool air_alive=AOHDSystem::instanceAir().is_alive();
    if(!air_alive){
        workaround::makePopupMessage("Precondition: Air and Ground running and alive not given. Change not possible.");
        return;
    }
    const MavlinkSettingsModel::ExtraRetransmitParams extra_retransmit_params{std::chrono::milliseconds(100),10};
    const QString param_id=PARAM_ID_WB_MCS_INDEX;
    const auto air_success=MavlinkSettingsModel::instanceAir().try_set_param_int_impl(param_id,value,extra_retransmit_params);
    if(!(air_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
         workaround::makePopupMessage(ss.str().c_str());
        return;
    }
    std::stringstream ss;
    ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value;
    workaround:: makePopupMessage(ss.str().c_str());
}

int SynchronizedSettings::get_param_int_air_only_mcs()
{
    const QString param_id=PARAM_ID_WB_MCS_INDEX;
    const auto value_air_opt=MavlinkSettingsModel::instanceAir().try_get_param_int_impl(param_id);
    if(!value_air_opt.has_value()){
        workaround::makePopupMessage("Cannot fetch param from air");
        return -1;
    }
    return value_air_opt.value();
}

