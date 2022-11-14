#include "aohdsystem.h"

#include "../qopenhdmavlinkhelper.hpp"
#include "../../common_consti/StringHelper.hpp"
#include "../telemetryutil.hpp"

#include "rcchannelsmodel.h"

#include <string>
#include <sstream>

#include <logging/logmessagesmodel.h>


static std::string video_codec_to_string(int value){
    if(value==0)return "h264";
    if(value==1)return "h265";
    if(value==2)return "mjpeg";
    return "Unknown";
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
        }
        case MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS:{
            mavlink_onboard_computer_status_t parsedMsg;
            mavlink_msg_onboard_computer_status_decode(&msg,&parsedMsg);
            process_x0(parsedMsg);
            return true;
            break;
        }
        case MAVLINK_MSG_ID_OPENHD_WIFIBROADCAST_WIFI_CARD:{
            mavlink_openhd_wifibroadcast_wifi_card_t parsedMsg;
            mavlink_msg_openhd_wifibroadcast_wifi_card_decode(&msg,&parsedMsg);
            //qDebug()<<"Got MAVLINK_MSG_ID_OPENHD_WIFI_CARD"<<(int)parsedMsg.card_index<<" "<<(int)parsedMsg.signal_millidBm;
            process_x1(parsedMsg);
            return true;
            break;
        }
        case MAVLINK_MSG_ID_OPENHD_STATS_TOTAL_ALL_WIFIBROADCAST_STREAMS:{
            mavlink_openhd_stats_total_all_wifibroadcast_streams_t parsedMsg;
            mavlink_msg_openhd_stats_total_all_wifibroadcast_streams_decode(&msg,&parsedMsg);
            process_x2(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_FEC_LINK_RX_STATISTICS:{
            mavlink_openhd_fec_link_rx_statistics_t parsedMsg;
            mavlink_msg_openhd_fec_link_rx_statistics_decode(&msg,&parsedMsg);
            process_x3(parsedMsg);
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

void AOHDSystem::process_x0(const mavlink_onboard_computer_status_t &msg)
{
    set_cpuload(msg.cpu_cores[0]);
    set_temp(msg.temperature_core[0]);
    // temporary, we repurpose this value
    set_curr_cpu_freq_mhz(msg.storage_type[0]);
    set_curr_isp_freq_mhz(msg.storage_type[1]);
    set_curr_h264_freq_mhz(msg.storage_type[2]);
    set_curr_core_freq_mhz(msg.storage_type[3]);
}

void AOHDSystem::process_x1(const mavlink_openhd_wifibroadcast_wifi_card_t &msg)
{
    if(_is_air && msg.card_index>1){
        qDebug()<<"Air only has 1 wifibroadcats card";
        return;
    }
    set_wifi_adapter(msg.card_index,msg.count_p_received,msg.rx_rssi,true);
}

void AOHDSystem::process_x2(const mavlink_openhd_stats_total_all_wifibroadcast_streams_t &msg)
{
    m_last_message_openhd_stats_total_all_wifibroadcast_streams=std::chrono::steady_clock::now();
    {
        set_curr_incoming_tele_bitrate(QString(StringHelper::bitrate_to_string(msg.curr_telemetry_rx_bps).c_str()));
        auto total_rx_bitrate=msg.curr_telemetry_rx_bps;
        if(!_is_air){
            // ground
            total_rx_bitrate+=msg.curr_video0_bps;
            total_rx_bitrate+=msg.curr_video1_bps;
            set_curr_incoming_video_bitrate(QString(StringHelper::bitrate_to_string(msg.curr_video0_bps).c_str()));
        }else{
            set_curr_video0_tx_pps((std::to_string(msg.curr_video0_tx_pps)+"pps").c_str());
            set_curr_video1_tx_pps((std::to_string(msg.curr_video1_tx_pps)+"pps").c_str());
        }
        set_curr_telemetry_tx_pps((std::to_string(msg.curr_telemetry_tx_pps)+"pps").c_str());
        const auto bitrate_string=StringHelper::bitrate_to_string(total_rx_bitrate);
        set_curr_incoming_bitrate(QString(bitrate_string.c_str()));
        if(_is_air){
            set_curr_outgoing_video_bitrate(StringHelper::bitrate_to_string(msg.curr_video0_bps).c_str());
        }
    }
    set_wifi_rx_packets_count(msg.count_wifi_packets_received);
    set_wifi_tx_packets_count(msg.count_wifi_packets_injected);
    {
        uint64_t total_tx_error_count=0;
        total_tx_error_count+=msg.count_telemetry_tx_injections_error_hint;
        total_tx_error_count+=msg.count_video_tx_injections_error_hint;
        set_total_tx_error_count(total_tx_error_count);
    }
    set_curr_rx_packet_loss_perc(msg.unused_0);
}

void AOHDSystem::process_x3(const mavlink_openhd_fec_link_rx_statistics_t &msg)
{
    if(!_is_air){
        if(msg.link_index==0){
             set_video_rx_blocks_lost(msg.count_blocks_lost);
             set_video_rx_blocks_recovered(msg.count_blocks_recovered);
        }
    }
}

void AOHDSystem::set_wifi_tx_packets_count(int wifi_tx_packets_count){
    m_wifi_tx_packets_count=wifi_tx_packets_count;
    emit wifi_tx_packets_count_changed(wifi_tx_packets_count);
}

void AOHDSystem::set_cpuload(int cpuload) {
    m_cpuload = cpuload;
    emit cpuload_changed(m_cpuload);
}

void AOHDSystem::set_temp(int temp) {
    m_temp = temp;
    emit temp_changed(m_temp);
}

void AOHDSystem::set_curr_cpu_freq_mhz(int curr_cpu_freq_mhz)
{
    if(m_curr_cpu_freq_mhz==curr_cpu_freq_mhz)return;
    m_curr_cpu_freq_mhz=curr_cpu_freq_mhz;
    emit curr_cpu_freq_mhz_changed(curr_cpu_freq_mhz);
}

void AOHDSystem::set_curr_isp_freq_mhz(int curr_isp_freq_mhz)
{
    if(m_curr_isp_freq_mhz==curr_isp_freq_mhz)return;
    m_curr_isp_freq_mhz=curr_isp_freq_mhz;
    emit curr_isp_freq_mhz_changed(curr_isp_freq_mhz);
}

void AOHDSystem::set_curr_h264_freq_mhz(int curr_h264_freq_mhz)
{
    if(m_curr_h264_freq_mhz==curr_h264_freq_mhz)return;
    m_curr_h264_freq_mhz=curr_h264_freq_mhz;
    emit curr_h264_freq_mhz_changed(curr_h264_freq_mhz);
}

void AOHDSystem::set_curr_core_freq_mhz(int curr_core_freq_mhz)
{
    if(m_curr_core_freq_mhz==curr_core_freq_mhz)return;
    m_curr_core_freq_mhz=curr_core_freq_mhz;
    emit curr_core_freq_mhz_changed(curr_core_freq_mhz);
}

void AOHDSystem::set_openhd_version(QString openhd_version){
    m_openhd_version=openhd_version;
    emit openhd_version_changed(openhd_version);
}

void AOHDSystem::set_last_ping_result_openhd(QString last_ping_result_openhd)
{
    m_last_ping_result_openhd=last_ping_result_openhd;
    emit last_ping_result_openhd_changed(m_last_ping_result_openhd);
}

void AOHDSystem::set_last_openhd_heartbeat(qint64 last_openhd_heartbeat) {
    m_last_openhd_heartbeat = last_openhd_heartbeat;
    emit last_openhd_heartbeat_changed(m_last_openhd_heartbeat);
}

void AOHDSystem::set_is_alive(bool alive)
{
    m_is_alive=alive;
    emit is_alive_changed(alive);
}

void AOHDSystem::set_best_rx_rssi(int best_rx_rssi)
{
    m_best_rx_rssi = best_rx_rssi;
    emit best_rx_rssi_changed(best_rx_rssi);
}

void AOHDSystem::set_wifi_rx_packets_count(int wifi_rx_packets_count){
    m_wifi_rx_packets_count=wifi_rx_packets_count;
    emit wifi_rx_packets_count_changed(wifi_rx_packets_count);
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

void AOHDSystem::set_battery_percent(int battery_percent) {
    m_battery_percent = battery_percent;
    emit battery_percent_changed(m_battery_percent);
}

void AOHDSystem::set_battery_gauge(QString battery_gauge) {
    m_battery_gauge = battery_gauge;
    emit battery_gauge_changed(m_battery_gauge);
}

void AOHDSystem::set_gpio(QList<int> gpio){
    m_gpio = gpio;
    emit gpio_changed(m_gpio);
}

void AOHDSystem::set_curr_incoming_bitrate(QString curr_incoming_bitrate)
{
    m_curr_incoming_bitrate=curr_incoming_bitrate;
    emit curr_incoming_bitrate_changed(curr_incoming_bitrate);
}

void AOHDSystem::set_curr_incoming_video_bitrate(QString curr_incoming_video_bitrate)
{
    m_curr_incoming_video_bitrate=curr_incoming_video_bitrate;
    emit curr_incoming_video_bitrate_changed(curr_incoming_video_bitrate);
}

void AOHDSystem::set_curr_incoming_tele_bitrate(QString curr_incoming_tele_bitrate)
{
    m_curr_incoming_tele_bitrate=curr_incoming_tele_bitrate;
    emit curr_incoming_tele_bitrate_changed(curr_incoming_tele_bitrate);
}

void AOHDSystem::set_curr_outgoing_video_bitrate(QString curr_outgoing_video_bitrate)
{
    m_curr_outgoing_video_bitrate=curr_outgoing_video_bitrate;
    emit curr_outgoing_video_bitrate_changed(curr_outgoing_video_bitrate);
}

void AOHDSystem::set_total_tx_error_count(int total_tx_error_count)
{
    m_total_tx_error_count=total_tx_error_count;
    emit total_tx_error_count_changed(total_tx_error_count);
}

void AOHDSystem::set_video_rx_blocks_lost(int video_rx_blocks_lost)
{
    m_video_rx_blocks_lost=video_rx_blocks_lost;
    emit video_rx_blocks_lost_changed(video_rx_blocks_lost);
}

void AOHDSystem::set_video_rx_blocks_recovered(int video_rx_blocks_recovered)
{
    m_video_rx_blocks_recovered=video_rx_blocks_recovered;
    emit video_rx_blocks_recovered_changed(video_rx_blocks_recovered);
}

void AOHDSystem::set_curr_set_video_bitrate(QString curr_set_video_bitrate)
{
    if(m_curr_set_video_bitrate==curr_set_video_bitrate)return;
    m_curr_set_video_bitrate=curr_set_video_bitrate;
    emit curr_set_video_bitrate_changed(curr_set_video_bitrate);
}

void AOHDSystem::set_curr_set_video_bitrate_int(int value){
    auto tmp=std::to_string(value)+" MBit/s";
    set_curr_set_video_bitrate(tmp.c_str());
}

void AOHDSystem::set_curr_set_video_codec(QString curr_set_video_codec)
{
    if(m_curr_set_video_codec==curr_set_video_codec)return;
    m_curr_set_video_codec=curr_set_video_codec;
    emit curr_set_video_codec_changed(curr_set_video_codec);
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
        // after 3 seconds, consider as "not alive"
        if(QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_openhd_heartbeat> 3*1000){
            set_is_alive(false);
        }else{
            set_is_alive(true);
        }
    }
    {
        // If we don't get any bitrate updates, after 5 seconds go back to default
        const auto delta=std::chrono::steady_clock::now()-m_last_message_openhd_stats_total_all_wifibroadcast_streams;
        if(delta>std::chrono::seconds(5)){
            set_curr_incoming_bitrate("Bitrate NA");
            set_curr_incoming_tele_bitrate("Bitrate NA");
            set_curr_incoming_video_bitrate("Bitrate NA");
            set_curr_outgoing_video_bitrate("Bitrate NA");
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
