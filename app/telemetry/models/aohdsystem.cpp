#include "aohdsystem.h"

#include "../qopenhdmavlinkhelper.hpp"
#include "../../common_consti/StringHelper.hpp"
#include "../../common_consti/TimeHelper.hpp"
#include "../telemetryutil.hpp"

#include "rcchannelsmodel.h"

#include <string>
#include <sstream>

#include <logging/logmessagesmodel.h>
#include <logging/hudlogmessagesmodel.h>


static std::string video_codec_to_string(int value){
    if(value==0)return "h264";
    if(value==1)return "h265";
    if(value==2)return "mjpeg";
    return "Unknown";
}
static QString bitrate_to_qstring(int64_t bitrate_bits_per_second){
    return QString{StringHelper::bitrate_to_string(bitrate_bits_per_second).c_str()};
}
static QString pps_to_string(int64_t packets_per_second){
    return QString((std::to_string(packets_per_second)+" pps").c_str());
}
static QString us_min_max_avg_to_string(int32_t min_us,int32_t max_us,int32_t avg_us){
    std::stringstream ss;
    ss<<"Min:"<<MyTimeHelper::R(std::chrono::microseconds(min_us))<<", ";
    ss<<"Max:"<<MyTimeHelper::R(std::chrono::microseconds(max_us));
    ss<<"Avg:"<<MyTimeHelper::R(std::chrono::microseconds(avg_us))<<", ";
    return QString(ss.str().c_str());
}
static QString min_max_avg_to_string(int32_t min,int32_t max,int32_t avg){
    std::stringstream ss;
    ss<<"min:"<<min<<", ";
    ss<<"max:"<<max<<", ";
    ss<<"avg:"<<avg;
    return QString(ss.str().c_str());
}


AOHDSystem::AOHDSystem(const bool is_air,QObject *parent)
    : QObject{parent},_is_air(is_air)
{
    m_alive_timer = new QTimer(this);
    QObject::connect(m_alive_timer, &QTimer::timeout, this, &AOHDSystem::update_alive);
    m_alive_timer->start(1000);
}

AOHDSystem &AOHDSystem::instanceAir()
{
    static AOHDSystem air(true);
    return air;
}

AOHDSystem &AOHDSystem::instanceGround()
{
    static AOHDSystem ground(false);
    return ground;
}

void AOHDSystem::register_for_qml(QQmlContext *qml_context)
{
    qml_context->setContextProperty("_ohdSystemAir", &AOHDSystem::instanceAir());
    qml_context->setContextProperty("_ohdSystemGround", &AOHDSystem::instanceGround());
}

