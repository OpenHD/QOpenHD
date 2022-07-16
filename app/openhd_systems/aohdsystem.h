#ifndef AOHDSYSTEM_H
#define AOHDSYSTEM_H

#include <QObject>
#include <QDebug>
#include <QTimer>
#include "../telemetry/mavlink_include.h"
#include "wifiadapter.h"
#include <array>

/**
 * This class contains information (basically like a model) about one OpenHD Air or Ground instance (if connected).
 * A (Abstract) because it is only for functionalities that are always supported by both air and ground.
 * For example, both the air and ground unit report the CPU usage and more, and this data is made available to QT UI using a instance of this model.
 * NOTE: FC telemetry has nothing to do here, as well as air / ground specific things.
 * NOTE: In QOpenHD, there are 2 instances of this model, named "_ohdSystemGround" and "_ohdSystemAir" (registered in main)
 * They each correspond to the apropriate singleton instance (instanceGround() and instanceAir() )
 */
class AOHDSystem : public QObject
{
    Q_OBJECT
public:
    explicit AOHDSystem(const bool is_air,QObject *parent = nullptr);
     static AOHDSystem& instanceAir();
     static AOHDSystem& instanceGround();
private:
     const bool _is_air; // either true (for air) or false (for ground)
public:
     // These are for handling the slight differences regarding air/ ground properly, if there are any
     // For examle, the onboard computer status is the same when coming from either air or ground,
     // but the stats total are to be interpreted slightly different for air and ground.
     void process_x0(const  mavlink_onboard_computer_status_t& msg);
     void process_x1(const mavlink_openhd_wifibroadcast_wifi_card_t& msg);
     void process_x2(const mavlink_openhd_stats_total_all_wifibroadcast_streams_t& msg);
     void process_x3(const mavlink_openhd_fec_link_rx_statistics_t& msg);
     // QT Code pegin
public:
     Q_PROPERTY(int cpuload MEMBER m_cpuload WRITE set_cpuload NOTIFY cpuload_changed)
     void set_cpuload(int cpuload);
     Q_PROPERTY(int temp MEMBER m_temp WRITE set_temp NOTIFY temp_changed)
     void set_temp(int temp);
     Q_PROPERTY(QString m_openhd_version MEMBER m_openhd_version WRITE set_openhd_version NOTIFY openhd_version_changed)
     void set_openhd_version(QString openhd_version_);
     Q_PROPERTY(QString last_ping_result_openhd MEMBER  m_last_ping_result_openhd WRITE set_last_ping_result_openhd NOTIFY last_ping_result_openhd_changed)
     void set_last_ping_result_openhd(QString last_ping_result_openhd);
     Q_PROPERTY(qint64 last_openhd_heartbeat MEMBER m_last_openhd_heartbeat WRITE set_last_openhd_heartbeat NOTIFY last_openhd_heartbeat_changed)
     void set_last_openhd_heartbeat(qint64 last_openhd_heartbeat);
     Q_PROPERTY(bool is_alive MEMBER m_is_alive WRITE set_is_alive NOTIFY is_alive_changed)
     void set_is_alive(bool alive);
     Q_PROPERTY(int best_rx_rssi MEMBER m_best_rx_rssi WRITE set_best_rx_rssi NOTIFY best_rx_rssi_changed)
     void set_best_rx_rssi(int best_rx_rssi);
     // both air and ground report outgoing and ingoing data via the wifibroadcast interface
     Q_PROPERTY(int wifi_rx_packets_count MEMBER m_wifi_rx_packets_count WRITE set_wifi_rx_packets_count NOTIFY wifi_rx_packets_count_changed)
     void set_wifi_rx_packets_count(int wifi_rx_packets_count);
     Q_PROPERTY(int wifi_tx_packets_count MEMBER m_wifi_tx_packets_count WRITE set_wifi_tx_packets_count NOTIFY wifi_tx_packets_count_changed)
     void set_wifi_tx_packets_count(int wifi_tx_packets_count);
     //
     // calls the indexed method, we need that for qt signals to work
     void set_wifi_adapter(uint8_t index,unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void set_wifi_adapter0(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void set_wifi_adapter1(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void set_wifi_adapter2(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void set_wifi_adapter3(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     // This basically only makes sense on the ground pi, it is not the battery percentage reported by the FC
     // but the battery percentage reported by the COmpanion computer running OpenHD (if it is supported, aka for future power hat o.ä)
     Q_PROPERTY(int battery_percent MEMBER m_battery_percent WRITE set_battery_percent NOTIFY battery_percent_changed)
     void set_battery_percent(int battery_percent);
     Q_PROPERTY(QString battery_gauge MEMBER m_battery_gauge WRITE set_battery_gauge NOTIFY battery_gauge_changed)
     void set_battery_gauge(QString battery_gauge);
     // this is a placeholder for later
     Q_PROPERTY(QList<int> gpio MEMBER m_gpio WRITE set_gpio NOTIFY gpio_changed)
     void set_gpio(QList<int> gpio);
signals:
     void cpuload_changed(int cpuload);
     void temp_changed(int temp);
     void openhd_version_changed(QString openhd_version_);
     void last_ping_result_openhd_changed(QString last_ping_result_openhd);
     void last_openhd_heartbeat_changed(qint64 last_openhd_heartbeat);
     void is_alive_changed(bool alive);
     void best_rx_rssi_changed(int best_rx_rssi);
     void wifi_tx_packets_count_changed(int wifi_tx_packets_count);
     void wifi_rx_packets_count_changed(int wifi_rx_packets_count);
     // air only 1
     void wifi_adapter0_changed(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void wifi_adapter1_changed(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void wifi_adapter2_changed(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     void wifi_adapter3_changed(unsigned int received_packet_count,int current_signal_dbm,int signal_good);
     //
     void battery_percent_changed(int battery_percent);
     void battery_gauge_changed(QString battery_gauge);
     //
     void gpio_changed(QList<int> gpio);
private:
     int m_cpuload = 0;
     int m_temp = 0;
     QString m_openhd_version="NA";
     QString m_last_ping_result_openhd="NA";
     qint64 m_last_openhd_heartbeat = -1;
     bool m_is_alive=false; // see alive timer
     int m_best_rx_rssi = -127;
     int m_wifi_rx_packets_count=-1;
     int m_wifi_tx_packets_count=-1;
     // air always has only 1 wfibroadcast card, ground can have more than one
     std::array<WifiAdapter,4> m_wifi_adapters;
     //
     int m_battery_percent = 0;
     QString m_battery_gauge = "\uf091";
     //
     QList<int> m_gpio{0};
private:
    // Sets the alive boolean if no heartbeat / message has been received in the last X seconds
    QTimer* m_alive_timer = nullptr;
    void update_alive();
};

inline void AOHDSystem::set_wifi_tx_packets_count(int wifi_tx_packets_count){
    m_wifi_tx_packets_count=wifi_tx_packets_count;
    emit wifi_tx_packets_count_changed(wifi_tx_packets_count);
}

#endif // AOHDSYSTEM_H
