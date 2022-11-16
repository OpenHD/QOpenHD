#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../udp/UDPReceiver.h"

#include <fstream>
#include <mutex>
#include <queue>

#include "../nalu/NALU.hpp"
#include "../nalu/KeyFrameFinder.hpp"

#include "../../common_consti/TimeHelper.hpp"
#include "../../common_consti/EmulatedPacketDrop.hpp"

//#define OPENHD_USE_LIB_UVGRTP

#ifdef OPENHD_USE_LIB_UVGRTP
#include <uvgrtp/lib.hh>
#endif

class RTPReceiver
{
public:
    RTPReceiver(int port,bool is_h265,bool feed_incomplete_frames);
    ~RTPReceiver();

    std::shared_ptr<NALU> get_data();

    std::shared_ptr<std::vector<uint8_t>> get_config_data();
    bool config_has_changed_during_decode=false;
    // get width height using the config data (SPS)
    // do not call that if there is no config data
    std::array<int,2> sps_get_width_height();
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
    std::queue<std::shared_ptr<NALU>> m_data;
    static constexpr auto MAX_DATA_QUEUE_SIZE=20;

    void queue_data(const uint8_t* nalu_data,const std::size_t nalu_data_len);
private:
    std::unique_ptr<KeyFrameFinder> m_keyframe_finder;
    int n_dropped_frames=0;
    BitrateCalculator m_rtp_bitrate;
    PacketDropEmulator m_packet_drop_emulator{1};
private:
    // Calculate fps, but note that this actually calculates the non-sps / pps / vps NALUs per second
    FPSCalculator m_estimate_fps_calculator{};
#ifdef OPENHD_USE_LIB_UVGRTP
private:
    uvgrtp::context m_ctx;
    uvgrtp::session *m_session;
    uvgrtp::media_stream *m_receiver;
public:
    void uvgrtp_rtp_receive_hook(void *arg, uvgrtp::frame::rtp_frame *frame);
#endif
};

#endif // RTPRECEIVER_H
