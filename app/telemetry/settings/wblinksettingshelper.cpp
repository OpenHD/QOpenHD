#include "wblinksettingshelper.h"
#include "../action/impl/xparam.h"

#include "../models/aohdsystem.h"

#include "../logging/hudlogmessagesmodel.h"
#include <qsettings.h>
#include <sstream>
#include "../action/ohdaction.h"
#include "../../util/qopenhd.h"

#include "pollutionhelper.h"

static void tmp_log_result(bool enable,const std::string message){
    if(enable){
        HUDLogMessagesModel::instance().add_message_info(message.c_str());
    }else{
        qDebug()<<"Not logged to HUD:"<<message.c_str();
    }
}

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
        set_analyze_progress_perc(0);
        return true;
    }
    return false;
}

bool WBLinkSettingsHelper::start_scan_channels(int freq_bands,int channel_widths)
{
    if(OHDAction::instance().send_command_start_scan_channels_blocking(freq_bands,channel_widths)){
        set_scan_progress_perc(0);
        set_scanning_text_for_ui("SCANNING");
        return true;
    }
    return false;
}


void WBLinkSettingsHelper::validate_and_set_gnd_channel_mhz(int channel_mhz)
{
    if(channel_mhz<=1000 || channel_mhz>=8000){
        qDebug()<<"Invalid channel "<<channel_mhz<<"Mhz";
        return;
    }
    if(m_curr_channel_mhz!=channel_mhz){
        qDebug()<<"Changing channel from "<<m_curr_channel_mhz<<" to "<<channel_mhz;
        set_curr_channel_mhz(channel_mhz);
        signal_ui_rebuild_model_when_possible();
    }
}

void WBLinkSettingsHelper::validate_and_set_gnd_channel_width_mhz(int channel_width_mhz)
{
    if(!(channel_width_mhz==20 || channel_width_mhz==40 || channel_width_mhz==80)){
        qDebug()<<"Invalid channel width "<<channel_width_mhz<<" Mhz";
        return;
    }
    if(m_curr_channel_width_mhz!=channel_width_mhz){
        qDebug()<<"Changing channel width from "<<m_curr_channel_width_mhz<<" to "<<channel_width_mhz;
        set_curr_channel_width_mhz(channel_width_mhz);
        signal_ui_rebuild_model_when_possible();
    }
}

void WBLinkSettingsHelper::validate_and_set_air_channel_width_mhz(int channel_width_mhz)
{
    if(!(channel_width_mhz==20 || channel_width_mhz==40 || channel_width_mhz==80)){
        qDebug()<<"Invalid channel width "<<channel_width_mhz<<" Mhz";
        return;
    }
    set_curr_air_channel_width_mhz(channel_width_mhz);
}

void WBLinkSettingsHelper::set_simplify_channels(bool enable)
{
    m_simplify_channels=enable;
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
    if(update_supported_channels(channels)){
        qDebug()<<"Supported channels changed";
        signal_ui_rebuild_model_when_possible();
    }
}

