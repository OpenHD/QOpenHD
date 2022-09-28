#include "rtpreceiver.h"

#include <qdebug.h>

#include "../common_consti/StringHelper.hpp"

RTPReceiver::RTPReceiver(int port,bool is_h265):
    is_h265(is_h265)
{
    if(false){
        // Debug write raw data to file
        std::stringstream ss;
        ss<<"/tmp/received_rtp.";
        if(is_h265){
            ss<<"h265";
        }else{
            ss<<"h264";
        }
        m_out_file=std::make_unique<std::ofstream>(ss.str());
    }
    m_keyframe_finder=std::make_unique<KeyFrameFinder>();
    m_rtp_decoder=std::make_unique<RTPDecoder>([this](const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size){
        this->nalu_data_callback(creation_time,nalu_data,nalu_data_size);
    });
    m_udp_receiver=std::make_unique<UDPReceiver>(port,"V_REC",[this](const uint8_t *payload, const std::size_t payloadSize){
        this->udp_raw_data_callback(payload,payloadSize);
    });
    m_udp_receiver->startReceiving();
}

RTPReceiver::~RTPReceiver()
{
    m_udp_receiver->stopReceiving();
}


 std::shared_ptr<NALU> RTPReceiver::get_data()
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    if(m_data.size()<=0)return nullptr;
    auto ret=m_data.front();
    m_data.pop();
    return ret;
}

std::shared_ptr<std::vector<uint8_t>> RTPReceiver::get_config_data()
{
     std::lock_guard<std::mutex> lock(m_data_mutex);
     if(m_keyframe_finder->allKeyFramesAvailable(is_h265)){
         return m_keyframe_finder->get_keyframe_data(is_h265);
     }
     return nullptr;
}

void RTPReceiver::queue_data(const uint8_t* nalu_data,const std::size_t nalu_data_len)
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    NALU nalu(nalu_data,nalu_data_len,is_h265);
    if(m_keyframe_finder->allKeyFramesAvailable(is_h265)){
        if(!m_keyframe_finder->check_is_still_same_config_data(nalu)){
            config_has_changed_during_decode=true;
            return;
        }
         // If we have all config data, start storing video frames
        if(nalu.is_config())return;
        if(nalu.is_aud())return;
        if(nalu.is_sei())return;
        if(m_data.size()>20)m_data.pop();
        m_data.push(std::make_shared<NALU>(nalu));
        return;
    }
    // We don't have all config data yet, drop anything that is not config data.
    m_keyframe_finder->saveIfKeyFrame(nalu);
}

void RTPReceiver::udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize)
{
    //qDebug()<<"Got UDP data "<<payloadSize;
    if(is_h265){
        m_rtp_decoder->parseRTPH265toNALU(payload,payloadSize);
        //m_rtp_decoder->parse_rtp_mjpeg(payload,payloadSize);
    }else{
        m_rtp_decoder->parseRTPH264toNALU(payload,payloadSize);
    }
}

void RTPReceiver::nalu_data_callback(const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size)
{
    //qDebug()<<"Got NALU "<<nalu_data_size;
    {
        //std::vector<uint8_t> tmp(nalu_data,nalu_data+nalu_data_size);
        //qDebug()<<StringHelper::vectorAsString(tmp).c_str()<<"\n";
    }
    if(m_out_file!=nullptr){
        m_out_file->write((const char*)nalu_data,nalu_data_size);
        m_out_file->flush();
    }
    queue_data(nalu_data,nalu_data_size);
}

