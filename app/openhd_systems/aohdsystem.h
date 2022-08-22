#ifndef AOHDSYSTEM_H
#define AOHDSYSTEM_H

#include <QObject>
#include <QDebug>
#include <QTimer>
#include "../telemetry/mavlink_include.h"
#include "wifiadapter.h"
#include "../telemetry/openhd_defines.hpp"
#include <array>
//
#include <mavsdk/mavsdk.h>
#include <mavsdk/plugins/action/action.h>

/**
 * Abstract OHD (Mavlink) system.
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
     uint8_t get_own_sys_id()const{
         return _is_air ? OHD_SYS_ID_AIR : OHD_SYS_ID_GROUND;
     }
public:
     //Process OpenHD custom flavour message(s) coming from either the OHD Air or Ground unit
     // Returns true if the passed message was processed (known message id), false otherwise
     bool process_message(const mavlink_message_t& msg);
private:
     // These are for handling the slight differences regarding air/ ground properly, if there are any
     // For examle, the onboard computer status is the same when coming from either air or ground,
     // but the stats total are to be interpreted slightly different for air and ground.
     void process_x0(const  mavlink_onboard_computer_status_t& msg);
     void process_x1(const mavlink_openhd_wifibroadcast_wifi_card_t& msg);
     void process_x2(const mavlink_openhd_stats_total_all_wifibroadcast_streams_t& msg);
     void process_x3(const mavlink_openhd_fec_link_rx_statistics_t& msg);
     // QT Code pegin
public:
     // these are mostly based on what rpi provides as stats
     Q_PROPERTY(int cpuload MEMBER m_cpuload WRITE set_cpuload NOTIFY cpuload_changed)
     void set_cpuload(int cpuload);
     Q_PROPERTY(int temp MEMBER m_temp WRITE set_temp NOTIFY temp_changed)
     void set_temp(int temp);
     Q_PROPERTY(int curr_cpu_freq_mhz MEMBER m_curr_cpu_freq_mhz WRITE set_curr_cpu_freq_mhz NOTIFY curr_cpu_freq_mhz_changed)
     void set_curr_cpu_freq_mhz(int curr_cpu_freq_mhz);
     Q_PROPERTY(int curr_isp_freq_mhz MEMBER m_curr_isp_freq_mhz WRITE set_curr_isp_freq_mhz NOTIFY curr_isp_freq_mhz_changed)
     void set_curr_isp_freq_mhz(int curr_isp_freq_mhz);
     Q_PROPERTY(int curr_h264_freq_mhz MEMBER m_curr_h264_freq_mhz WRITE set_curr_h264_freq_mhz NOTIFY curr_h264_freq_mhz_changed)
     void set_curr_h264_freq_mhz(int curr_h264_freq_mhz);
     Q_PROPERTY(int curr_core_freq_mhz MEMBER m_curr_core_freq_mhz WRITE set_curr_core_freq_mhz NOTIFY curr_core_freq_mhz_changed)
     void set_curr_core_freq_mhz(int curr_core_freq_mhz);
     //
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
     //
     Q_PROPERTY(QString curr_incoming_bitrate MEMBER m_curr_incoming_bitrate WRITE set_curr_incoming_bitrate NOTIFY curr_incoming_bitrate_changed)
     void set_curr_incoming_bitrate(QString curr_incoming_bitrate);
     Q_PROPERTY(QString curr_incoming_video_bitrate MEMBER m_curr_incoming_video_bitrate WRITE set_curr_incoming_video_bitrate NOTIFY curr_incoming_video_bitrate_changed)
     void set_curr_incoming_video_bitrate(QString curr_incoming_video_bitrate);
     Q_PROPERTY(QString curr_incoming_tele_bitrate MEMBER m_curr_incoming_tele_bitrate WRITE set_curr_incoming_tele_bitrate NOTIFY curr_incoming_tele_bitrate_changed)
     void set_curr_incoming_tele_bitrate(QString curr_incoming_tele_bitrate);
     //
     Q_PROPERTY(QString curr_outgoing_video_bitrate MEMBER m_curr_outgoing_video_bitrate WRITE set_curr_outgoing_video_bitrate NOTIFY curr_outgoing_video_bitrate_changed)
     void set_curr_outgoing_video_bitrate(QString curr_outgoing_video_bitrate);
     Q_PROPERTY(int total_tx_error_count MEMBER m_total_tx_error_count WRITE set_total_tx_error_count NOTIFY total_tx_error_count_changed)
     void set_total_tx_error_count(int total_tx_error_count);
     // these are only active on the ground system, since they are created by the video rx-es
     Q_PROPERTY(int video_rx_blocks_lost MEMBER m_video_rx_blocks_lost WRITE set_video_rx_blocks_lost NOTIFY video_rx_blocks_lost_changed)
     void set_video_rx_blocks_lost(int video_rx_blocks_lost);
     Q_PROPERTY(int video_rx_blocks_recovered MEMBER m_video_rx_blocks_recovered WRITE set_video_rx_blocks_recovered NOTIFY video_rx_blocks_recovered_changed)
     void set_video_rx_blocks_recovered(int video_rx_blocks_recovered);
     // NOTE: hacky right now, since it is a param but we also want to display it in the HUD
     Q_PROPERTY(QString curr_set_video_bitrate MEMBER m_curr_set_video_bitrate WRITE set_curr_set_video_bitrate NOTIFY curr_set_video_bitrate_changed)
     void set_curr_set_video_bitrate(QString curr_set_video_bitrate);
     void set_curr_set_video_bitrate_int(int value);
     Q_PROPERTY(QString curr_set_video_codec MEMBER m_curr_set_video_codec WRITE set_curr_set_video_codec NOTIFY curr_set_video_codec_changed)
     void set_curr_set_video_codec(QString curr_set_video_codec);
     void set_curr_set_video_codec_int(int value);
signals:
     void cpuload_changed(int cpuload);
     void temp_changed(int temp);
     void curr_cpu_freq_mhz_changed(int curr_cpu_freq_mhz);
     //
     void curr_isp_freq_mhz_changed(int curr_isp_freq_mhz);
     void curr_h264_freq_mhz_changed(int curr_h264_freq_mhz);
     void curr_core_freq_mhz_changed(int curr_core_freq_mhz);
     //
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
     void curr_incoming_bitrate_changed(QString curr_incoming_bitrate);
     void curr_incoming_video_bitrate_changed(QString curr_incoming_video_bitrate);
     void curr_incoming_tele_bitrate_changed(QString curr_incoming_tele_bitrate);

     void curr_outgoing_video_bitrate_changed(QString curr_outgoing_video_bitrate);
     void total_tx_error_count_changed(int total_tx_error_count);
     // only on ground
     void video_rx_blocks_lost_changed(int video_rx_blocks_lost);
     void video_rx_blocks_recovered_changed(int video_rx_blocks_recovered);
     //
     void curr_set_video_bitrate_changed(QString curr_set_video_bitrate);
     void curr_set_video_codec_changed(QString curr_set_video_codec);
public:
     bool is_alive(){return m_is_alive;}
private:
     int m_cpuload = 0;
     int m_temp = 0;
     int m_curr_cpu_freq_mhz=-1;
     int m_curr_isp_freq_mhz=-1;
     int m_curr_h264_freq_mhz=-1;
     int m_curr_core_freq_mhz=-1;
     QString m_openhd_version="NA";
     QString m_last_ping_result_openhd="NA";
     qint64 m_last_openhd_heartbeat = -1;
     bool m_is_alive=false; // see alive timer
     int m_best_rx_rssi = -127;
     int m_wifi_rx_packets_count=-1;
     int m_wifi_tx_packets_count=-1;
     int m_total_tx_error_count=-1;
     // only on ground
     int m_video_rx_blocks_lost=-1;
     int m_video_rx_blocks_recovered=-1;
     // air always has only 1 wfibroadcast card, ground can have more than one
     std::array<WifiAdapter,4> m_wifi_adapters;
     //
     int m_battery_percent = 0;
     QString m_battery_gauge = "\uf091";
     //
     QList<int> m_gpio{0};
     //
     QString m_curr_incoming_bitrate="Bitrate NA";
     QString m_curr_incoming_video_bitrate="Bitrate NA";
     QString m_curr_incoming_tele_bitrate="Bitrate NA";
     QString m_curr_outgoing_video_bitrate="Bitrate NA";
     QString m_curr_set_video_bitrate="NA";
     QString m_curr_set_video_codec="Unknown";
private:
    // Sets the alive boolean if no heartbeat / message has been received in the last X seconds
    QTimer* m_alive_timer = nullptr;
    void update_alive();
    std::chrono::steady_clock::time_point m_last_message_openhd_stats_total_all_wifibroadcast_streams=std::chrono::steady_clock::now();
    // Model / fire and forget data only end
private:
     // NOTE: Null until discovered
     std::shared_ptr<mavsdk::System> _system;
     std::shared_ptr<mavsdk::Action> _action;
     bool send_command_long(mavsdk::Action::CommandLong command);
public:
     // Set the mavlink system reference, once discovered
     void set_system(std::shared_ptr<mavsdk::System> system);
     Q_INVOKABLE bool send_command_reboot(bool reboot);
     //
     bool send_command_restart_interface();
};



#endif // AOHDSYSTEM_H