void WBLinkSettingsHelper::process_message_openhd_wifibroadcast_analyze_channels_progress(const mavlink_openhd_wifbroadcast_analyze_channels_progress_t &msg)
{
    std::vector<PollutionHelper::PollutionElement> analyzed_channels;
    for(int i=0;i<30;i++){
        if(msg.channels_mhz[i]==0){
            break;
        }
        PollutionHelper::PollutionElement tmp;
        tmp.frequency_mhz=msg.channels_mhz[i];
        tmp.n_foreign_packets=msg.foreign_packets[i];
        analyzed_channels.push_back(tmp);
    }
    if(analyzed_channels.size()==0){
        qDebug()<<"Perhaps malformed message analyze channels";
        return;
    }
    const uint16_t curr_channel_mhz=analyzed_channels[analyzed_channels.size()-1].frequency_mhz;
    const uint16_t curr_channel_width_mhz=40;
    const uint16_t curr_foreign_packets=analyzed_channels[analyzed_channels.size()-1].n_foreign_packets;
    {
        std::stringstream ss;
        ss<<"Analyzed "<<(int)curr_channel_mhz<<"@"<<(int)curr_channel_width_mhz;
        //ss<<" Foreign:"<<(int)curr_foreign_packets<<"packets";
        ss<<" Progress:"<<(int)msg.progress_perc<<"%";
        HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
    }
    //qDebug()<<"Got progress "<<msg.channel_mhz<<"@"<<msg.channel_width_mhz<<"Mhz "<<msg.progress<<"%";
    std::stringstream ss;
    ss<<"Analyzed "<<(int)curr_channel_mhz<<"@"<<(int)curr_channel_width_mhz<<"Mhz, ";
    ss<<" Foreign packets:"<<curr_foreign_packets<<" ";
    if(msg.progress_perc>=100){
        ss<<"100%, Done";
    }else{
        ss<<(int)msg.progress_perc<<"%";
    }
    qDebug()<<ss.str().c_str();
    PollutionHelper::instance().threadsafe_update(analyzed_channels);
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
        if(msg.progress==100){
            if(msg.success){
                std::stringstream ss2;
                ss2<<"Found air unit "<<(int)msg.channel_mhz<<"@"<<(int)msg.channel_width_mhz;
                set_scanning_text_for_ui(ss2.str().c_str());
            }else{
                std::stringstream ss2;
                ss2<<"Couldn't find air unit";
                set_scanning_text_for_ui(ss2.str().c_str());
            }
        }else{
            std::stringstream ss2;
            ss2<<"Scanning "<<(int)msg.channel_mhz<<"@"<<(int)msg.channel_width_mhz;
            set_scanning_text_for_ui(ss2.str().c_str());
        }
    }
    set_scan_progress_perc(msg.progress);
}

int WBLinkSettingsHelper::change_param_air_and_ground_blocking(QString param_id,int value)
{
    qDebug()<<"SynchronizedSettings::change_param_air_and_ground: "<<param_id<<":"<<value;
    // First change it on the air and wait for ack - if failed, return. We do a lot of retransmissions to make it unlikely that fails
    const auto command_air=XParam::create_cmd_set_int(OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM,param_id.toStdString(),value);
    const bool air_success=XParam::instance().try_set_param_blocking(command_air,std::chrono::milliseconds(100),20);
    if(!air_success){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" air not reached";
        qDebug()<<ss.str().c_str();
         // TODO handle ack, but rejected
        return -2;
    }
    // we have changed the value on air, now change the ground
    // It is highly unlikely that fauls - if it does, we have an issue !
    // But since qopenhd <-> openhd ground is either localhost or tcp, that should never be an issue
    const auto command_gnd=XParam::create_cmd_set_int(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM,param_id.toStdString(),value);
    const bool ground_success=XParam::instance().try_set_param_blocking(command_gnd,std::chrono::milliseconds(200),5);
    if(!ground_success){
        std::stringstream ss;
        ss<<"Cannot change "<<param_id.toStdString()<<" to "<<value<<" (gnd failed)";
        qWarning("%s", ss.str().c_str());
        return -3;
    }
    std::stringstream ss;
    ss<<"Successfully changed "<<param_id.toStdString()<<" to "<<value<<" ,might take up to 3 seconds until applied";
    qDebug()<<ss.str().c_str();
    return 0;
}

bool WBLinkSettingsHelper::change_param_ground_only_blocking(QString param_id, int value)
{
    const auto command_gnd=XParam::create_cmd_set_int(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM,param_id.toStdString(),value);
    const bool ground_success=XParam::instance().try_set_param_blocking(command_gnd,std::chrono::milliseconds(200),5);
    if(ground_success){
        qDebug()<<"change_param_ground_only success "<<param_id<<":"<<value;
        return true;
    }
    qDebug()<<"change_param_ground_only failure "<<param_id<<":"<<value;
    return false;
}


