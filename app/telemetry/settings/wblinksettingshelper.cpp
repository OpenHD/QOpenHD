#include "wblinksettingshelper.h"

#include "../models/aohdsystem.h"
#include "mavlinksettingsmodel.h"

#include "../../util/WorkaroundMessageBox.h"
#include "../logging/hudlogmessagesmodel.h"
#include "../logging/logmessagesmodel.h"
#include <qsettings.h>
#include <sstream>
#include "../action/ohdaction.h"

WBLinkSettingsHelper::WBLinkSettingsHelper(QObject *parent)
    : QObject{parent}
{
}

WBLinkSettingsHelper& WBLinkSettingsHelper::instance()
{
    static WBLinkSettingsHelper tmp;
    return tmp;
}

bool WBLinkSettingsHelper::start_analyze_channels()
{
    if(OHDAction::instance().send_command_analyze_channels_blocking()){
        set_progress_analyze_channels_perc(0);
        set_text_for_qml("Analyzing");
        return true;
    }
    return false;
}

bool WBLinkSettingsHelper::start_scan_channels(int freq_bands,int channel_widths)
{
    if(OHDAction::instance().send_command_start_scan_channels_blocking(freq_bands,channel_widths)){
        set_progress_scan_channels_perc(0);
        set_text_for_qml("Scanning");
        return true;
    }
    return false;
}


void WBLinkSettingsHelper::validate_and_set_channel_mhz(int channel_mhz)
{
    if(channel_mhz<=1000 || channel_mhz>=8000){
        qDebug()<<"Invalid channel "<<channel_mhz<<"Mhz";
        return;
    }
    if(!m_has_valid_ground_channel_data){
        // Ground channel data not available yet
        return;
    }
    if(m_curr_channel_mhz!=channel_mhz){
        qDebug()<<"Changing channel from "<<m_curr_channel_mhz<<" to "<<channel_mhz;
        set_curr_channel_mhz(channel_mhz);
        signal_ui_rebuild_model_when_possible();
    }
}

void WBLinkSettingsHelper::validate_and_set_channel_width_mhz(int channel_width_mhz)
{
    if(!(channel_width_mhz==20 || channel_width_mhz==40 || channel_width_mhz==80)){
        qDebug()<<"Invalid channel width "<<channel_width_mhz<<" Mhz";
        return;
    }
    if(!m_has_valid_ground_channel_data){
        // Ground channel data not available yet
        return;
    }
    if(m_curr_channel_width_mhz!=channel_width_mhz){
        qDebug()<<"Changing channel width from "<<m_curr_channel_width_mhz<<" to "<<channel_width_mhz;
        set_curr_channel_width_mhz(channel_width_mhz);
        signal_ui_rebuild_model_when_possible();
    }
}

void WBLinkSettingsHelper::process_message_openhd_wifibroadcast_supported_channels(const mavlink_openhd_wifbroadcast_supported_channels_t &msg)
{
    std::vector<uint16_t> channels;
    for(int i=0;i<60;i++){
        if(msg.channels[i]==0)break;
        channels.push_back(msg.channels[i]);
    }
    if(channels.empty()){
        qDebug()<<"No valid channels from ground station - should never happen";
        return;
    }
    // We have valid supported channels datat
    if(m_has_valid_ground_channel_data==false){
        m_supported_channels=channels;
        m_has_valid_ground_channel_data=true;
        qDebug()<<"Got valid ground channel data";
        signal_ui_rebuild_model_when_possible();
    }

}

void WBLinkSettingsHelper::process_message_openhd_wifibroadcast_analyze_channels_progress(const mavlink_openhd_wifbroadcast_analyze_channels_progress_t &msg)
{
    {
        std::stringstream ss;
        ss<<"Analyzed "<<(int)msg.channel_mhz<<"@"<<(int)msg.channel_width_mhz;
        //ss<<" Foreign:"<<(int)msg.foreign_packets<<"packets";
        ss<<" Progress:"<<(int)msg.progress<<"%";
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
    }
    //qDebug()<<"Got progress "<<msg.channel_mhz<<"@"<<msg.channel_width_mhz<<"Mhz "<<msg.progress<<"%";
    std::stringstream ss;
    ss<<"Analyzed "<<(int)msg.channel_mhz<<"@"<<(int)msg.channel_width_mhz<<"Mhz, ";
    ss<<" Foreign packets:"<<msg.foreign_packets<<" ";
    if(msg.progress>=100){
        ss<<"100%, Done";
    }else{
        ss<<(int)msg.progress<<"%";
    }
    qDebug()<<ss.str().c_str();
    set_progress_analyze_channels_perc(msg.progress);
    set_text_for_qml(ss.str().c_str());
    update_pollution(msg.channel_mhz,msg.foreign_packets);
    // signal to the UI to rebuild model
    signal_ui_rebuild_model_when_possible();
}

