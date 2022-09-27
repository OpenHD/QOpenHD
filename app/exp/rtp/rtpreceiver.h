#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../../common_consti/UDPReceiver.h"

#include <fstream>
#include <mutex>
#include <queue>

#include "../nalu/NALU.hpp"
#include "../nalu/KeyFrameFinder.hpp"

class RTPReceiver
{
public:
    RTPReceiver(int port,bool is_h265);
    ~RTPReceiver();

    std::shared_ptr<std::vector<uint8_t>> get_data();

    std::unique_ptr<std::vector<uint8_t>> get_config_data();
private:
    std::unique_ptr<UDPReceiver> m_udp_receiver=nullptr;
    std::unique_ptr<RTPDecoder> m_rtp_decoder=nullptr;

    void udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize);

    void nalu_data_callback(const std::chrono::steady_clock::time_point creation_time,const uint8_t* nalu_data,const int nalu_data_size);
    //
    std::unique_ptr<std::ofstream> m_out_file;
private:
    const bool is_h265;
private:
    std::mutex m_data_mutex;
    std::queue<std::shared_ptr<std::vector<uint8_t>>> m_data;

    void queue_data(std::shared_ptr<std::vector<uint8_t>> data);
private:
    std::unique_ptr<KeyFrameFinder> m_keyframe_finder;
};

#endif // RTPRECEIVER_H
