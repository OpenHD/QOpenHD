#include "wificard.h"

#include <sstream>

#include "../../logging/hudlogmessagesmodel.h"
#include "tutil/qopenhdmavlinkhelper.hpp"
#include "openhd_core/wifi_card_type.h"


static std::string wifi_card_type_to_string(const int card_type) {
    switch (card_type) {
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2AU):
        return "88X2AU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2BU):
        return "88X2BU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2CU):
        return "88X2CU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2EU):
        return "88X2EU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::RTL_88X2AU):
        return "RTL_88X2AU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::RTL_88X2BU):
        return "RTL_88X2BU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::ATHEROS):
        return "ATHEROS";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::MT_7921u):
        return "MT_7921u";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::RALINK):
        return "RALINK";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::INTEL):
        return "INTEL";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::BROADCOM):
        return "BROADCOM";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_8852BU):
        return "OPENHD_8852BU";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_EMULATED):
        return "OPENHD_EMULATED";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::AIC):
        return "AIC";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::QUALCOMM):
        return "QUALCOMM";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::UNKNOWN):
        return "UNKNOWN";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::ARTOSYN):
        return "ARTOSYN";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8812A): return "Devourer RTL8812A";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8821A): return "Devourer RTL8821A (1T1R)";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8814A): return "Devourer RTL8814A";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8821C): return "Devourer RTL8821C (1T1R)";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822B): return "Devourer RTL8822B";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822C): return "Devourer RTL8822C";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822E): return "Devourer RTL8822E";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8733B): return "Devourer RTL8733B (1T1R)";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8852B): return "Devourer RTL8852B";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8852C): return "Devourer RTL8852C";
    case openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8811A): return "Devourer RTL8811A (1T1R)";
    default:
        return "UNKNOWN";
    }
}
static bool is_devourer_card_type(const int card_type) {
    return card_type >= openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8812A) &&
           card_type <= openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8811A);
}

static QString devourer_verdict_to_string(const int verdict) {
    switch (verdict) {
    case 1: return "SATURATED";
    case 2: return "INTERFERENCE";
    case 3: return "WEAK";
    case 4: return "MARGINAL";
    case 5: return "HEALTHY";
    default: return "NO SIGNAL";
    }
}

static QString thermal_status_from_delta(const bool valid, const int delta) {
    if (!valid) return "UNKNOWN";
    if (delta < 8) return "COOL";
    if (delta < 15) return "WARM";
    if (delta < 25) return "HOT";
    return "CRITICAL";
}
static QString tx_power_unit_for_card(const int card_type){
    std::stringstream ss;
    if(card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2AU) ||
       is_devourer_card_type(card_type)){
        // OpenHD RTL8812AU
        return "TPI";
    }else if(card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2BU) ||
             card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2EU)){
        return "mW";
    }
    return " ?mW";
}


WiFiCard::WiFiCard(bool is_air,int card_idx,QObject *parent)
    : QObject{parent},m_is_air_card(is_air),m_card_idx(card_idx)
{
    if(!m_is_air_card){
        m_alive_timer = std::make_unique<QTimer>(this);
        QObject::connect(m_alive_timer.get(), &QTimer::timeout, this, &WiFiCard::update_alive);
        m_alive_timer->start(1000);
    }
}


WiFiCard &WiFiCard::instance_gnd(int index)
{
    if(index==0){
        static WiFiCard gnd0{false,0};
        return gnd0;
    }else if(index==1){
        static WiFiCard gnd1{false,1};
        return gnd1;
    }else if(index==2){
        static WiFiCard gnd2{false,2};
        return gnd2;
    }else if(index==3){
        static WiFiCard gnd3{false,3};
        return gnd3;
    }
    assert(false);
}

WiFiCard &WiFiCard::instance_air()
{
    static WiFiCard air{true,0};
    return air;
}