struct FrequencyItem{
    int channel_nr;
    int frequency;
    bool radar;
    bool simple;
    bool recommended;
    int openhd_raceband;
};
static std::vector<FrequencyItem> get_freq_descr(){
    std::vector<FrequencyItem> ret{
        FrequencyItem{-1,2312,false,false,false,-1},
        FrequencyItem{-1,2332,false,false,false,-1},
        FrequencyItem{-1,2352,false,false,false,-1},
        FrequencyItem{-1,2372,false,false,false,-1},
        FrequencyItem{-1,2392,false,false,false,-1},
        // ACTUAL 2G
        FrequencyItem{1 ,2412,false,true,false,-1},
        FrequencyItem{5 ,2432,false,true,false,-1},
        FrequencyItem{9 ,2452,false,true,false,-1},
        FrequencyItem{13,2472,false,true,false,-1},
        FrequencyItem{14,2484,false,false,false,-1},
        // ACTUAL 2G end
        FrequencyItem{-1,2492,false,false,false,-1},
        FrequencyItem{-1,2512,false,false,false,-1},
        FrequencyItem{-1,2532,false,false,false,-1},
        FrequencyItem{-1,2572,false,false,false,-1},
        FrequencyItem{-1,2592,false,false,false,-1},
        FrequencyItem{-1,2612,false,false,false,-1},
        FrequencyItem{-1,2632,false,false,false,-1},
        FrequencyItem{-1,2652,false,false,false,-1},
        FrequencyItem{-1,2672,false,false,false,-1},
        FrequencyItem{-1,2692,false,false,false,-1},
        FrequencyItem{-1, 2712,false,false,false,-1},
        // 5G begin
        FrequencyItem{ 32,5160,false,false,false,-1},
        FrequencyItem{ 36,5180,false,true ,false,-1},
        FrequencyItem{ 40,5200,false,false,false,-1},
        FrequencyItem{ 44,5220,false,true,false,-1},
        FrequencyItem{ 48,5240,false,false,false,-1},
        FrequencyItem{ 52,5260,true,true ,false,-1},
        FrequencyItem{ 56,5280,true,false,false,-1},
        FrequencyItem{ 60,5300,true,true,false,-1},
        FrequencyItem{ 64,5320,true,false,false,-1},
        // big break / part that is not allowed
        FrequencyItem{100,5500,true,true,false,-1},
        FrequencyItem{104,5520,true,false,false,-1},
        FrequencyItem{108,5540,true,true,false,-1},
        FrequencyItem{112,5560,true,false,false,-1},
        FrequencyItem{116,5580,true,true,false,-1},
        FrequencyItem{120,5600,true,false,false,-1},
        FrequencyItem{124,5620,true,true,false,-1},
        FrequencyItem{128,5640,true,false,false,-1},
        FrequencyItem{132,5660,true,true,false,-1},
        FrequencyItem{136,5680,true,false,false,-1},
        FrequencyItem{140,5700,false,true,false,1},
        FrequencyItem{144,5720,false,false,false,-1},
        // Here is the weird break
        FrequencyItem{149,5745,false,true,true,2},
        FrequencyItem{153,5765,false,false,false,-1},
        FrequencyItem{157,5785,false,true,true,3},
        FrequencyItem{161,5805,false,false,false,-1},
        FrequencyItem{165,5825,false,true,true,4},
        // Depends
        FrequencyItem{169,5845,false,false,false,-1},
        FrequencyItem{173,5865,false,true,true,5},
        FrequencyItem{177,5885,false,false,false,-1},
        FrequencyItem{181,5905,false,false,true,-1}
    };
    return ret;
}

static FrequencyItem find_frequency_item(const int frequency){
    const auto frequency_items=get_freq_descr();
    for(const auto& item:frequency_items){
        if(item.frequency==frequency)return item;
    }
    return FrequencyItem{-1,-1,false,false,false};
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
    const auto frequency_item=find_frequency_item(frequency_mhz);
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
    //if(frequency_item.radar){
    //    ss<<"(DFS RADAR)";
    //}
    return ss.str().c_str();
}

bool WBLinkSettingsHelper::get_frequency_radar(int frequency_mhz)
{
    const auto frequency_item=find_frequency_item(frequency_mhz);
    return frequency_item.radar;
}

bool WBLinkSettingsHelper::get_frequency_simplify(int frequency_mhz)
{
    const auto frequency_item=find_frequency_item(frequency_mhz);
    return frequency_item.simple;
}

bool WBLinkSettingsHelper::get_frequency_reccommended(int frequency_mhz)
{
    const auto frequency_item=find_frequency_item(frequency_mhz);
    return frequency_item.recommended;
}

int WBLinkSettingsHelper::get_frequency_openhd_race_band(int frequency_mhz)
{
    const auto frequency_item=find_frequency_item(frequency_mhz);
    return frequency_item.openhd_raceband;
}

