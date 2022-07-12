#ifndef WIFIADAPTER_H
#define WIFIADAPTER_H

struct WifiAdapter{
    unsigned int received_packet_count;
    int current_signal_dbm;
    int signal_good;
};

#endif // WIFIADAPTER_H