void WBLinkSettingsHelper::process_message_openhd_wifibroadcast_scan_channels_progress(const mavlink_openhd_wifbroadcast_scan_channels_progress_t &msg)
{
    {
        std::stringstream ss;
        ss<<"Scanned "<<(int)msg.channel_mhz<<"@"<<(int)msg.channel_width_mhz;
        ss<<" Progress:"<<(int)msg.progress<<"%";
        if(msg.success){
            ss<<"-SUCCESS";
        }else{
            ss<<"-NOT FOUND";
        }
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        qDebug()<<ss.str().c_str();
        set_text_for_qml(ss.str().c_str());
    }
    set_progress_scan_channels_perc(msg.progress);
}

int WBLinkSettingsHelper::change_param_air_and_ground(QString param_id,int value)
{
    qDebug()<<"SynchronizedSettings::change_param_air_and_ground: "<<param_id<<":"<<value;
    // sanity checking
    if(!AOHDSystem::instanceGround().is_alive()){
        qDebug()<<"Precondition: Ground running and alive not given. Change not possible.";
        return -1;
    }
    if(!AOHDSystem::instanceAir().is_alive()){
        qDebug()<<"Precondition: Air running and alive not given. Change not possible.";
        return -2;
    }
    // First change it on the air and wait for ack - if failed, return. We do 3 retransmission(s) until acked so it is really unlikely that
    // we set the value and all 3 ack's are lost (which would be the generals problem and then the frequenies are out of sync).
    const auto air_success=MavlinkSettingsModel::instanceAir().try_set_param_int_impl(param_id,value);
    if(!(air_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
        qDebug()<<ss.str().c_str();
        if(air_success==MavlinkSettingsModel::SetParamResult::VALUE_UNSUPPORTED){
            return -4;
        }else{
            return -3;
        }
    }
    // we have changed the value on air, now change the ground
    // It is highly unlikely that fauls - if it does, we have an issue ! (2 generals problem)
    const auto ground_success=MavlinkSettingsModel::instanceGround().try_set_param_int_impl(param_id,value);
    if(!(ground_success==MavlinkSettingsModel::SetParamResult::SUCCESS)){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(air_success);
        qWarning("%s", ss.str().c_str());
        return -5;
    }
    std::stringstream ss;
    ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value<<" ,might take up to 3 seconds until applied";
    qDebug()<<ss.str().c_str();
    return 0;
}

bool WBLinkSettingsHelper::change_param_ground_only(QString param_id, int value)
{
    const auto ground_success=MavlinkSettingsModel::instanceGround().try_set_param_int_impl(param_id,value);
    if(ground_success==MavlinkSettingsModel::SetParamResult::SUCCESS){
        qDebug()<<"change_param_ground_only success "<<param_id<<":"<<value;
        return true;
    }
    qDebug()<<"change_param_ground_only failure "<<param_id<<":"<<value<<" -"<<MavlinkSettingsModel::set_param_result_as_string(ground_success).c_str();
    return false;
}


struct FrequencyItem{
    int channel_nr=0;
    int frequency=0;
    bool radar=false;
};
static std::vector<FrequencyItem> get_freq_descr(){
    std::vector<FrequencyItem> ret{
        FrequencyItem{-1,2312},
        FrequencyItem{-1,2332},
        FrequencyItem{-1,2352},
        FrequencyItem{-1,2372},
        FrequencyItem{-1,2392},
        // ACTUAL 2G
        FrequencyItem{1,2412},
        FrequencyItem{5,2432},
        FrequencyItem{9,2452},
        FrequencyItem{13,2472},
        FrequencyItem{14,2484},
        // ACTUAL 2G end
        FrequencyItem{-1,2492},
        FrequencyItem{-1,2512},
        FrequencyItem{-1,2532},
        FrequencyItem{-1,2572},
        FrequencyItem{-1,2592},
        FrequencyItem{-1,2612},
        FrequencyItem{-1,2632},
        FrequencyItem{-1,2652},
        FrequencyItem{-1,2672},
        FrequencyItem{-1,2692},
        FrequencyItem{-1, 2712},
        // 5G begin
        FrequencyItem{ 32,5160},
        FrequencyItem{ 36,5180},
        FrequencyItem{40,5200},
        FrequencyItem{ 44,5220},
        FrequencyItem{ 48,5240},
        FrequencyItem{ 52,5260,true},
        FrequencyItem{ 56,5280,true},
        FrequencyItem{ 60,5300,true},
        FrequencyItem{ 64,5320,true},
        // exp - probably illegal part
        //FrequencyItem{"5380Mhz [76]  (NOT ALLOWED)",5380},
        //
        FrequencyItem{100,5500,true},
        FrequencyItem{104,5520,true},
        FrequencyItem{108,5540,true},
        FrequencyItem{112,5560,true},
        FrequencyItem{116,5580,true},
        FrequencyItem{120,5600,true},
        FrequencyItem{124,5620,true},
        FrequencyItem{128,5640,true},
        FrequencyItem{132,5660,true},
        FrequencyItem{136,5680,true},
        FrequencyItem{140,5700,true},
        FrequencyItem{144,5720,true},
        // Here is the weird break
        FrequencyItem{149,5745},
        FrequencyItem{153,5765},
        FrequencyItem{157,5785},
        FrequencyItem{161,5805},
        FrequencyItem{165,5825},
        // Depends
        FrequencyItem{169,5845},
        FrequencyItem{173,5865},
        FrequencyItem{177,5885},
        FrequencyItem{181,5905}
    };
    return ret;
}

static FrequencyItem find_frequency_item(const int frequency){
    const auto frequency_items=get_freq_descr();
    for(const auto& item:frequency_items){
        if(item.frequency==frequency)return item;
    }
    return FrequencyItem{-1,-1,false};
}



int WBLinkSettingsHelper::get_next_supported_frequency(int index)
{
    const auto tmp=m_supported_channels;
    if(index<m_supported_channels.size()){
        const auto frequency=m_supported_channels[index];
        //qDebug()<<"Index:"<<index<<" freq"<<frequency;
        return frequency;
    }
    return -1;
}

static std::string spaced_string(int number){
    std::stringstream ss;
    if(number<100)ss<<" ";
    if(number<10)ss<<" ";
    ss<<number;
    return ss.str();
}

QString WBLinkSettingsHelper::get_frequency_description(int frequency_mhz)
{
    auto frequency_item=find_frequency_item(frequency_mhz);
    std::stringstream ss;
    const bool is_2g=frequency_mhz<3000;
    if(is_2g){
        //ss<<"2.4G ";
    }else{
        //ss<<"5.8G ";
    }
    ss<<"["<<spaced_string(frequency_item.channel_nr)<<"] ";
    ss<<frequency_mhz<<"Mhz ";
    //if(frequency_item.channel_nr==-1){
    //    ss<<"(ATH) ";
    //}
    if(frequency_item.radar){
        ss<<"(DFS RADAR)";
    }
    return ss.str().c_str();
}

int WBLinkSettingsHelper::get_frequency_pollution(int frequency_mhz)
{
    auto pollution=get_pollution_for_frequency_channel_width(frequency_mhz,40);
    if(pollution.has_value()){
        return pollution.value().n_foreign_packets;
    }
    return -1;
}

void WBLinkSettingsHelper::log_result_message(const std::string &result_message, bool use_hud)
{
    if(use_hud){
        HUDLogMessagesModel::instance().add_message_info(result_message.c_str());
    }else{
       WorkaroundMessageBox::makePopupMessage(result_message.c_str());
    }
}

void WBLinkSettingsHelper::update_pollution(int frequency, int n_foreign_packets)
{
    for(int i=0;i<m_pollution_elements.size();i++){
       if(m_pollution_elements.at(i).frequency_mhz==frequency){
            m_pollution_elements[i].n_foreign_packets=n_foreign_packets;
       }
    }
    m_pollution_elements.push_back(PollutionElement{frequency,40,n_foreign_packets});
}

std::optional<WBLinkSettingsHelper::PollutionElement> WBLinkSettingsHelper::get_pollution_for_frequency_channel_width(int frequency, int width)
{
    for(int i=0;i<m_pollution_elements.size();i++){
       if(m_pollution_elements.at(i).frequency_mhz==frequency){
            return m_pollution_elements[i];
       }
    }
    return std::nullopt;
}

void WBLinkSettingsHelper::signal_ui_rebuild_model_when_possible()
{
    if(m_curr_channel_mhz>0 && m_curr_channel_width_mhz>0 && m_has_valid_ground_channel_data){
       qDebug()<<"Signal UI Ready & should rebuild "<<m_curr_channel_mhz<<":"<<m_curr_channel_width_mhz<<"Mhz "<<m_has_valid_ground_channel_data;
       set_ui_rebuild_models(m_ui_rebuild_models+1);
    }else{
       qDebug()<<"Signal UI Not ready yet "<<m_curr_channel_mhz<<":"<<m_curr_channel_width_mhz<<"Mhz "<<m_has_valid_ground_channel_data;
    }
}
