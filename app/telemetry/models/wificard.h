#ifndef WIFICARD_H
#define WIFICARD_H

#include <memory>
#include <qobject.h>
#include <qtimer.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"

#include "../util/mavlink_include.h"

// Stats unique per each connected (wifibroadcast) wfi card
// Air has only one card, ground can have one or more card(s)
class WiFiCard : public QObject
{
    Q_OBJECT
    L_RO_PROP(bool,alive,set_alive,false)
    L_RO_PROP(int,n_received_packets,set_n_received_packets,0)
    L_RO_PROP(int,curr_rx_rssi_dbm,set_curr_rx_rssi_dbm,-128)
    L_RO_PROP(int,packet_loss_perc,set_packet_loss_perc,-1)
    L_RO_PROP(bool,is_active_tx,set_is_active_tx,false)
    L_RO_PROP(int,tx_power,set_tx_power,-1)
    L_RO_PROP(QString,tx_power_unit,set_tx_power_unit,"N/A");
    L_RO_PROP(QString,tx_power_current_str,set_tx_power_current_str,"N/A");
    L_RO_PROP(int,tx_power_armed,set_tx_power_armed,-1)
    // Shows disabled if no special armed tx power is set
    L_RO_PROP(QString,tx_power_armed_str,set_tx_power_armed_str,"DISABLED")
    L_RO_PROP(int,tx_power_disarmed,set_tx_power_disarmed,-1)
    L_RO_PROP(int,n_received_packets_rolling,set_n_received_packets_rolling,0)
    // A card might have more than one antenna
    L_RO_PROP(int,curr_rx_rssi_dbm_antenna1,set_curr_rx_rssi_dbm_antenna1,-128)
    L_RO_PROP(int,curr_rx_rssi_dbm_antenna2,set_curr_rx_rssi_dbm_antenna2,-128)
    //
    L_RO_PROP(int,card_type,set_card_type,-1) // -1 = no info available yet, otherwise, openhd card type (0..?)
    L_RO_PROP(QString,card_type_as_string,set_card_type_as_string,"N/A")
    L_RO_PROP(int,card_type_supported,set_card_type_supported,false)
public:
    explicit WiFiCard(bool is_air,int card_idx,QObject *parent = nullptr);
    static constexpr int N_CARDS=4;
    // Ground might have multiple rx-es
    static WiFiCard& instance_gnd(int index);
    // air always has only one rx
    static WiFiCard& instance_air();
    //
    void process_mavlink(const mavlink_openhd_stats_monitor_mode_wifi_card_t &msg);

    static int helper_get_gnd_curr_best_rssi();
private:
    std::chrono::steady_clock::time_point m_last_disconnected_warning=std::chrono::steady_clock::now();
    static constexpr auto CARD_DISCONNECTED_WARNING_INTERVAL=std::chrono::seconds(3);
    const bool m_is_air_card;
    const int m_card_idx;
    // On the OSD, we show how many packets were received on each card in X seconds intervals
    std::chrono::steady_clock::time_point m_last_packets_in_X_second_recalculation=std::chrono::steady_clock::now();
    int64_t m_last_packets_in_X_second_value=-1;
    // Card alive - ONLY USED FOR GROUND CARD(s)
    std::unique_ptr<QTimer> m_alive_timer = nullptr;
    std::atomic<int> m_last_mavlink_message=0;
    void update_alive();
};

#endif // WIFICARD_H
