#ifndef MAVLINKCHANNEL_H
#define MAVLINKCHANNEL_H

#include <mutex>



class MavlinkChannel
{
public:
    MavlinkChannel();
    static MavlinkChannel& instance();
    int get_free_channel();
    void give_back_channel(int channel);
private:
    std::mutex m_chann_mutex;
    int m_channel_number=0;
};


#endif // MAVLINKCHANNEL_H
