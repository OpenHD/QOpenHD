#ifndef WIFICARD_H
#define WIFICARD_H

#include <qobject.h>
#include "../../../lib/lqtutils_master/lqtutils_prop.h"


class WiFiCard : public QObject
{
    Q_OBJECT
    L_RO_PROP(bool,alive,set_alive,false)
    L_RO_PROP(int,n_received_packets,set_n_received_packets,0)
    L_RO_PROP(int,curr_rx_rssi_dbm,set_curr_rx_rssi_dbm,-128)
public:
    explicit WiFiCard(QObject *parent = nullptr);
    // Ground might have multiple rx-es
    static WiFiCard& instance_gnd(int index);
    // air always has only one rx
    static WiFiCard& instance_air();
    //
    static int helper_get_gnd_curr_best_rssi();
};

#endif // WIFICARD_H
