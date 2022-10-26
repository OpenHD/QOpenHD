//
// Created by Constantin on 2/6/2019.
//

#ifndef LIVE_VIDEO_10MS_ANDROID_NALU_H
#define LIVE_VIDEO_10MS_ANDROID_NALU_H

//https://github.com/Dash-Industry-Forum/Conformance-and-reference-source/blob/master/conformance/TSValidator/h264bitstream/h264_stream.h

#include <cstring>
#include <string>
#include <chrono>
#include <sstream>
#include <array>
#include <vector>
#include <variant>
#include <optional>
#include <assert.h>
#include <memory>

#include "NALUnitType.hpp"

// dependency could be easily removed again
#include <h264_common.h>
#include <sps_parser.h>
#include <pps_parser.h>

/**
 * A NALU either contains H264 data (default) or H265 data
 * NOTE: Only when copy constructing a NALU it owns the data, else it only holds a data pointer (that might get overwritten by the parser if you hold onto a NALU)
 * Also, H264 and H265 is slightly different
 * The constructor of the NALU does some really basic validation - make sure the parser never produces a NALU where this validation would fail
 */
class NALU{
public:
    // test video white iceland: Max 1024*117. Video might not be decodable if its NALU buffers size exceed the limit
    // But a buffer size of 1MB accounts for 60fps video of up to 60MB/s or 480 Mbit/s. That should be plenty !
    static constexpr const auto NALU_MAXLEN=1024*1024;
    // Application should re-use NALU_BUFFER to avoid memory allocations
    using NALU_BUFFER=std::array<uint8_t,NALU_MAXLEN>;
    // Copy constructor allocates new buffer for data (heavy)
    NALU(const NALU& nalu):
    ownedData(std::vector<uint8_t>(nalu.getData(),nalu.getData()+nalu.getSize())),
    data(ownedData->data()),data_len(nalu.getSize()),IS_H265_PACKET(nalu.IS_H265_PACKET),creationTime(nalu.creationTime){
        //MLOGD<<"NALU copy constructor";
    }
    // Default constructor does not allocate a new buffer,only stores some pointer (light)
    NALU(const NALU_BUFFER& data1,const size_t data_length,const bool IS_H265_PACKET1=false,const std::chrono::steady_clock::time_point creationTime=std::chrono::steady_clock::now()):
            data(data1.data()),data_len(data_length),IS_H265_PACKET(IS_H265_PACKET1),creationTime{creationTime}{
        // Validate correctness of NALU (make sure parser never forwards NALUs where this assertion fails)
        assert(hasValidPrefix());
        assert(getSize()>=getMinimumNaluSize(IS_H265_PACKET1));
    };
    // tmp
    NALU(const uint8_t* data1,size_t data_len1,const bool IS_H265_PACKET1=false,const std::chrono::steady_clock::time_point creationTime=std::chrono::steady_clock::now()):
            data(data1),data_len(data_len1),IS_H265_PACKET(IS_H265_PACKET1),creationTime{creationTime}
    {
        assert(hasValidPrefix());
        assert(getSize()>=getMinimumNaluSize(IS_H265_PACKET1));
    }
    ~NALU()= default;
private:
    // With the default constructor a NALU does not own its memory. This saves us one memcpy. However, storing a NALU after the lifetime of the
    // Non-owned memory expired is also needed in some places, so the copy-constructor creates a copy of the non-owned data and stores it in a optional buffer
    // WARNING: Order is important here (Initializer list). Declare before data pointer
    const std::optional<std::vector<uint8_t>> ownedData={};
    const uint8_t* data;
    const size_t data_len;
public:
    const bool IS_H265_PACKET;
    // creation time is used to measure latency
    const std::chrono::steady_clock::time_point creationTime;
public:
    // returns true if starts with 0001, false otherwise
    bool hasValidPrefix()const{
        return data[0]==0 && data[1]==0 &&data[2]==0 &&data[3]==1;
    }
    static std::size_t getMinimumNaluSize(const bool isH265){
        // 4 bytes prefix, 1 byte header for h264, 2 byte header for h265
        return isH265 ? 6 : 5;
    }
public:
    // pointer to the NALU data with 0001 prefix
    const uint8_t* getData()const{
        return data;
    }
    // size of the NALU data with 0001 prefix
    const size_t getSize()const{
        return data_len;
    }
    //pointer to the NALU data without 0001 prefix
    const uint8_t* getDataWithoutPrefix()const{
        return &getData()[4];
    }
    //size of the NALU data without 0001 prefix
    const ssize_t getDataSizeWithoutPrefix()const{
        return getSize()-4;
    }
    // return the nal unit type (quick)
   int get_nal_unit_type()const{
       if(IS_H265_PACKET){
           return (getData()[4] & 0x7E)>>1;
       }
       return getData()[4]&0x1f;
   }
public:
   bool isSPS()const{
       if(IS_H265_PACKET){
           return get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_SPS;
       }
       return (get_nal_unit_type() == NALUnitType::H264::NAL_UNIT_TYPE_SPS);
   }
   bool isPPS()const{
       if(IS_H265_PACKET){
           return get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_PPS;
       }
       return (get_nal_unit_type() == NALUnitType::H264::NAL_UNIT_TYPE_PPS);
   }
   // VPS NALUs are only possible in H265
   bool isVPS()const{
       assert(IS_H265_PACKET);
       return get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_VPS;
   }
   bool is_aud()const{
       if(IS_H265_PACKET){
           return get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_ACCESS_UNIT_DELIMITER;
       }
       return (get_nal_unit_type() == NALUnitType::H264::NAL_UNIT_TYPE_AUD);
   }
   bool is_sei()const{
       if(IS_H265_PACKET){
           return get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_PREFIX_SEI || get_nal_unit_type()==NALUnitType::H265::NAL_UNIT_SUFFIX_SEI;
       }
       return (get_nal_unit_type() == NALUnitType::H264::NAL_UNIT_TYPE_SEI);
   }
   bool is_dps()const{
       if(IS_H265_PACKET){
           // doesn't exist in h265
           return false;
       }
       return (get_nal_unit_type() == NALUnitType::H264::NAL_UNIT_TYPE_DPS);
   }
   bool is_config(){
       return isSPS() || isPPS() || (IS_H265_PACKET && isVPS());
   }
   std::array<int,2> sps_get_width_height()const{
       assert(isSPS());
       // r.n we only support fetching with and height from sps for h264 (and only need it in this case anyways)
       assert(!IS_H265_PACKET);
       const auto offset_for_webrtc=4+webrtc::H264::kNaluTypeSize;
       auto _sps = webrtc::SpsParser::ParseSps(getData() + offset_for_webrtc, getSize() - offset_for_webrtc);
       if(_sps){
           const int width=_sps->width;
           const int height=_sps->height;
           return {width,height};
       }
       return {640,480};
   }
};



#endif //LIVE_VIDEO_10MS_ANDROID_NALU_H