void WBLinkSettingsHelper::set_param_keyframe_interval_async(int keyframe_interval)
{
    change_param_air_async(OHD_COMP_ID_AIR_CAMERA_PRIMARY,"V_KEYFRAME_I",static_cast<int32_t>(keyframe_interval),"KEYFRAME");
}
void WBLinkSettingsHelper::set_param_video_resolution_framerate_async(bool primary,QString res_str)
{
    const std::string value=res_str.toStdString();
    const auto comp_id = primary ? OHD_COMP_ID_AIR_CAMERA_PRIMARY : OHD_COMP_ID_AIR_CAMERA_SECONDARY;
    change_param_air_async(comp_id,"V_FORMAT",value,"VIDEO FORMAT");
}
void WBLinkSettingsHelper::set_param_fec_percentage_async(int percent)
{
    change_param_air_async(OHD_COMP_ID_LINK_PARAM,openhd::WB_VIDEO_FEC_PERCENTAGE,static_cast<int32_t>(percent),"FEC PERCENTAGE");
}
void WBLinkSettingsHelper::set_param_air_only_mcs_async(int mcs)
{
    change_param_air_async(OHD_COMP_ID_LINK_PARAM,openhd::WB_MCS_INDEX,static_cast<int32_t>(mcs),"MCS (RATE)");
}

bool WBLinkSettingsHelper::set_param_tx_power(bool ground,bool is_tx_power_index, bool is_for_armed_state, int value)
{
    qDebug()<<"set_param_tx_power "<<(is_tx_power_index ? "IDX" : "MW")<<" "<<(is_for_armed_state ? "ARMED" : "DISARMED")<<" "<<value;
    auto& system=ground ? AOHDSystem::instanceGround() : AOHDSystem::instanceAir();
    if(!system.is_alive()){
        return false;
    }
    std::string param_id="";
    if(is_tx_power_index){
        if(is_for_armed_state){
            param_id=openhd::WB_RTL8812AU_TX_PWR_IDX_ARMED;
        }else{
            param_id=openhd::WB_RTL8812AU_TX_PWR_IDX_OVERRIDE;
        }
    }else{
        if(is_for_armed_state){
            param_id=openhd::WB_TX_POWER_MILLI_WATT_ARMED;
        }else{
            param_id=openhd::WB_TX_POWER_MILLI_WATT;
        }
    }
    const auto command=XParam::create_cmd_set_int(ground ? OHD_SYS_ID_GROUND : OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM,param_id,value);
    const auto result= XParam::instance().try_set_param_blocking(command);
    //return result==XParam::EasySetParamResult::VALUE_SUCCESS;
    return result;
}

bool WBLinkSettingsHelper::set_param_stbc_ldpc_enable_air_ground()
{
    qDebug()<<"set_param_stbc_ldpc_enable_air_ground";
    const std::string param_id_stbc=openhd::WB_ENABLE_STBC;
    const std::string param_id_ldpc=openhd::WB_ENABLE_LDPC;
    auto command=XParam::create_cmd_set_int(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM,param_id_stbc,1);
    auto result= XParam::instance().try_set_param_blocking(command);
    if(!result)return false;
    command=XParam::create_cmd_set_int(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM,param_id_ldpc,1);
    result= XParam::instance().try_set_param_blocking(command);
    if(!result)return false;
    // air
    command=XParam::create_cmd_set_int(OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM,param_id_stbc,1);
    result= XParam::instance().try_set_param_blocking(command);
    if(!result)return false;
    command=XParam::create_cmd_set_int(OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM,param_id_ldpc,1);
    result= XParam::instance().try_set_param_blocking(command);
    if(!result)return false;
    return true;
}

bool WBLinkSettingsHelper::update_supported_channels(const std::vector<uint16_t> supported_channels)
{
    std::lock_guard<std::mutex> lock(m_supported_channels_mutex);
    if(m_supported_channels!=supported_channels){
        m_supported_channels=supported_channels;
        return true;
    }
    return false;
}

bool WBLinkSettingsHelper::has_valid_reported_channel_data()
{
    std::lock_guard<std::mutex> lock(m_supported_channels_mutex);
    return !m_supported_channels.empty();
}

