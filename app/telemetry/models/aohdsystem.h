#ifndef AOHDSYSTEM_H
#define AOHDSYSTEM_H

#include <QObject>
#include <QDebug>
#include <QTimer>
#include "../mavsdk_include.h"
#include "../openhd_defines.hpp"
#include <array>
#include <QQmlContext>
#include <atomic>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

/**
 * Abstract OHD (Mavlink) system.
 * This class contains information (basically like a model) about one OpenHD Air or Ground instance (if connected).
 * A (Abstract) because it is mostly for functionalities that are always supported by both air and ground.
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
    // Singletons for accessing the models from c++
    static AOHDSystem& instanceAir();
    static AOHDSystem& instanceGround();
    // Called in main.cpp to egister the models for qml
    static void register_for_qml(QQmlContext* qml_context);
    //Process OpenHD custom flavour message(s) coming from either the OHD Air or Ground unit
    // Returns true if the passed message was processed (known message id), false otherwise
    bool process_message(const mavlink_message_t& msg);
    // Set the mavlink system reference, once discovered
    void set_system(std::shared_ptr<mavsdk::System> system);
public: // public for QT
    // NOTE: I wrote this class before I knew about the lqutils macros, which is why they are used sparingly here
    //
    // WB / Monitor mode link statistics, generic for both air and ground (incoming / outgoing)
    L_RO_PROP(int,curr_rx_packet_loss_perc,set_curr_rx_packet_loss_perc,-1)
    L_RO_PROP(quint64,count_tx_inj_error_hint,set_count_tx_inj_error_hint,0)
    L_RO_PROP(quint64,count_tx_dropped_packets,set_count_tx_dropped_packets,0)
    // telemetry specific
    L_RO_PROP(QString,curr_telemetry_tx_pps,set_curr_telemetry_tx_pps,"-1pps")
    L_RO_PROP(QString,curr_telemetry_rx_pps,set_curr_telemetry_rx_pps,"-1pps")
    L_RO_PROP(QString,curr_telemetry_tx_bps,set_curr_telemetry_tx_bps,"-1bps")
    L_RO_PROP(QString,curr_telemetry_rx_bps,set_curr_telemetry_rx_bps,"-1bps")
    //
    // The following stats only exist on the air instance, since they are only generated by OpenHD air unit
    // for the UI, if his value is set we show a warning below the bitrate icon to the user
    // a TX dropping packets means the user set a vieo bitrate that is too high
    L_RO_PROP(bool,tx_is_currently_dropping_packets,set_tx_is_currently_dropping_packets,false)
    //
    // --------- SOC statistics, generic for both air and ground
    // based on RPI SOC
    L_RO_PROP(int,curr_cpuload_perc,set_curr_cpuload_perc,0)
    L_RO_PROP(int,curr_soc_temp_degree,set_curr_soc_temp_degree,0)
    L_RO_PROP(int,curr_cpu_freq_mhz,set_curr_cpu_freq_mhz,0)
    L_RO_PROP(int,curr_isp_freq_mhz,set_curr_isp_freq_mhz,0)
    L_RO_PROP(int,curr_h264_freq_mhz,set_curr_h264_freq_mhz,0)
    L_RO_PROP(int,curr_core_freq_mhz,set_curr_core_freq_mhz,0)
    L_RO_PROP(int,curr_v3d_freq_mhz,set_curr_v3d_freq_mhz,0)
    L_RO_PROP(int,curr_space_left_mb,set_curr_space_left_mb,0)
    L_RO_PROP(int,ram_usage_perc,set_ram_usage_perc,0)
    L_RO_PROP(int,ram_total,set_ram_total,0)
    //L_RO_PROP(int,,set_,0)
    // This basically only makes sense on the ground pi, it is not the battery percentage reported by the FC
    // but the battery percentage reported by the COmpanion computer running OpenHD (if it is supported, aka for future power hat o.ä)
    L_RO_PROP(int,battery_percent,set_battery_percent,0)
    L_RO_PROP(QString,battery_gauge,set_battery_gauge,"\uf091")
    // needs to be queried explicitly (not continous fire and forget)
    L_RO_PROP(QString,openhd_version,set_openhd_version,"N/A")
    L_RO_PROP(QString,last_ping_result_openhd,set_last_ping_result_openhd,"N/A")
    L_RO_PROP(bool,is_alive,set_is_alive,false)
    //
    L_RO_PROP(int,current_rx_rssi,set_current_rx_rssi,-128)
    //
    L_RO_PROP(int,wifi_rx_packets_count,wifi_rx_packets_count,-1)
    L_RO_PROP(int,wifi_tx_packets_count,wifi_tx_packets_count,-1)
private:
     const bool _is_air; // either true (for air) or false (for ground)
     uint8_t get_own_sys_id()const{
         return _is_air ? OHD_SYS_ID_AIR : OHD_SYS_ID_GROUND;
     }
     // These are for handling the slight differences regarding air/ ground properly, if there are any
     // For examle, the onboard computer status is the same when coming from either air or ground,
     // but the stats total are to be interpreted slightly different for air and ground.
     void process_onboard_computer_status(const mavlink_onboard_computer_status_t& msg);
     void process_x0(const mavlink_openhd_stats_monitor_mode_wifi_card_t& msg);
     void process_x1(const mavlink_openhd_stats_monitor_mode_wifi_link_t& msg);
     void process_x2(const mavlink_openhd_stats_telemetry_t& msg);
     void process_x3(const mavlink_openhd_stats_wb_video_air_t& msg);
     void process_x4(const mavlink_openhd_stats_wb_video_ground_t& msg);
private:
     std::atomic<int32_t> m_last_heartbeat_ms = -1;
     std::atomic<int32_t> m_last_message_ms= -1;
     //
     QString m_curr_incoming_bitrate="Bitrate NA";
     QString m_curr_incoming_tele_bitrate="Bitrate NA";
     //
private:
    // Sets the alive boolean if no heartbeat / message has been received in the last X seconds
    QTimer* m_alive_timer = nullptr;
    void update_alive();
    std::chrono::steady_clock::time_point m_last_message_openhd_stats_total_all_wifibroadcast_streams=std::chrono::steady_clock::now();
    // Model / fire and forget data only end
private:
     // NOTE: nullptr until discovered !!
     std::shared_ptr<mavsdk::System> _system=nullptr;
     std::shared_ptr<mavsdk::Action> _action=nullptr;
     bool send_command_long(mavsdk::Action::CommandLong command);
public:
     Q_INVOKABLE bool send_command_reboot(bool reboot);
     //
     bool send_command_restart_interface();
private:
     int64_t x_last_dropped_packets=-1;
     void send_message_hud_connection(bool connected);
public:
     // Ditry, until we have send command with retransmissions
     // request version if not set yet, but no more than x times
     bool should_request_version();
private:
     int m_n_times_version_has_been_requested=0;
private:
     // do not completely pollute the HUD with this error message
     std::chrono::steady_clock::time_point m_last_tx_error_hud_message=std::chrono::steady_clock::now();
};



#endif // AOHDSYSTEM_H