bool AOHDSystem::process_message(const mavlink_message_t &msg)
{
    if(msg.sysid != get_own_sys_id()){
        qDebug()<<"AOHDSystem::process_message: wron sys id";
        return false;
    }
    switch(msg.msgid){
        case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE:{
            mavlink_openhd_version_message_t parsedMsg;
            mavlink_msg_openhd_version_message_decode(&msg,&parsedMsg);
            QString version(parsedMsg.version);
            set_openhd_version(version);
            return true;
        }break;
        case MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS:{
            mavlink_onboard_computer_status_t parsedMsg;
            mavlink_msg_onboard_computer_status_decode(&msg,&parsedMsg);
            process_onboard_computer_status(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_CARD:{
            mavlink_openhd_stats_monitor_mode_wifi_card_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_card_decode(&msg,&parsedMsg);
            //qDebug()<<"Got MAVLINK_MSG_ID_OPENHD_WIFI_CARD"<<(int)parsedMsg.card_index<<" "<<(int)parsedMsg.signal_millidBm;
            process_x0(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_LINK:{
            mavlink_openhd_stats_monitor_mode_wifi_link_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_link_decode(&msg,&parsedMsg);
            process_x1(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_TELEMETRY:{
            mavlink_openhd_stats_telemetry_t parsedMsg;
            mavlink_msg_openhd_stats_telemetry_decode(&msg,&parsedMsg);
            process_x2(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_AIR:{
            mavlink_openhd_stats_wb_video_air_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_air_decode(&msg,&parsedMsg);
            process_x3(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_GROUND:{
            mavlink_openhd_stats_wb_video_ground_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_ground_decode(&msg,&parsedMsg);
            process_x4(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_ONBOARD_COMPUTER_STATUS_EXTENSION:{
            mavlink_openhd_onboard_computer_status_extension_t parsedMsg;
            mavlink_msg_openhd_onboard_computer_status_extension_decode(&msg,&parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_HEARTBEAT:{
            mavlink_heartbeat_t parsedMsg;
            mavlink_msg_heartbeat_decode(&msg,&parsedMsg);
            const auto time_millis=QOpenHDMavlinkHelper::getTimeMilliseconds();
            set_last_openhd_heartbeat(time_millis);
            if(parsedMsg.autopilot!=MAV_AUTOPILOT_INVALID){
                qDebug()<<"Warning OpenHD systems should always set autopilot to none";
            }
            return true;
        }break;
        case MAVLINK_MSG_ID_RC_CHANNELS_OVERRIDE:{
             mavlink_rc_channels_override_t parsedMsg;
             mavlink_msg_rc_channels_override_decode(&msg,&parsedMsg);
             RCChannelsModel::instanceGround().update_all_channels(mavlink_msg_rc_channels_override_to_array(parsedMsg));
             return true;
        };break;
        case MAVLINK_MSG_ID_STATUSTEXT:{
             mavlink_statustext_t parsedMsg;
             mavlink_msg_statustext_decode(&msg,&parsedMsg);
             auto tmp=Telemetryutil::statustext_convert(parsedMsg);
             LogMessagesModel::instance().addLogMessage(_is_air ? "OHD[A]":"OHD[G]",tmp.message.c_str(),tmp.level);
             return true;
        }break;
        /*case MAVLINK_MSG_ID_OPENHD_LOG_MESSAGE:{
            mavlink_openhd_log_message_t parsedMsg;
            mavlink_msg_openhd_log_message_decode(&msg,&parsedMsg);
            const QString message{parsedMsg.text};
            const quint64 timestamp=parsedMsg.timestamp;
            const quint8 severity=parsedMsg.severity;
            qDebug()<<"Log message:"<<message;
            LogMessagesModel::instance().addLogMessage({"OHD",message,timestamp,LogMessagesModel::log_severity_to_color(severity)});
            break;
        }*/
    }
    return false;
}

void AOHDSystem::process_onboard_computer_status(const mavlink_onboard_computer_status_t &msg)
{
    set_curr_cpuload_perc(msg.cpu_cores[0]);
    set_curr_soc_temp_degree(msg.temperature_core[0]);
    // temporary, we repurpose this value
    set_curr_cpu_freq_mhz(msg.storage_type[0]);
    set_curr_isp_freq_mhz(msg.storage_type[1]);
    set_curr_h264_freq_mhz(msg.storage_type[2]);
    set_curr_core_freq_mhz(msg.storage_type[3]);
}

void AOHDSystem::process_x0(const mavlink_openhd_stats_monitor_mode_wifi_card_t &msg){
    if(_is_air && msg.card_index>1){
        qDebug()<<"Air only has 1 wifibroadcats card";
        return;
    }
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_card_t";
    set_wifi_adapter(msg.card_index,msg.count_p_received,msg.rx_rssi,true);
}

void AOHDSystem::process_x1(const mavlink_openhd_stats_monitor_mode_wifi_link_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_link_t";
    set_curr_rx_packet_loss_perc(msg.curr_rx_packet_loss_perc);
    set_count_tx_inj_error_hint(msg.count_tx_inj_error_hint);
    set_count_tx_dropped_packets(msg.count_tx_dropped_packets);
}

void AOHDSystem::process_x2(const mavlink_openhd_stats_telemetry_t &msg)
{
    //qDebug()<<"Got mavlink_openhd_stats_telemetry_t";
    set_curr_telemetry_rx_pps(pps_to_string(msg.curr_rx_pps));
    set_curr_telemetry_tx_pps(pps_to_string(msg.curr_tx_pps));
    set_curr_telemetry_rx_bps(bitrate_to_qstring(msg.curr_rx_bps));
    set_curr_telemetry_tx_bps(bitrate_to_qstring(msg.curr_tx_bps));
}

void AOHDSystem::process_x3(const mavlink_openhd_stats_wb_video_air_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_air_t";
    if(!_is_air){
        qDebug()<<"warning got mavlink_openhd_stats_wb_video_air from ground";
        return;
    }
    // r.n we only suport stats for the primary video stream
    if(msg.link_index!=0)return;
    set_curr_video0_measured_encoder_bitrate(bitrate_to_qstring(msg.curr_measured_encoder_bitrate));
    set_curr_video0_injected_bitrate(bitrate_to_qstring(msg.curr_injected_bitrate));
    set_curr_video0_injected_pps(pps_to_string(msg.curr_injected_pps));
    set_curr_video0_dropped_packets(msg.curr_dropped_packets);
    set_curr_video0_fec_encode_time_avg_min_max(
                us_min_max_avg_to_string(msg.curr_fec_encode_time_min_us,msg.curr_fec_encode_time_max_us,msg.curr_fec_encode_time_avg_us));
    set_curr_video0_fec_block_length_min_max_avg(
                min_max_avg_to_string(msg.curr_fec_block_size_min,msg.curr_fec_block_size_max,msg.curr_fec_block_size_avg));
    // dirty
    if(x_last_dropped_packets<0){
        x_last_dropped_packets=msg.curr_dropped_packets;
    }else{
        const auto delta=msg.curr_dropped_packets-x_last_dropped_packets;
        x_last_dropped_packets=msg.curr_dropped_packets;
        if(delta>0){
            set_tx_is_currently_dropping_packets(true);
        }else{
            set_tx_is_currently_dropping_packets(false);
        }
    }
}

void AOHDSystem::process_x4(const mavlink_openhd_stats_wb_video_ground_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_ground_t";
    if(_is_air){
         qDebug()<<"warning got mavlink_openhd_stats_wb_video_ground from air";
         return;
    }
    // r.n we only suport stats for the primary video stream
    if(msg.link_index!=0)return;
    set_curr_video0_received_bitrate_with_fec(bitrate_to_qstring(msg.curr_incoming_bitrate));
    set_video0_count_blocks_lost(msg.count_blocks_lost);
    set_video0_count_blocks_recovered(msg.count_blocks_recovered);
    set_video0_count_fragments_recovered(msg.count_fragments_recovered);
    set_video0_count_blocks_total(msg.count_blocks_total);
    set_curr_video0_fec_decode_time_avg_min_max(
                us_min_max_avg_to_string(msg.curr_fec_decode_time_min_us,msg.curr_fec_decode_time_max_us,msg.curr_fec_decode_time_avg_us));
}


void AOHDSystem::set_last_openhd_heartbeat(qint64 last_openhd_heartbeat) {
    m_last_openhd_heartbeat = last_openhd_heartbeat;
    emit last_openhd_heartbeat_changed(m_last_openhd_heartbeat);
}

void AOHDSystem::set_wifi_adapter(uint8_t index, unsigned int received_packet_count, int current_signal_dbm, int signal_good)
{
    if(index==0){
        set_wifi_adapter0(received_packet_count,current_signal_dbm,signal_good);
    }else if(index==1){
        set_wifi_adapter1(received_packet_count,current_signal_dbm,signal_good);
    }else if(index==2){
        set_wifi_adapter2(received_packet_count,current_signal_dbm,signal_good);
    }else if(index==3){
        set_wifi_adapter3(received_packet_count,current_signal_dbm,signal_good);
    }else{
        qDebug()<<"wifi adapter error index unsuported:"<<index;
    }
    //qDebug()<<QString::fromStdString(m_wifi_adapters[0].to_string(0));
}

//  TODO register qt struct and make it nice
void AOHDSystem::set_wifi_adapter0(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[0].received_packet_count=received_packet_count;
    m_wifi_adapters[0].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[0].signal_good=signal_good;
    emit wifi_adapter0_changed(received_packet_count,current_signal_dbm,signal_good);
    // TODO figure out a way to calculate the best rssi
    set_best_rx_rssi(current_signal_dbm);
}
void AOHDSystem::set_wifi_adapter1(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[1].received_packet_count=received_packet_count;
    m_wifi_adapters[1].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[1].signal_good=signal_good;
    emit wifi_adapter1_changed(received_packet_count,current_signal_dbm,signal_good);
}
void AOHDSystem::set_wifi_adapter2(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[2].received_packet_count=received_packet_count;
    m_wifi_adapters[2].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[2].signal_good=signal_good;
    emit wifi_adapter2_changed(received_packet_count,current_signal_dbm,signal_good);
}
void AOHDSystem::set_wifi_adapter3(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[3].received_packet_count=received_packet_count;
    m_wifi_adapters[3].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[3].signal_good=signal_good;
    emit wifi_adapter3_changed(received_packet_count,current_signal_dbm,signal_good);
}

void AOHDSystem::set_gpio(QList<int> gpio){
    m_gpio = gpio;
    emit gpio_changed(m_gpio);
}

void AOHDSystem::set_curr_set_video_bitrate_int(int value){
    auto tmp=std::to_string(value)+" MBit/s";
    set_curr_set_video_bitrate(tmp.c_str());
}

void AOHDSystem::set_curr_set_video_codec_int(int value){
    auto tmp=video_codec_to_string(value);
    set_curr_set_video_codec(tmp.c_str());
}

void AOHDSystem::update_alive()
{
    if(m_last_openhd_heartbeat==-1){
        set_is_alive(false);
    }else{
        const auto elapsed_since_last_heartbeat=QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_openhd_heartbeat;
        // after 3 seconds, consider as "not alive"
        const bool alive=elapsed_since_last_heartbeat< 3*1000;
        if(alive != m_is_alive){
            // message when state changes
            HUDLogMessagesModel::Element message;
            message.severity=3;
            if(_is_air){
                message.message="Air unit ";
            }else{
                message.message="Ground unit ";
            }
            if(alive){
                message.message+="found";
            }else{
                message.message+="lost";
            }
            HUDLogMessagesModel::instance().addData(message);
            //
            set_is_alive(alive);
        }
    }
    {
        // If we don't get any bitrate updates, after 5 seconds go back to default
        const auto delta=std::chrono::steady_clock::now()-m_last_message_openhd_stats_total_all_wifibroadcast_streams;
        if(delta>std::chrono::seconds(5)){
            //TODO clear curr values
        }
    }
}

bool AOHDSystem::send_command_long(mavsdk::Action::CommandLong command)
{
    if(!_action){
        return false;
    }
    const auto res=_action->send_command_long(command);
    assert(command.target_system_id==get_own_sys_id());
    std::stringstream ss;
    ss<<"Action: "<<res;
    qDebug()<<QString(ss.str().c_str());
    if(res==mavsdk::Action::Result::Success){
        return true;
    }
    return false;
}


void AOHDSystem::set_system(std::shared_ptr<mavsdk::System> system)
{
    // once discovered, the system never changes !
    assert(_system==nullptr);
    assert(system->get_system_id()==get_own_sys_id());
    _system=system;
    _action=std::make_shared<mavsdk::Action>(system);
}

bool AOHDSystem::send_command_reboot(bool reboot)
{
    mavsdk::Action::CommandLong command{};
    command.target_system_id= get_own_sys_id();
    command.target_component_id=0; // unused r.n
    command.command=MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN;
    command.params.maybe_param1=0;
    command.params.maybe_param2=(reboot ? 1 : 2);
    return send_command_long(command);
}

bool AOHDSystem::send_command_restart_interface()
{
     mavsdk::Action::CommandLong command{};
     command.target_system_id= get_own_sys_id();
     command.target_component_id=0; // unused r.n
     command.command=MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN;
     // dirty, we use component action
     command.params.maybe_param1=0;
     command.params.maybe_param2=0;
     command.params.maybe_param3=1;
     return send_command_long(command);
}

AOHDSystem::RC_CHANNELS AOHDSystem::mavlink_msg_rc_channels_override_to_array(const mavlink_rc_channels_override_t &parsedMsg)
{
    RC_CHANNELS ret{};
    ret[0]=parsedMsg.chan1_raw;
    ret[1]=parsedMsg.chan2_raw;
    ret[2]=parsedMsg.chan3_raw;
    ret[3]=parsedMsg.chan4_raw;
    ret[4]=parsedMsg.chan5_raw;
    ret[5]=parsedMsg.chan6_raw;
    ret[6]=parsedMsg.chan7_raw;
    ret[7]=parsedMsg.chan8_raw;
    ret[8]=parsedMsg.chan9_raw;
    ret[9]=parsedMsg.chan10_raw;
    ret[10]=parsedMsg.chan11_raw;
    ret[11]=parsedMsg.chan12_raw;
    ret[12]=parsedMsg.chan13_raw;
    ret[13]=parsedMsg.chan14_raw;
    ret[14]=parsedMsg.chan15_raw;
    ret[15]=parsedMsg.chan16_raw;
    ret[16]=parsedMsg.chan17_raw;
    ret[17]=parsedMsg.chan18_raw;
    return ret;
}
