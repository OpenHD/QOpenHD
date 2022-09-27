#include "rtpreceiver.h"

#include <qdebug.h>

#include "../common_consti/StringHelper.hpp"

RTPReceiver::RTPReceiver(int port,bool is_h265):
    is_h265(is_h265)
{
    m_keyframe_finder=std::make_unique<KeyFrameFinder>();
    m_rtp_decoder=std::make_unique<RTPDecoder>([this](const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size){
        this->nalu_data_callback(creation_time,nalu_data,nalu_data_size);
    });

    const auto cb = [this](const uint8_t *payload, const std::size_t payloadSize)mutable {
          this->udp_raw_data_callback(payload,payloadSize);
        };
    m_udp_receiver=std::make_unique<UDPReceiver>(port,"V_REC",cb);
    m_udp_receiver->startReceiving();
}

RTPReceiver::~RTPReceiver()
{
    m_udp_receiver->stopReceiving();
}


std::shared_ptr<std::vector<uint8_t> > RTPReceiver::get_data()
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    if(m_data.size()<=0)return nullptr;
    auto ret=m_data.front();
    m_data.pop();
    return ret;
}

std::unique_ptr<std::vector<uint8_t>> RTPReceiver::get_config_data()
{
     std::lock_guard<std::mutex> lock(m_data_mutex);
     if(m_keyframe_finder->allKeyFramesAvailable(is_h265)){
         return m_keyframe_finder->get_keyframe_data(is_h265);
     }
     return nullptr;
}

void RTPReceiver::queue_data(std::shared_ptr<std::vector<uint8_t>> data)
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    {
        NALU nalu(data->data(),data->size(),is_h265);
        if(m_keyframe_finder->saveIfKeyFrame(nalu)){
            return;
        }
    }
    if(m_data.size()>30)m_data.pop();
    m_data.push(data);
}


void RTPReceiver::udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize)
{
    qDebug()<<"Got UDP data "<<payloadSize;
    if(is_h265){
        m_rtp_decoder->parseRTPH265toNALU(payload,payloadSize);
        //m_rtp_decoder->parse_rtp_mjpeg(payload,payloadSize);
    }else{
        m_rtp_decoder->parseRTPH264toNALU(payload,payloadSize);
    }
}


void RTPReceiver::nalu_data_callback(const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size)
{
    qDebug()<<"Got RTP "<<nalu_data_size;

    std::vector<uint8_t> tmp(nalu_data,nalu_data+nalu_data_size);
    //qDebug()<<StringHelper::vectorAsString(tmp).c_str()<<"\n";

    if(m_out_file==nullptr){
        std::stringstream ss;
        ss<<"/tmp/received_rtp.";
        if(is_h265){
            ss<<"h265";
        }else{
            ss<<"h264";
        }
        m_out_file=std::make_unique<std::ofstream>(ss.str());
    }
    m_out_file->write((const char*)nalu_data,nalu_data_size);
    m_out_file->flush();

    auto copy=std::make_shared<std::vector<uint8_t>>(nalu_data,nalu_data+nalu_data_size);
    queue_data(copy);
}

