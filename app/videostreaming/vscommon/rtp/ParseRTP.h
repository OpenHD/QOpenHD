//
// Created by Constantin on 2/6/2019.
//

#ifndef LIVE_VIDEO_10MS_ANDROID_PARSERTP_H
#define LIVE_VIDEO_10MS_ANDROID_PARSERTP_H

#include <chrono>
#include <cstdio>
#include <functional>
#include <array>
#include "RTP.hpp"

/*********************************************
 ** Parses a stream of rtp h264 / h265 data into NALUs.
 ** No rtp jitterbuffer or similar - this decreases latency, but removes any rtp packet re-ordering capabilities.
 ** Aka this decoder can deal with lost packets (incomplete rtp fragments are dropped) but requires received packets to
 ** be in order.
 ** No special dependencies other than std library.
 ** R.n Supports single, aggregated and fragmented rtp packets for both h264 and h265.
 ** Data is forwarded directly via a callback for no thread scheduling overhead
**********************************************/

// Enough for pretty much any resolution/framerate we handle in OpenHD
static constexpr const auto NALU_MAXLEN=1024*1024;

typedef std::function<void(const std::chrono::steady_clock::time_point creation_time,const uint8_t* nalu_data,const int nalu_data_size)> RTP_FRAME_DATA_CALLBACK;

class RTPDecoder{
public:
    // NALUs are passed on via the callback, one by one.
    // (Each time the callback is called, it contains exactly one NALU prefixed with the 0,0,0,1 start code)
    RTPDecoder(RTP_FRAME_DATA_CALLBACK cb,bool feed_incomplete_frames);
    // check if a packet is missing by using the rtp sequence number and
    // if the payload is dynamic (h264 or h265)
    // Returns false if payload is wrong
    // sets the 'missing packet' flag to true if packet got lost
    bool validateRTPPacket(const rtp_header_t& rtpHeader);
    // parse rtp h264 packet to NALU
    void parseRTPH264toNALU(const uint8_t* rtp_data, const size_t data_length);
    // parse rtp h265 packet to NALU
    void parseRTPH265toNALU(const uint8_t* rtp_data, const size_t data_length);
    // exp
    void parse_rtp_mjpeg(const uint8_t* rtp_data, const size_t data_length);
    // reset to defaults
    void reset();
private:
    // Write 0,0,0,1 (or 0,0,1) into the start of the NALU buffer and set the length to 4 / 3
    void write_h264_h265_nalu_start(bool use_4_bytes=true);
    // copy data_len bytes into the data buffer at the current position
    // and increase its size by data_len
    void append_nalu_data(const uint8_t* data, size_t data_len);
    // like append_nalu_data, but for one byte
    void append_nalu_data_byte(uint8_t byte);
    void append_empty(size_t data_len);
    // Properly calls the cb function (if not null)
    // Resets the m_nalu_data_length to 0
    void forwardNALU(const bool isH265=false);
    const RTP_FRAME_DATA_CALLBACK m_cb;
    //std::shared_ptr<std::array<uint8_t,NALU_MAXLEN>> m_curr_nalu{};
    std::array<uint8_t,NALU_MAXLEN> m_curr_nalu;
    size_t m_nalu_data_length=0;
    bool m_feed_incomplete_frames;
    int m_total_n_fragments_for_current_fu=0;
private:
    //TDOD: What shall we do if a start, middle or end of fu-a is missing ?
    int lastSequenceNumber=-1;
    bool flagPacketHasGoneMissing=false;
public:
    // each time there is a "gap" between packets, this counter is increased
    int m_n_gaps=0;
    int m_n_lost_packets=0;
    // This time point is as 'early as possible' to debug the parsing time as accurately as possible.
    // E.g for a fu-a NALU the time point when the start fu-a was received, not when its end is received
    std::chrono::steady_clock::time_point timePointStartOfReceivingNALU;
private:
    // reconstruct and forward a single nalu, either from a "single" or "aggregated" rtp packet (not from a fragmented packet)
    // data should point to the nalu_header_t, size includes the nalu_header_t size and the following bytes that make up the nalu
    void h264_reconstruct_and_forward_one_nalu(const uint8_t* data,int data_size);
    // forward a single nalu, either froma a "single" or "aggregated" rtp packet (not from a fragmented packet)
    // ( In contrast to h264 we don't need the stupid reconstruction with h265)
    // data should point to "just" the rtp payload
    void h265_forward_one_nalu(const uint8_t* data,int data_size,bool write_4_bytes_for_start_code=true);
    // wtf
    static bool check_has_valid_prefix(const uint8_t* nalu_data,int nalu_data_len,bool use_4_bytes_start_code);
    bool check_curr_nalu_has_valid_prefix(bool use_4_bytes_start_code);
    // we can clear the missing packet flag when we either receive the first packet of a fragmented rtp packet or
    // a non-fragmented rtp packet
    //void clear_missing_packet_flag();
    int curr_packet_diff=0;
private:
    std::chrono::steady_clock::time_point m_last_log_wrong_rtp_payload_time=std::chrono::steady_clock::now();
};

#endif //LIVE_VIDEO_10MS_ANDROID_PARSERTP_H
