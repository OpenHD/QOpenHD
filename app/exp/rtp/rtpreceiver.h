#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../../common_consti/UDPReceiver.h"

#include <fstream>

class RTPReceiver
{
public:
    RTPReceiver(int port,bool is_h265);
private:
    std::unique_ptr<UDPReceiver> m_udp_receiver=nullptr;
    std::unique_ptr<RTPDecoder> m_rtp_decoder=nullptr;

    void udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize);

    void nalu_data_callback(const uint8_t* nalu_data,const int nalu_data_size);

    //
    std::unique_ptr<std::ofstream> m_out_file;
private:
    const bool is_h265;
};

#endif // RTPRECEIVER_H