void WBLinkSettingsHelper::change_param_air_async(const int comp_id,const std::string param_id,std::variant<int32_t,std::string> param_value,const std::string tag)
{
    mavlink_param_ext_set_t command;
    if(std::holds_alternative<int32_t>(param_value)){
        auto value=std::get<int32_t>(param_value);
        command=XParam::create_cmd_set_int(OHD_SYS_ID_AIR,comp_id,param_id,value);
    }else{
        auto value=std::get<std::string>(param_value);
        command=XParam::create_cmd_set_string(OHD_SYS_ID_AIR,comp_id,param_id,value);
    }
    if(!AOHDSystem::instanceAir().is_alive()){
        HUDLogMessagesModel::instance().add_message_warning("Air not alive - cannot change "+QString(tag.c_str()));
        return;
    }
    auto res_cb=[tag,param_value](XParam::SetParamResult result){
        if(result.is_accepted()){
            std::stringstream ss;
            ss<<"Changed "<<tag<<" to ";
            if(std::holds_alternative<int32_t>(param_value)){
                ss<<std::get<int32_t>(param_value);
            }else{
                ss<<std::get<std::string>(param_value);
            }
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }else{
            std::stringstream ss;
            ss<<"Cannot change "<<tag<<" to ";
            if(std::holds_alternative<int32_t>(param_value)){
                ss<<std::get<int32_t>(param_value);
            }else{
                ss<<std::get<int32_t>(param_value);
            }
            ss<<",please check uplink";
            HUDLogMessagesModel::instance().add_message_warning(ss.str().c_str());
        }
    };
    const bool enqueue_success=XParam::instance().try_set_param_async(command,res_cb,nullptr,std::chrono::milliseconds(200),5);
    if(!enqueue_success){
        HUDLogMessagesModel::instance().add_message_warning("Busy - cannot change "+QString(tag.c_str())+", try again later");
        return;
    }
}

void WBLinkSettingsHelper::change_param_air_channel_width_async(int value, bool log_result)
{
    if(!AOHDSystem::instanceAir().is_alive()){
        tmp_log_result(true,"Cannot change BW, AIR not alive");
        return;
    }
    change_param_air_async(OHD_COMP_ID_LINK_PARAM,PARAM_ID_WB_CHANNEL_WIDTH,static_cast<int32_t>(value),"BWIDTH");
}

QList<int> WBLinkSettingsHelper::get_supported_frequencies()
{
    std::lock_guard<std::mutex> lock(m_supported_channels_mutex);
    QList<int> ret;
    for(auto& channel:m_supported_channels){
        ret.push_back(channel);
    }
    return ret;
}

QList<int> WBLinkSettingsHelper::get_supported_frequencies_filtered(int filter_level)
{
    auto supported_frequencies=get_supported_frequencies();
    if(filter_level<=0)return supported_frequencies;
    QList<int> ret;
    for(auto& frequency: supported_frequencies){
        if(filter_level==1){
            // 40Mhz spacing
            auto info=find_frequency_item(frequency);
            if(info.simple){
                ret.push_back(frequency);
            }
        }
    }
    return ret;
}

QStringList WBLinkSettingsHelper::pollution_frequencies_int_to_qstringlist(QList<int> frequencies)
{
    QStringList ret;
    for(auto& freq:frequencies){
        std::stringstream ss;
        ss<<freq<<"Mhz";
        ret.push_back(QString(ss.str().c_str()));
    }
    return ret;
}

QVariantList WBLinkSettingsHelper::pollution_frequencies_int_get_pollution(QList<int> frequencies,bool normalize)
{
    QVariantList ret;
    for(auto& freq: frequencies){
        auto pollution=PollutionHelper::instance().threadsafe_get_pollution_for_frequency(freq);
        if(pollution.has_value()){
            if(normalize){
                ret.push_back(static_cast<int>(pollution.value().n_foreign_packets_normalized));
            }else{
                ret.push_back(static_cast<int>(pollution.value().n_foreign_packets));
            }

        }else{
            ret.push_back(static_cast<int>(0));
        }
    }
    return ret;
}


void WBLinkSettingsHelper::signal_ui_rebuild_model_when_possible()
{
    const bool valid_ground_channel_data=has_valid_reported_channel_data();
    if(m_curr_channel_mhz>0 && m_curr_channel_width_mhz>0 && valid_ground_channel_data){
       qDebug()<<"Signal UI Ready & should rebuild "<<m_curr_channel_mhz<<":"<<m_curr_channel_width_mhz<<"Mhz valid channels:"<<valid_ground_channel_data;
       set_ui_rebuild_models(m_ui_rebuild_models+1);
    }else{
       qDebug()<<"Signal UI Not ready yet "<<m_curr_channel_mhz<<":"<<m_curr_channel_width_mhz<<"Mhz valid channels:"<<valid_ground_channel_data;
    }
}
