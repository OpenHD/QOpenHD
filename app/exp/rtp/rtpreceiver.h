#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../../common_consti/UDPReceiver.h"

class RTPReceiver
{
public:
    RTPReceiver();
private:
    std::unique_ptr<UDPReceiver> m_udp_receiver=nullptr;
    std::unique_ptr<RTPDecoder> m_rtp_decoder=nullptr;

    void udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize);

    void nalu_data_callback(const uint8_t* nalu_data,const int nalu_data_size);
};

#endif // RTPRECEIVER_H