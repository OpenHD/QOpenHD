#ifndef EMULATEDPACKETDROP_H
#define EMULATEDPACKETDROP_H

#include <cstdlib>
#include <qdebug.h>
#include <time.h>

// emulating packet drop "as" when using wifibroadcast (no matter weather it is with or without FEC) is not that easy.

// Drops a specific percentage of packets, this doesn't eumlate the "big gaps" behaviour
class PacketDropEmulator{
public:
    PacketDropEmulator(int percentage_dropped_packets):m_percentage_dropped_packets(percentage_dropped_packets){
        srand(time(NULL));
    }
    // Returns true if you should drop this packet, false otherwise
    bool drop_packet(){
        int r = rand();      // Returns a pseudo-random integer between 0 and RAND_MAX.
        r = r % m_percentage_dropped_packets;
        if(r==0){
            // drop packet
            n_dropped_packets++;
            log();
            return true;
        }
        n_forwarded_packets++;
        log();
        return false;
    }
    void log(){
        const double perc_dropped=(double)n_dropped_packets / (n_dropped_packets+n_forwarded_packets)*100.0;
        qDebug()<<"N dropped:"<<n_dropped_packets<<",forwarded:"<<n_forwarded_packets<<"Perc:"<<perc_dropped;
    }
private:
    const int m_percentage_dropped_packets;
    int n_dropped_packets=0;
    int n_forwarded_packets=0;
};

#endif // EMULATEDPACKETDROP_H
