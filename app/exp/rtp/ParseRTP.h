//
// Created by Constantin on 2/6/2019.
//

#ifndef LIVE_VIDEO_10MS_ANDROID_PARSERTP_H
#define LIVE_VIDEO_10MS_ANDROID_PARSERTP_H

#include <chrono>
#include <cstdio>
#include <functional>
#include "RTP.hpp"

/*********************************************
 ** Parses a stream of rtp h264 / h265 data into NALUs
**********************************************/

static constexpr const auto NALU_MAXLEN=1024*1024;
typedef std::function<void(const uint8_t* nalu_data,const int nalu_data_size)> NALU_DATA_CALLBACK;

class RTPDecoder{
public:
    RTPDecoder(NALU_DATA_CALLBACK cb);
public:
    // check if a packet is missing by using the rtp sequence number and
    // if the payload is dynamic (h264 or h265)
    // Returns false if payload is wrong
    // sets the 'missing packet' flag to true if packet got lost
    bool validateRTPPacket(const rtp_header_t& rtpHeader);
    // parse rtp h264 packet to NALU
    void parseRTPH264toNALU(const uint8_t* rtp_data, const size_t data_length);
    // parse rtp h265 packet to NALU
    void parseRTPH265toNALU(const uint8_t* rtp_data, const size_t data_length);
    // reset mNALU_DATA_LENGTH to 0
    void reset();
private:
    // copy data_len bytes into the mNALU_DATA buffer at the current position
    // and increase mNALU_DATA_LENGTH by data_len
    void appendNALUData(const uint8_t* data, size_t data_len);
    // Write 0,0,0,1 into the start of the NALU buffer and set the length to 4
    void write_h264_h265_nalu_start();
    // Properly calls the cb function
    // Resets the mNALU_DATA_LENGTH to 0
    void forwardNALU(const std::chrono::steady_clock::time_point creationTime,const bool isH265=false);
    const NALU_DATA_CALLBACK cb;
    std::array<uint8_t,NALU_MAXLEN> mNALU_DATA;
    size_t mNALU_DATA_LENGTH=0;
private:
    //TDOD: What shall we do if a start, middle or end of fu-a is missing ?
    int lastSequenceNumber=-1;
    bool flagPacketHasGoneMissing=false;
    // This time point is as 'early as possible' to debug the parsing time as accurately as possible.
    // E.g for a fu-a NALU the time point when the start fu-a was received, not when its end is received
    std::chrono::steady_clock::time_point timePointStartOfReceivingNALU;
private:
    // reconstruct and forward a single nalu, either from a "single" or "aggregated" rtp packet (not from a fragmented packet)
    // data should point to the nalu_header_t, size includes the nalu_header_t size and the following bytes that make up the nalu
    void h264_reconstruct_and_forward_one_nalu(const uint8_t* data,int data_size);
    // forwardt a single nalu, either froma a "single" or "aggregated" rtp packet (not from a fragmented packet)
    // ( In contrast to h264 we don't need the stupid reconstruction with h265)
    // data should point to "just" the rtp payload
    void h265_forward_one_nalu(const uint8_t* data,int data_size);
};

#endif //LIVE_VIDEO_10MS_ANDROID_PARSERTP_H
