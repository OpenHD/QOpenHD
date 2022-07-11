#include "ohdsystemground.h"

OHDSystemGround::OHDSystemGround(QObject *parent)
    : QObject{parent}
{
    set_ground_gpio({0, 0, 0, 0, 0, 0, 0, 0});
    m_alive_timer = new QTimer(this);
    QObject::connect(m_alive_timer, &QTimer::timeout, this, &OHDSystemGround::update_alive);
    m_alive_timer->start(1000);
}

OHDSystemGround &OHDSystemGround::instance()
{
    static OHDSystemGround* instance=new OHDSystemGround();
    return *instance;
}

void OHDSystemGround::set_cpuload_gnd(int cpuload_gnd) {
    m_cpuload_gnd = cpuload_gnd;
    emit cpuload_gnd_changed(m_cpuload_gnd);
}

void OHDSystemGround::set_temp_gnd(int temp_gnd) {
    m_temp_gnd = temp_gnd;
    emit temp_gnd_changed(m_temp_gnd);
}

void OHDSystemGround::set_openhd_version_ground(QString openhd_version_ground){
    m_openhd_version_ground=openhd_version_ground;
    emit openhd_version_ground_changed(openhd_version_ground);
}

void OHDSystemGround::set_ground_gpio(QList<int> ground_gpio){
    m_ground_gpio = ground_gpio;
    emit ground_gpio_changed(m_ground_gpio);
}

void OHDSystemGround::set_ground_gpio_busy(bool ground_gpio_busy){
    m_ground_gpio_busy = ground_gpio_busy;
    emit ground_gpio_busy_changed(ground_gpio_busy);
}


void OHDSystemGround::set_ground_vin(double ground_vin) {
    m_ground_vin = ground_vin;
    emit ground_vin_changed(m_ground_vin);
}

void OHDSystemGround::set_ground_vout(double ground_vout) {
    m_ground_vout = ground_vout;
    emit ground_vout_changed(m_ground_vout);
}

void OHDSystemGround::set_ground_vbat(double ground_vbat) {
    m_ground_vbat = ground_vbat;
    emit ground_vbat_changed(m_ground_vbat);
}

void OHDSystemGround::set_ground_iout(double ground_iout) {
    m_ground_iout = ground_iout;
    emit ground_iout_changed(m_ground_iout);
}


void OHDSystemGround::set_last_ping_result_openhd_ground(QString last_ping_result_openhd_ground)
{
    m_last_ping_result_openhd_ground=last_ping_result_openhd_ground;
    emit last_ping_result_openhd_ground_changed(m_last_ping_result_openhd_ground);
}

void OHDSystemGround::set_last_openhd_heartbeat(qint64 last_openhd_heartbeat) {
    m_last_openhd_heartbeat = last_openhd_heartbeat;
    emit last_openhd_heartbeat_changed(m_last_openhd_heartbeat);
}

void OHDSystemGround::set_is_alive(bool alive)
{
    m_is_alive=alive;
    emit is_alive_changed(alive);
}

//  TODO register qt struct and make it nice
void OHDSystemGround::set_wifi_adapter0(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[0].received_packet_count=received_packet_count;
    m_wifi_adapters[0].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[0].signal_good=signal_good;
    emit wifi_adapter0_changed(received_packet_count,current_signal_dbm,signal_good);
    set_downlink_rssi(current_signal_dbm);
}
void OHDSystemGround::set_wifi_adapter1(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[1].received_packet_count=received_packet_count;
    m_wifi_adapters[1].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[1].signal_good=signal_good;
    emit wifi_adapter1_changed(received_packet_count,current_signal_dbm,signal_good);
    set_downlink_rssi(current_signal_dbm);
}
void OHDSystemGround::set_wifi_adapter2(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[2].received_packet_count=received_packet_count;
    m_wifi_adapters[2].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[2].signal_good=signal_good;
    emit wifi_adapter2_changed(received_packet_count,current_signal_dbm,signal_good);
}
void OHDSystemGround::set_wifi_adapter3(unsigned int received_packet_count, int current_signal_dbm, int signal_good){
    m_wifi_adapters[3].received_packet_count=received_packet_count;
    m_wifi_adapters[3].current_signal_dbm=current_signal_dbm;
    m_wifi_adapters[3].signal_good=signal_good;
    emit wifi_adapter3_changed(received_packet_count,current_signal_dbm,signal_good);
}

void OHDSystemGround::set_downlink_rssi(int downlink_rssi)
{
    m_downlink_rssi = downlink_rssi;
    emit downlink_rssi_changed(m_downlink_rssi);
}

void OHDSystemGround::set_ground_battery_percent(int ground_battery_percent) {
    m_ground_battery_percent = ground_battery_percent;
    emit ground_battery_percent_changed(m_ground_battery_percent);
}


void OHDSystemGround::set_ground_battery_gauge(QString ground_battery_gauge) {
    m_ground_battery_gauge = ground_battery_gauge;
    emit ground_battery_gauge_changed(m_ground_battery_gauge);
}

void OHDSystemGround::set_gnd_freq(int gnd_freq){
    m_gnd_freq = gnd_freq;
    emit gnd_freq_changed(m_gnd_freq);
}


void OHDSystemGround::set_gnd_freq_busy(bool gnd_freq_busy){
    m_gnd_freq_busy = gnd_freq_busy;
    emit gnd_freq_busy_changed(gnd_freq_busy);
}

void OHDSystemGround::update_alive()
{
    // TODO this is not correct
    if(m_last_openhd_heartbeat==-1){
        set_is_alive(false);
    }else{
        set_is_alive(false);
    }
}
