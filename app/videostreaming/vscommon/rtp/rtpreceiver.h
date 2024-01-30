#ifndef RTPRECEIVER_H
#define RTPRECEIVER_H


#include "ParseRTP.h"
#include <memory>
#include "../udp/UDPReceiver.h"

#include <fstream>
#include <mutex>
#include <functional>

#include "../nalu/NALU.hpp"
#include "../nalu/CodecConfigFinder.hpp"

#include "common/TimeHelper.hpp"
#include "common/moodycamel/readerwriterqueue/readerwritercircularbuffer.h"

//#define OPENHD_USE_LIB_UVGRTP

#ifdef OPENHD_USE_LIB_UVGRTP
#include <uvgrtp/lib.hh>
#endif

class RTPReceiver
{
public:
    RTPReceiver(int port,std::string ip,bool is_h265,bool feed_incomplete_frames);
    ~RTPReceiver();

    // Returns the oldest frame if available.
    // (nullptr on failure)
    // The timeout is optional
    std::shared_ptr<NALUBuffer> get_next_frame(std::optional<std::chrono::microseconds> timeout=std::nullopt);
    // Instead of using a queue and another thread for fetching data between what's basically the udp receiver
    // and the decoder, you can register a callback here that is called directly when there is a new NALU
    // available. Note that care needs to be taken to not perform any blocking operation(s) in this callback -
    // aka the decoder should have a queue internally when using this mode. Can decrease latency (scheduling latency) though
    typedef std::function<void(const NALU& nalu)> NEW_NALU_CALLBACK;
    void register_new_nalu_callback(NEW_NALU_CALLBACK cb);
    // return nullptr if not enough config data is available yet, otherwise, return valid config data
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
    std::unique_ptr<std::ofstream> m_out_file=nullptr;
private:
    const bool is_h265;
private:
    std::mutex m_data_mutex;
    // space for up to X NALUs to account for "weird" cases, fifo anyways
    // In case the decoder cannot keep up with the data we provide to it, the only fix would be to reduce the fps/resolution anyways.
    moodycamel::BlockingReaderWriterCircularBuffer<std::shared_ptr<NALUBuffer>> m_data_queue{20};
    void queue_data(const uint8_t* nalu_data,const std::size_t nalu_data_len);
    std::mutex m_new_nalu_data_cb_mutex;
    NEW_NALU_CALLBACK m_new_nalu_cb=nullptr;
    bool forward_via_cb_if_registered();
private:
    std::unique_ptr<CodecConfigFinder> m_keyframe_finder;
    int n_dropped_frames=0;
    BitrateCalculator m_rtp_bitrate;
private:
    // Calculate fps, but note that this might not give the exact/correct value in some case(s)
    FPSCalculator m_estimate_fps_calculator{};
#ifdef OPENHD_USE_LIB_UVGRTP
private:
    uvgrtp::context m_ctx;
    uvgrtp::session *m_session;
    uvgrtp::media_stream *m_receiver;
public:
    void uvgrtp_rtp_receive_hook(void *arg, uvgrtp::frame::rtp_frame *frame);
#endif
private:
    int n_frames_non_idr=0;
    int n_frames_idr=0;
private:
    std::chrono::steady_clock::time_point m_last_log_hud_dropped_frame=std::chrono::steady_clock::now();
    int dev_count=0;
};

#endif // RTPRECEIVER_H
