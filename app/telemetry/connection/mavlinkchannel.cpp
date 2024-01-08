#include "mavlinkchannel.h"

MavlinkChannel::MavlinkChannel()
{

}

MavlinkChannel &MavlinkChannel::instance()
{
    static MavlinkChannel instance;
    return instance;
}

int MavlinkChannel::get_free_channel()
{
    std::lock_guard<std::mutex> lock(m_chann_mutex);
    auto ret=m_channel_number;
    m_channel_number++;
    return ret;
}

void MavlinkChannel::give_back_channel(int channel)
{

}
