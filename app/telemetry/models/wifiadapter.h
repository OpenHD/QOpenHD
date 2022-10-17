#ifndef WIFIADAPTER_H
#define WIFIADAPTER_H

#include <string>
#include <sstream>

struct WifiAdapter{
    unsigned int received_packet_count;
    int current_signal_dbm;
    int signal_good;

    std::string to_string(int index)const{
        std::stringstream ss;
        ss<<"WifiAdapter"<<index<<":{"<<current_signal_dbm<<" dbm,"<<received_packet_count<<"}";
        return ss.str();
    }
};


#endif // WIFIADAPTER_H
