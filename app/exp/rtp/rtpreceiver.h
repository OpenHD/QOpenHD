#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../../common_consti/UDPReceiver.h"

#include <fstream>

class RTPReceiver
{
public:
    RTPReceiver(int port);
private:
    std::unique_ptr<UDPReceiver> m_udp_receiver=nullptr;
    std::unique_ptr<RTPDecoder> m_rtp_decoder=nullptr;

    void udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize);

    void nalu_data_callback(const uint8_t* nalu_data,const int nalu_data_size);

    //
    //std::ofstream m_out_file{"/tmp/x_raw_h264.h264"};
    std::ofstream m_out_file{"/tmp/x_raw_h265.h265"};
};

#endif // RTPRECEIVER_H
