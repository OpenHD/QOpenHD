#include "aohdsystem.h"

#include "../../common/StringHelper.hpp"
#include "../../common/TimeHelper.hpp"
#include "QOpenHDVideoHelper.hpp"
#include "util/telemetryutil.hpp"
#include "wificard.h"
#include "rcchannelsmodel.h"
#include "camerastreammodel.h"

#include <string>
#include <sstream>
#include <MavlinkTelemetry.h>

#include <logging/logmessagesmodel.h>
#include <logging/hudlogmessagesmodel.h>

#include "util/qopenhd.h"
#include "../util/qopenhdmavlinkhelper.hpp"

#include <../util/WorkaroundMessageBox.h>
#include "../settings/wblinksettingshelper.h"

// From https://netbeez.net/blog/what-is-mcs-index/
static std::vector<int> get_dbm_20mhz(){
    return {-82,-79,-77,-74,-70,-66,-65,-64,-59,-57};
}
static std::vector<int> get_dbm_40mhz(){
    return {-79,-76,-74,-71,-67,-63,-62,-61,-56,-54};
}

static int get_required_dbm_for_rate(int channel_width,int mcs_index){
    const auto values=channel_width==20 ? get_dbm_20mhz() : get_dbm_40mhz();
    if(mcs_index>=0 && mcs_index<=values.size()){
        return values[mcs_index];
    }
    return 0;
}

