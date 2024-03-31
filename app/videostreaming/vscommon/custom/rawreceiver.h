#ifndef RAWRECEIVER_H
#define RAWRECEIVER_H

#include <mutex>

#include <udp/UDPReceiver.h>

#include "nalu/NALU.hpp"
#include "nalu/CodecConfigFinder.hpp"
#include "common/TimeHelper.hpp"
#include "common/ThreadsafeQueue.hpp"

class RawReceiver
{
public:
    static constexpr const auto NALU_MAXLEN=1024*1024;
    RawReceiver(int port,std::string ip,bool is_h265,bool unused);
    ~RawReceiver();
    // Returns the oldest frame if available.
    // (nullptr on failure)
    // The timeout is optional
    std::shared_ptr<NALUBuffer> get_next_frame(std::optional<std::chrono::microseconds> timeout=std::nullopt);
    // return nullptr if not enough config data is available yet, otherwise, return valid config data
    std::shared_ptr<std::vector<uint8_t>> get_config_data();
    bool config_has_changed_during_decode=false;
    // get width height using the config data (SPS)
    // do not call that if there is no config data
    std::array<int,2> sps_get_width_height();
private:
    void udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize);
    void raw_nalu_callback(const uint8_t *data,int len);
    void queue_data(const uint8_t* nalu_data,const std::size_t nalu_data_len);
private:
    const bool is_h265;
    std::mutex m_data_mutex;
    std::unique_ptr<UDPReceiver> m_udp_receiver=nullptr;
    std::unique_ptr<CodecConfigFinder> m_keyframe_finder;
    std::array<uint8_t,NALU_MAXLEN> m_curr_nalu;
    int m_nalu_data_length=0;
    int nalu_search_state=0;
    // Calculate fps, but note that this might not give the exact/correct value in some case(s)
    FPSCalculator m_estimate_fps_calculator{};
    // space for up to X NALUs to account for "weird" cases, fifo anyways
    // In case the decoder cannot keep up with the data we provide to it, the only fix would be to reduce the fps/resolution anyways.
    qopenhd::ThreadsafeQueue<std::shared_ptr<NALUBuffer>> m_data_queue{20};
private:
    int n_frames_non_idr=0;
    int n_frames_idr=0;
    int n_dropped_frames=0;
    bool valid=false;
};

#endif // RAWRECEIVER_H
