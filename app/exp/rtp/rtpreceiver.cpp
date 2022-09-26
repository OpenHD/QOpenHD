#include "rtpreceiver.h"

#include <qdebug.h>



RTPReceiver::RTPReceiver()
{

    m_rtp_decoder=std::make_unique<RTPDecoder>([this](const uint8_t *nalu_data, const int nalu_data_size){
        this->nalu_data_callback(nalu_data,nalu_data_size);
    });

    const auto cb = [this](const uint8_t *payload, const std::size_t payloadSize)mutable {
          this->udp_raw_data_callback(payload,payloadSize);
        };
    m_udp_receiver=std::make_unique<UDPReceiver>(5600,"V_REC",cb);
    m_udp_receiver->startReceiving();
}


void RTPReceiver::udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize)
{
    qDebug()<<"Got UDP data "<<payloadSize;
    //m_rtp_decoder->parseRTPH264toNALU(payload,payloadSize);
    m_rtp_decoder->parseRTPH265toNALU(payload,payloadSize);
}


void RTPReceiver::nalu_data_callback(const uint8_t *nalu_data, const int nalu_data_size)
{
    qDebug()<<"Got RTP "<<nalu_data_size;
}