AOHDSystem::AOHDSystem(const bool is_air,QObject *parent)
    : QObject{parent},m_is_air(is_air)
{
    m_alive_timer = std::make_unique<QTimer>(this);
    QObject::connect(m_alive_timer.get(), &QTimer::timeout, this, &AOHDSystem::update_alive);
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

bool AOHDSystem::process_message(const mavlink_message_t &msg)
{
    if(msg.sysid != get_own_sys_id()){
        qDebug()<<"AOHDSystem::process_message: wron sys id";
        return false;
    }
    m_last_message_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
    bool consumed=false;
    switch(msg.msgid){
        case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE:{
            mavlink_openhd_version_message_t parsedMsg;
            mavlink_msg_openhd_version_message_decode(&msg,&parsedMsg);
            QString version(parsedMsg.version);
            set_openhd_version(version);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS:{
            mavlink_onboard_computer_status_t parsedMsg;
            mavlink_msg_onboard_computer_status_decode(&msg,&parsedMsg);
            process_onboard_computer_status(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_CARD:{
            mavlink_openhd_stats_monitor_mode_wifi_card_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_card_decode(&msg,&parsedMsg);
            //qDebug()<<"Got MAVLINK_MSG_ID_OPENHD_WIFI_CARD"<<(int)parsedMsg.card_index<<" "<<(int)parsedMsg.rx_rssi;
            process_x0(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_LINK:{
            mavlink_openhd_stats_monitor_mode_wifi_link_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_link_decode(&msg,&parsedMsg);
            process_x1(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_TELEMETRY:{
            mavlink_openhd_stats_telemetry_t parsedMsg;
            mavlink_msg_openhd_stats_telemetry_decode(&msg,&parsedMsg);
            process_x2(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_AIR:{
            mavlink_openhd_stats_wb_video_air_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_air_decode(&msg,&parsedMsg);
            process_x3(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_AIR_FEC_PERFORMANCE:{
            mavlink_openhd_stats_wb_video_air_fec_performance_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_air_fec_performance_decode(&msg,&parsedMsg);
            process_x3b(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_CAMERA_STATUS:{
            mavlink_openhd_camera_status_t parsedMsg;
            mavlink_msg_openhd_camera_status_decode(&msg,&parsedMsg);
            if(msg.compid==OHD_COMP_ID_AIR_CAMERA_PRIMARY){
                CameraStreamModel::instance(0).update_mavlink_openhd_camera_stats(parsedMsg);
            }else if(msg.compid==OHD_COMP_ID_AIR_CAMERA_SECONDARY){
                CameraStreamModel::instance(1).update_mavlink_openhd_camera_stats(parsedMsg);
                // Feature - tell user to enable 2 cameras in qopenhd
                set_n_openhd_cameras(2);
                const int value_in_qopenhd=QOpenHDVideoHelper::get_qopenhd_n_cameras();
                if(value_in_qopenhd!=2){
                    const auto elapsed=std::chrono::steady_clock::now()-m_last_n_cameras_message;
                    if(elapsed>std::chrono::seconds(10)){
                        auto message="QOpenHD is not configured for dual cam usage, go to QOpenHD settings / General to configure your GCS to show secondary camera screen";
                        qDebug()<<message;
                        WorkaroundMessageBox::makePopupMessage(message,8);
                        m_last_n_cameras_message=std::chrono::steady_clock::now();
                    }
                    HUDLogMessagesModel::instance().add_message_info("QOpenHD only shows 1 camera");
                }

            }
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_GROUND:{
            mavlink_openhd_stats_wb_video_ground_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_ground_decode(&msg,&parsedMsg);
            process_x4(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_GROUND_FEC_PERFORMANCE:{
            mavlink_openhd_stats_wb_video_ground_fec_performance_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_ground_fec_performance_decode(&msg,&parsedMsg);
            process_x4b(parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_ONBOARD_COMPUTER_STATUS_EXTENSION:{
            mavlink_openhd_onboard_computer_status_extension_t parsedMsg;
            mavlink_msg_openhd_onboard_computer_status_extension_decode(&msg,&parsedMsg);
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_HEARTBEAT:{
            mavlink_heartbeat_t parsedMsg;
            mavlink_msg_heartbeat_decode(&msg,&parsedMsg);
            m_last_heartbeat_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
            if(parsedMsg.autopilot!=MAV_AUTOPILOT_INVALID){
                qDebug()<<"Warning OpenHD systems should always set autopilot to none";
            }
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_RC_CHANNELS_OVERRIDE:{
             mavlink_rc_channels_override_t parsedMsg;
             mavlink_msg_rc_channels_override_decode(&msg,&parsedMsg);
             RCChannelsModel::instanceGround().update_all_channels(Telemetryutil::mavlink_msg_rc_channels_override_to_array(parsedMsg));
            consumed=true;
        };break;
        case MAVLINK_MSG_ID_STATUSTEXT:{
             mavlink_statustext_t parsedMsg;
             mavlink_msg_statustext_decode(&msg,&parsedMsg);
             auto tmp=Telemetryutil::statustext_convert(parsedMsg);
             LogMessagesModel::instanceOHD().addLogMessage(m_is_air ? "OHD[A]":"OHD[G]",tmp.message.c_str(),tmp.level);
             // Notify user in HUD of external device connect / disconnect events
             if(tmp.message.find("External device") != std::string::npos){
                HUDLogMessagesModel::instance().add_message(tmp.level,tmp.message.c_str());
             }
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_WIFBROADCAST_SUPPORTED_CHANNELS:{
            mavlink_openhd_wifbroadcast_supported_channels_t parsedMsg;
            mavlink_msg_openhd_wifbroadcast_supported_channels_decode(&msg,&parsedMsg);
            if(!m_is_air){
                WBLinkSettingsHelper::instance().process_message_openhd_wifibroadcast_supported_channels(parsedMsg);
            }
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_WIFBROADCAST_ANALYZE_CHANNELS_PROGRESS:{
            mavlink_openhd_wifbroadcast_analyze_channels_progress_t parsedMsg;
            mavlink_msg_openhd_wifbroadcast_analyze_channels_progress_decode(&msg,&parsedMsg);
            if(!m_is_air){
                WBLinkSettingsHelper::instance().process_message_openhd_wifibroadcast_analyze_channels_progress(parsedMsg);
            }
            consumed=true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_WIFBROADCAST_SCAN_CHANNELS_PROGRESS:{
            mavlink_openhd_wifbroadcast_scan_channels_progress_t parsedMsg;
            mavlink_msg_openhd_wifbroadcast_scan_channels_progress_decode(&msg,&parsedMsg);
            if(!m_is_air){
                WBLinkSettingsHelper::instance().process_message_openhd_wifibroadcast_scan_channels_progress(parsedMsg);
            }
            consumed=true;
        }break;
        default:{

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
    return consumed;
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
    set_curr_v3d_freq_mhz(msg.storage_usage[0]);
    set_curr_space_left_mb(msg.storage_usage[1]);
    set_rpi_undervolt_error(msg.link_tx_rate[0]==1);
    set_ina219_voltage_millivolt(msg.storage_usage[2]);
    set_ina219_current_milliamps(msg.storage_usage[3]);
    set_ram_usage_perc(msg.ram_usage);
    set_ram_total(msg.ram_total);
}

void AOHDSystem::process_x0(const mavlink_openhd_stats_monitor_mode_wifi_card_t &msg){
    if(m_is_air && msg.card_index>1){
        qDebug()<<"Air only has 1 wifibroadcats card";
        return;
    }
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_card_t";
    if(m_is_air){
        if(msg.card_index!=0){
            qDebug()<<"Air only has 1 wifibroadcats card";
            return;
        }
        auto& card=WiFiCard::instance_air();
        card.process_mavlink(msg);
        set_current_rx_rssi(card.curr_rx_rssi_dbm());
    }else{
        if(msg.card_index<0 || msg.card_index>=4){
            qDebug()<<"Gnd invalid card index"<<msg.card_index;
            return;
        }
        auto& card=WiFiCard::instance_gnd(msg.card_index);
        card.process_mavlink(msg);
        set_current_rx_rssi(WiFiCard::helper_get_gnd_curr_best_rssi());
    }
    // TODO: r.n we don't differentiate signal quality per card
    if(msg.card_index==0){
        set_current_rx_signal_quality(msg.rx_signal_quality);
    }
}

void AOHDSystem::process_x1(const mavlink_openhd_stats_monitor_mode_wifi_link_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_link_t";
    set_curr_rx_packet_loss_perc(msg.curr_rx_packet_loss_perc);
    set_count_tx_inj_error_hint(msg.count_tx_inj_error_hint);
    set_count_tx_dropped_packets(msg.count_tx_dropped_packets);
    // only on ground
    if(! m_is_air){
        for(int i=0;i<WiFiCard::N_CARDS;i++){
            WiFiCard::instance_gnd(i).set_is_active_tx(false);
        }
        const auto active_tx_idx=msg.curr_tx_card_idx;
        if(active_tx_idx>=0 && active_tx_idx<WiFiCard::N_CARDS){
            WiFiCard::instance_gnd(active_tx_idx).set_is_active_tx(true);
        }
        set_tx_operating_mode(msg.tx_passive_mode_is_enabled);
    }
    const int new_mcs_index=msg.curr_tx_mcs_index;
    if(m_is_air){
        // We are only interested in the mcs index of the air unit
        if(m_curr_mcs_index!=-1 && new_mcs_index!=m_curr_mcs_index){
            std::stringstream ss;
            ss<<"MCS index changed to "<<new_mcs_index;
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }
    }
    set_curr_mcs_index(new_mcs_index);
    set_curr_channel_mhz(msg.curr_tx_channel_mhz);
    set_curr_channel_width_mhz(msg.curr_tx_channel_w_mhz);
    if(!m_is_air){
        WBLinkSettingsHelper::instance().validate_and_set_channel_mhz(msg.curr_tx_channel_mhz);
        WBLinkSettingsHelper::instance().validate_and_set_channel_width_mhz(msg.curr_tx_channel_w_mhz);
    }
    set_curr_bitrate_kbits(msg.curr_rate_kbits);
    set_curr_n_rate_adjustments(msg.curr_n_rate_adjustments);
    set_tx_packets_per_second_and_bits_per_second(StringHelper::bitrate_and_pps_to_string(msg.curr_tx_bps,msg.curr_tx_pps).c_str());
    set_rx_packets_per_second_and_bits_per_second(StringHelper::bitrate_and_pps_to_string(msg.curr_rx_bps,msg.curr_rx_pps).c_str());
    const auto stbc_lpdc_gi=Telemetryutil::get_stbc_lpdc_shortguard_bitfield(msg.curr_tx_stbc_lpdc_shortguard_bitfield);
    set_wb_stbc_enabled(stbc_lpdc_gi.stbc);
    set_wb_lpdc_enabled(stbc_lpdc_gi.lpdc);
    set_wb_short_guard_enabled(stbc_lpdc_gi.short_guard);
    if(m_is_air && !stbc_lpdc_gi.stbc){
        if(m_stbc_warning_shown)return;
        //  If your ground unit uses card(s) with 2 antennas, enable STBC on your air unit (transmitting part)."
        // "If your air unit uses card(s) with 2 antennas, enable STBC on your ground unit (transmitting part).
        /*auto message="Please check: Enable WB_E_STBC on AIR unit IF your rtl8812au TX/RX both have more than one antenna"
                       " (NOTE: Without 2 populated rf paths, enabling this option results in"
                       " no connection !!! OpenHD cannot automatically check how many rf paths are populated on your adapter(s). ASUS has 1 external and "
                       "1 internal antenna (STBC should be used). If you wish to not see this "
                       "prompt again, you can disable it in QOpenHD - DEV - dev_wb_show_no_stbc_enabled_warning.";*/
        auto message="Please check: STBC is not enabled on your air unit. "
                       "If your air unit has 2 or more antennas (ONLY IF!), enable STBC to use them both and increase range significantly."
                       "See the wiki for more info."
                       "You can disable this prompt by going to QOpenHD - DEV and set dev_wb_show_no_stbc_enabled_warning=off.";
        QSettings settings;
        const auto dev_wb_show_no_stbc_enabled_warning =settings.value("dev_wb_show_no_stbc_enabled_warning", false).toBool();
        if(!dev_wb_show_no_stbc_enabled_warning){
            WorkaroundMessageBox::makePopupMessage(message,10);
            m_stbc_warning_shown=true;
        }
    }
    // Feature: Warning if dBm falls below minimum threshold for current MCS index on packets that need to be received
    // We need to get the mcs index from the other system (aka from air if we are running on ground) since that's whats being injected
    const int mcs_index_other=m_is_air ? AOHDSystem::instanceGround().m_curr_mcs_index : AOHDSystem::instanceAir().m_curr_mcs_index;
    const int minimum_dbm=get_required_dbm_for_rate(m_curr_channel_width_mhz,mcs_index_other);
    const int curr_rx_dbm=m_current_rx_rssi;
    const auto dbm_remaining=curr_rx_dbm - minimum_dbm;
    //qDebug()<<"On "<<(m_is_air ? "AIR" : "GND" )<<" RX mcs:"<<mcs_index_other<<" RX rssi:"<<curr_rx_dbm<<" minumum dbm:"<<minimum_dbm<<" remaining dbm:"<<dbm_remaining;
    if(minimum_dbm !=0 && curr_rx_dbm>-127){
        if(dbm_remaining<=0){
            // warning
            set_dbm_too_low_warning(2);
        }else if(dbm_remaining<=2){
            // caution
            set_dbm_too_low_warning(1);
        }else{
            set_dbm_too_low_warning(0);
        }
    }else{
        set_dbm_too_low_warning(0);
    }
    set_wb_link_pollution(msg.dummy0);
}

void AOHDSystem::process_x2(const mavlink_openhd_stats_telemetry_t &msg)
{
    //qDebug()<<"Got mavlink_openhd_stats_telemetry_t";
    set_curr_telemetry_rx_pps(Telemetryutil::pps_to_string(msg.curr_rx_pps));
    set_curr_telemetry_tx_pps(Telemetryutil::pps_to_string(msg.curr_tx_pps));
    set_curr_telemetry_rx_bps(Telemetryutil::bitrate_bps_to_qstring(msg.curr_rx_bps));
    set_curr_telemetry_tx_bps(Telemetryutil::bitrate_bps_to_qstring(msg.curr_tx_bps));
    set_tx_tele_packets_per_second_and_bits_per_second(StringHelper::bitrate_and_pps_to_string(msg.curr_tx_bps,msg.curr_tx_pps).c_str());
    set_rx_tele_packets_per_second_and_bits_per_second(StringHelper::bitrate_and_pps_to_string(msg.curr_rx_bps,msg.curr_rx_pps).c_str());
}

void AOHDSystem::process_x3(const mavlink_openhd_stats_wb_video_air_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_air_t";
    if(!m_is_air){
        qDebug()<<"warning got mavlink_openhd_stats_wb_video_air from ground";
        return;
    }
    // We use parts of this message ourself, but mostly, we just forward it to the right CameraStreamModel
    // (it is
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_air(msg);
    }
    // dirty
    if(msg.link_index!=0)return;
    if(x_last_dropped_packets<0){
        x_last_dropped_packets=msg.curr_dropped_frames;
    }else{
        const auto delta=msg.curr_dropped_frames-x_last_dropped_packets;
        x_last_dropped_packets=msg.curr_dropped_frames;
        if(delta>0){
            const auto elapsed_since_last=std::chrono::steady_clock::now()-m_last_tx_error_hud_message;
            if(elapsed_since_last>std::chrono::seconds(3)){
                HUDLogMessagesModel::instance().add_message_warning("TX error (dropped packets)");
                m_last_tx_error_hud_message=std::chrono::steady_clock::now();
            }
            set_tx_is_currently_dropping_packets(true);
        }else{
            set_tx_is_currently_dropping_packets(false);
        }
    }
}

void AOHDSystem::process_x3b(const mavlink_openhd_stats_wb_video_air_fec_performance_t &msg)
{
    if(!m_is_air){
        qDebug()<<"warning got mavlink_openhd_stats_wb_video_air_fec_performance_t from ground";
        return;
    }
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_air_fec_performance(msg);
    }
}

void AOHDSystem::process_x4(const mavlink_openhd_stats_wb_video_ground_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_ground_t";
    if(m_is_air){
         qDebug()<<"warning got mavlink_openhd_stats_wb_video_ground from air";
         return;
    }
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_ground(msg);
    }
}

void AOHDSystem::process_x4b(const mavlink_openhd_stats_wb_video_ground_fec_performance_t &msg)
{
    if(m_is_air){
        qDebug()<<"warning got mavlink_openhd_stats_wb_video_ground_fec_performance_ from air";
        return;
    }
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_ground_fec_performance(msg);
    }
}

void AOHDSystem::update_alive()
{
    // On the air unit, we consider it alive if "any" message has come in, not only the mavlink heartbeat
    const int32_t last_heartbeat_or_message = m_is_air ? m_last_message_ms : m_last_heartbeat_ms;
    if(last_heartbeat_or_message==-1){
        set_is_alive(false);
    }else{
        const auto elapsed_since_last_heartbeat=QOpenHDMavlinkHelper::getTimeMilliseconds()-last_heartbeat_or_message;
        // after X seconds, consider as "not alive"
        const bool alive=elapsed_since_last_heartbeat< 3*1000;
        if(alive != m_is_alive){
            // message when state changes
            send_message_hud_connection(alive);
            //
            set_is_alive(alive);
        }
    }
}

void AOHDSystem::send_message_hud_connection(bool connected){
    std::stringstream message;
    if(m_is_air){
        message << "Air unit ";
    }else{
        message << "Ground unit ";
    }
    if(connected){
        message << "connected";
        HUDLogMessagesModel::instance().add_message_info(message.str().c_str());
        //QOpenHD::instance().textToSpeech_sayMessage(message.str().c_str());
    }else{
        message << "disconnected";
        HUDLogMessagesModel::instance().add_message_warning(message.str().c_str());
    }
}

bool AOHDSystem::should_request_version()
{
    if(m_openhd_version=="N/A" &&  m_n_times_version_has_been_requested<10){
         m_n_times_version_has_been_requested++;
        return true;
    }
    return false;
}