void WiFiCard::process_mavlink(const mavlink_openhd_stats_monitor_mode_wifi_card_t &msg)
{
    m_last_mavlink_message=QOpenHDMavlinkHelper::getTimeMilliseconds();
    set_alive(true);
    set_curr_rx_rssi_dbm(msg.rx_rssi);
    set_curr_rx_rssi_dbm_antenna1(msg.rx_rssi_1);
    set_curr_rx_rssi_dbm_antenna2(msg.rx_rssi_2);
    set_rx_snr_antenna1(msg.rx_snr_antenna1);
    set_rx_snr_antenna2(msg.rx_snr_antenna2);
    set_rx_noise_dbm(msg.rx_noise_adapter);
    set_rx_noise_dbm_antenna1(msg.rx_noise_antenna1);
    set_rx_noise_dbm_antenna2(msg.rx_noise_antenna2);
    const bool devourer_card = is_devourer_card_type(msg.card_type);
    if(devourer_card){
        const quint32 metadata = static_cast<quint32>(msg.dummy2);
        const bool qualityValid = (metadata & (1u << 19)) != 0;
        const bool pathsValid = (metadata & (1u << 20)) != 0;
        const bool thermalValid = (metadata & (1u << 21)) != 0;
        const bool evmValid = (metadata & (1u << 23)) != 0;
        const quint16 thermalPacked = static_cast<quint16>(msg.dummy1);
        const int thermalDelta = static_cast<qint8>((thermalPacked >> 8) & 0xff);
        set_card_temperature(-128); // Devourer raw units are not degrees C.
        set_thermal_valid(thermalValid);
        set_thermal_raw(msg.card_temperature >= 0 ? msg.card_temperature : -1);
        set_thermal_baseline(thermalPacked & 0xff);
        set_thermal_delta(thermalDelta);
        set_card_temperature_status(thermal_status_from_delta(thermalValid, thermalDelta));
        set_devourer_quality_valid(qualityValid);
        set_devourer_link_health(qualityValid
            ? devourer_verdict_to_string((metadata >> 16) & 0x7) : "N/A");
        set_rx_paths_valid(pathsValid);
        set_rx_active_path_mask((metadata >> 8) & 0xf);
        set_rx_active_path_count((metadata >> 12) & 0x7);
        set_rx_evm_db(evmValid ? msg.dummy0 : -128);
    }else{
        set_card_temperature(msg.card_temperature);
        set_thermal_valid(false);
        set_thermal_raw(-1);
        set_thermal_baseline(-1);
        set_thermal_delta(0);
        set_card_temperature_status("N/A");
        set_devourer_quality_valid(false);
        set_devourer_link_health("N/A");
        set_rx_paths_valid(false);
        set_rx_active_path_mask(0);
        set_rx_active_path_count(0);
        set_rx_evm_db(-128);
    }

    set_n_received_packets(msg.count_p_received);
    set_packet_loss_perc(msg.curr_rx_packet_loss_perc);
    if(m_tx_power >0 && m_tx_power!=msg.tx_power_current){
        // TX power changed
        if(m_is_air_card){
            std::stringstream ss;
            ss<<"Air TX Power "<<(int)msg.tx_power_current;
            HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
        }else{
            // All gnd cards use the same tx power
            if(m_card_idx==0){
                std::stringstream ss;
                ss<<"GND TX Power "<<(int)msg.tx_power_current;
                HUDLogMessagesModel::instance().add_message_info(ss.str().c_str());
            }
        }
    }
    set_tx_power(msg.tx_power_current);
    set_tx_power_armed(msg.tx_power_armed);
    set_tx_power_disarmed(msg.tx_power_disarmed);
    set_tx_power_unit(tx_power_unit_for_card(msg.card_type));
    const bool disconnected=msg.curr_status==1;
    if(disconnected){
        const auto elapsed=std::chrono::steady_clock::now()-m_last_disconnected_warning;
        if(elapsed>=CARD_DISCONNECTED_WARNING_INTERVAL){
            m_last_disconnected_warning=std::chrono::steady_clock::now();
            std::stringstream message;
            message<<(m_is_air_card ? "Air ":"Gnd ");
            message<<"Card "<<(int)msg.card_index<<" disconnected";
            HUDLogMessagesModel::instance().add_message_warning(message.str().c_str());
        }
    }
    // Packets received in the last 1 second on this card
    const auto diff=std::chrono::steady_clock::now()-m_last_packets_in_X_second_recalculation;
    if(m_last_packets_in_X_second_value<=-1){
        m_last_packets_in_X_second_value=msg.count_p_received;
    }else{
        if(diff>=std::chrono::seconds(1)){
            const int64_t delta=msg.count_p_received-m_last_packets_in_X_second_value;
            set_n_received_packets_rolling(delta);
            m_last_packets_in_X_second_value=msg.count_p_received;
            m_last_packets_in_X_second_recalculation=std::chrono::steady_clock::now();
        }
    }
    set_card_type(msg.card_type);
    set_card_type_as_string(wifi_card_type_to_string(msg.card_type).c_str());
    const int card_type=msg.card_type;
    bool supported = false;
    if(card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2AU) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2BU) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2CU) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2EU) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_EMULATED) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::ARTOSYN)){
        supported=true;
    }
    if(card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8812A) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8814A) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822B) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822C) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8822E) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8852B) ||
       card_type==openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8852C)){
        supported=true;
    }
    set_card_type_supported(supported);
    set_card_sub_type(static_cast<quint32>(msg.dummy2) & 0xff);
}

int WiFiCard::helper_get_gnd_curr_best_rssi()
{
    int best_rssi=-127;
    for(int i=0;i<4;i++){
        auto& card=instance_gnd(i);
        const auto card_rssi=card.m_curr_rx_rssi_dbm;
        if(card.alive() && card_rssi>best_rssi){
            best_rssi=card_rssi;
        }
    }
    return best_rssi;
}

void WiFiCard::update_alive()
{
    const auto elapsed_since_last_message=QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_mavlink_message;
    if(elapsed_since_last_message>5*1000){
        set_alive(false);
    }
}

