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
#include <qdebug.h>

/**
 * NOTE: NALU only takes a c-style data pointer - it does not do any memory management. Use NALUBuffer if you need to store a NALU.
 * Since H264 and H265 are that similar, we use this class for both (make sure to not call methds only supported on h265 with a h264 nalu,though)
 * The constructor of the NALU does some really basic validation - make sure the parser never produces a NALU where this validation would fail
 */
class NALU{
public:
    NALU(const uint8_t* data1,size_t data_len1,const bool IS_H265_PACKET1=false,const std::chrono::steady_clock::time_point creationTime=std::chrono::steady_clock::now()):
            m_data(data1),m_data_len(data_len1),IS_H265_PACKET(IS_H265_PACKET1),creationTime{creationTime}
    {
        assert(hasValidPrefix());
        assert(getSize()>=getMinimumNaluSize(IS_H265_PACKET1));
        m_nalu_prefix_size=get_nalu_prefix_size();
    }
    ~NALU()= default;
    // test video white iceland: Max 1024*117. Video might not be decodable if its NALU buffers size exceed the limit
    // But a buffer size of 1MB accounts for 60fps video of up to 60MB/s or 480 Mbit/s. That should be plenty !
    static constexpr const auto NALU_MAXLEN=1024*1024;
    // Application should re-use NALU_BUFFER to avoid memory allocations
    using NALU_BUFFER=std::array<uint8_t,NALU_MAXLEN>;
private:
    const uint8_t* m_data;
    const size_t m_data_len;
    int m_nalu_prefix_size;
public:
    const bool IS_H265_PACKET;
    // creation time is used to measure latency
    const std::chrono::steady_clock::time_point creationTime;
public:
    // returns true if starts with 0001, false otherwise
    bool hasValidPrefixLong()const{
        return m_data[0]==0 && m_data[1]==0 &&m_data[2]==0 &&m_data[3]==1;
    }
    // returns true if starts with 001 (short prefix), false otherwise
    bool hasValidPrefixShort()const{
        return m_data[0]==0 && m_data[1]==0 &&m_data[2]==1;
    }
    bool hasValidPrefix()const{
        return hasValidPrefixLong() || hasValidPrefixShort();
    }
    int get_nalu_prefix_size()const{
        if(hasValidPrefixLong())return 4;
        return 3;
    }
    static std::size_t getMinimumNaluSize(const bool isH265){
        // 4 bytes prefix, 1 byte header for h264, 2 byte header for h265
        return isH265 ? 6 : 5;
    }
public:
    // pointer to the NALU data with 0001 prefix
    const uint8_t* getData()const{
        return m_data;
    }
    // size of the NALU data with 0001 prefix
    size_t getSize()const{
        return m_data_len;
    }
    //pointer to the NALU data without 0001 prefix
    const uint8_t* getDataWithoutPrefix()const{
        return &getData()[m_nalu_prefix_size];
    }
    //size of the NALU data without 0001 prefix
    int getDataSizeWithoutPrefix()const{
        return getSize()-m_nalu_prefix_size;
    }
    // return the nal unit type (quick)
   int get_nal_unit_type()const{
       if(IS_H265_PACKET){
           return (getDataWithoutPrefix()[0] & 0x7E)>>1;
       }
       return getDataWithoutPrefix()[0]&0x1f;
   }
   std::string get_nal_unit_type_as_string()const{
       if(IS_H265_PACKET){
           return NALUnitType::H265::unit_type_to_string(get_nal_unit_type());
       }
       return NALUnitType::H264::unit_type_to_string(get_nal_unit_type());
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
   // keyframe / IDR frame
   bool is_keyframe()const{
       const auto nut=get_nal_unit_type();
       if(IS_H265_PACKET){
           return false;
       }
       if(nut==NALUnitType::H264::NAL_UNIT_TYPE_CODED_SLICE_IDR){
           return true;
       }
       return false;
   }
   bool is_frame_but_not_keyframe()const{
       const auto nut=get_nal_unit_type();
       if(IS_H265_PACKET)return false;
       return (nut==NALUnitType::H264::NAL_UNIT_TYPE_CODED_SLICE_NON_IDR);
   }
   std::array<int,2> sps_get_width_height()const{
       assert(isSPS());
       // r.n we only support fetching with and height from sps for h264 (and only need it in this case anyways)
       assert(!IS_H265_PACKET);
       const auto offset_for_webrtc=webrtc::H264::kNaluTypeSize;
       auto _sps = webrtc::SpsParser::ParseSps(getDataWithoutPrefix() + offset_for_webrtc, getDataSizeWithoutPrefix() - offset_for_webrtc);
       if(_sps){
           const int width=_sps->width;
           const int height=_sps->height;
           return {width,height};
       }
       return {640,480};
   }
   // Print all sps info, for debugging
   std::string get_sps_as_string()const{
       if(!isSPS())return "no sps";
       const auto offset_for_webrtc=webrtc::H264::kNaluTypeSize;
       auto sps_opt = webrtc::SpsParser::ParseSps(getDataWithoutPrefix() + offset_for_webrtc, getDataSizeWithoutPrefix() - offset_for_webrtc);
       if(!sps_opt){
           return "cannot parse sps";
       }
       auto sps=sps_opt.value();
       std::stringstream ss;
       ss<<"SPS{"<<sps.width<<"x"<<sps.height<<" ";
       ss<<"delta_pic_order_always_zero_flag:"<<sps.delta_pic_order_always_zero_flag<<",";
       ss<<"frame_mbs_only_flag:"<<sps.frame_mbs_only_flag<<",";
       ss<<"log2_max_frame_num:"<<sps.log2_max_frame_num<<",";
       ss<<"log2_max_pic_order_cnt_lsb:"<<sps.log2_max_pic_order_cnt_lsb<<",";
       ss<<"pic_order_cnt_type:"<<sps.pic_order_cnt_type<<",";
       ss<<"max_num_ref_frames:"<<sps.max_num_ref_frames<<",";
       ss<<"vui_params_present:"<<sps.vui_params_present<<",";
       ss<<"id:"<<sps.id<<"}";
       return ss.str();
   }
};

// Copies the nalu data into its own c++-style managed buffer.
class NALUBuffer{
public:
    NALUBuffer(const uint8_t* data,int data_len,bool is_h265,std::chrono::steady_clock::time_point creation_time){
        m_data=std::make_shared<std::vector<uint8_t>>(data,data+data_len);
        m_nalu=std::make_unique<NALU>(m_data->data(),m_data->size(),is_h265,creation_time);
    }
    NALUBuffer(const NALU& nalu){
        m_data=std::make_shared<std::vector<uint8_t>>(nalu.getData(),nalu.getData()+nalu.getSize());
        m_nalu=std::make_unique<NALU>(m_data->data(),m_data->size(),nalu.IS_H265_PACKET,nalu.creationTime);
    }
    NALUBuffer(const NALUBuffer&)=delete;
    NALUBuffer(const NALUBuffer&&)=delete;

    const NALU& get_nal(){
        return *m_nalu;
    }
private:
    std::shared_ptr<std::vector<uint8_t>> m_data;
    std::unique_ptr<NALU> m_nalu;
};

#endif //LIVE_VIDEO_10MS_ANDROID_NALU_H


