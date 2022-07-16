#include "aohdsystem.h"
#include "../telemetry/qopenhdmavlinkhelper.hpp"
#include <string>
#include <sstream>

static std::string bitrate_to_string(uint64_t bits_per_second){
  const double mBits_per_second=static_cast<double>(bits_per_second)/(1000*1000);
  std::stringstream ss;
  if(mBits_per_second>1){
      ss.precision(3);
      ss<<mBits_per_second<<" mBit/s";
      return ss.str();
  }
  const double kBits_per_second=static_cast<double>(bits_per_second)/1000;
  ss.precision(3);
  ss<<kBits_per_second<<" kBit/s";
  return ss.str();
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

void AOHDSystem::process_x0(const mavlink_onboard_computer_status_t &msg)
{
    set_cpuload(msg.cpu_cores[0]);
    set_temp(msg.temperature_core[0]);
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
    {
        auto total_rx_bitrate=msg.curr_telemetry_rx_bps;
        if(!_is_air){
            // ground
            total_rx_bitrate+=msg.curr_video0_bps;
            total_rx_bitrate+=msg.curr_video1_bps;
        }
        const auto bitrate_string=bitrate_to_string(total_rx_bitrate);
        set_curr_incoming_bitrate(QString(bitrate_string.c_str()));
        if(_is_air){
            set_curr_outgoing_video_bitrate(bitrate_to_string(msg.curr_video0_bps).c_str());
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

void AOHDSystem::set_cpuload(int cpuload) {
    m_cpuload = cpuload;
    emit cpuload_changed(m_cpuload);
}

void AOHDSystem::set_temp(int temp) {
    m_temp = temp;
    emit temp_changed(m_temp);
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
}
