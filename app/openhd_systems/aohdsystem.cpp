#include "aohdsystem.h"
#include "../telemetry/qopenhdmavlinkhelper.hpp"
#include <string>

static std::string bitrate_to_string(uint64_t bits_per_second){
  const double mBits_per_second=static_cast<double>(bits_per_second)/(1000*1000);
  if(mBits_per_second>1){
    return std::to_string(mBits_per_second)+"mBit/s";
  }
  const double kBits_per_second=static_cast<double>(bits_per_second)/1000;
  return std::to_string(kBits_per_second)+"kBit/s";
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

}

void AOHDSystem::process_x2(const mavlink_openhd_stats_total_all_wifibroadcast_streams_t &msg)
{

}

void AOHDSystem::process_x3(const mavlink_openhd_fec_link_rx_statistics_t &msg)
{

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
