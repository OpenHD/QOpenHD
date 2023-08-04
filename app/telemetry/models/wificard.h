#ifndef WIFICARD_H
#define WIFICARD_H

#include <qobject.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"

#include "../mavsdk_include.h"

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


};

#endif // WIFICARD_H
