//
// Created by Constantin on 2/6/2019.
//

#include "ParseRTP.h"
#include <cstring>
#include <iostream>
#include <qdebug.h>

RTPDecoder::RTPDecoder(NALU_DATA_CALLBACK cb): cb(std::move(cb)){
}

void RTPDecoder::reset(){
    mNALU_DATA_LENGTH=0;
    //nalu_data.reserve(NALU::NALU_MAXLEN);
}

bool RTPDecoder::validateRTPPacket(const rtp_header_t& rtp_header) {
    if(rtp_header.payload!=RTP_PAYLOAD_TYPE_GENERIC){
        std::cerr<<"Unsupported payload type "<<(int)rtp_header.payload;
        //return false;
    }
    // Testing regarding sequence numbers.This stuff can be removed without issues
    const int seqNr=rtp_header.getSequence();
    if(seqNr==lastSequenceNumber){
        // duplicate. This should never happen for 'normal' rtp streams, but can be usefully when testing bitrates
        // (Since you can send the same packet multiple times to emulate a higher bitrate)
        std::cerr<<"Same seqNr";
        return false;
    }
    if(lastSequenceNumber==-1){
        // first packet in stream
        flagPacketHasGoneMissing=false;
    }else{
        // Don't forget that the sequence number loops every UINT16_MAX packets
        if(seqNr != ((lastSequenceNumber+1) % UINT16_MAX)){
            // We are missing a Packet !
            std::cerr<<"missing a packet. Last:"<<lastSequenceNumber<<" Curr:"<<seqNr<<" Diff:"<<(seqNr-(int)lastSequenceNumber);
            //flagPacketHasGoneMissing=true;
        }
    }
    lastSequenceNumber=seqNr;
    return true;
}

void RTPDecoder::h264_reconstruct_and_forward_one_nalu(const uint8_t *data,const int data_size)
{
    assert(data_size>sizeof(nalu_header_t));
    const nalu_header_t& nalu_header=*(const nalu_header_t*) &data[0];
    timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
    // Full NALU - we can remove the 'drop packet' flag
    if(flagPacketHasGoneMissing){
        std::cerr<<"Got full NALU - clearing missing packet flag";
        flagPacketHasGoneMissing= false;
    }
    write_h264_h265_nalu_start();
    const uint8_t h264_nal_header = (uint8_t )(nalu_header.type & 0x1f)
                                    | (nalu_header.nri << 5)
                                    | (nalu_header.f << 7);
    // write the reconstructed NAL header (the h264 "type")
    append_nalu_data(&h264_nal_header,1);
    // write the rest of the data
    append_nalu_data(&data[1], (size_t)data_size - 1);
    // forward via callback
    forwardNALU(timePointStartOfReceivingNALU);
    // reset length after forwarding
    mNALU_DATA_LENGTH=0;
}

void RTPDecoder::parseRTPH264toNALU(const uint8_t* rtp_data, const size_t data_length){
    //12 rtp header bytes and 1 nalu_header_t type byte
    if(data_length <= sizeof(rtp_header_t)+sizeof(nalu_header_t)){
        std::cerr<<"Not enough rtp data";
        return;
    }
    //MLOGD<<"Got rtp data";
    const RTP::RTPPacketH264 rtpPacket(rtp_data,data_length);
    //MLOGD<<"RTP Header: "<<rtp_header->asString();
    if(!validateRTPPacket(rtpPacket.header)){
        return;
    }
    const auto& nalu_header=rtpPacket.getNALUHeaderH264();
    if (nalu_header.type == 28) { /* FU-A */
        qDebug()<<"Got RTP H264 type 28 (fragmented) payload size:"<<rtpPacket.rtpPayloadSize;
        const auto& fu_header=rtpPacket.getFuHeader();
        const auto fu_payload=rtpPacket.getFuPayload();
        const auto fu_payload_size=rtpPacket.getFuPayloadSize();
        if (fu_header.e == 1) {
            //MLOGD<<"End of fu-a";
            // end of fu-a
            append_nalu_data(fu_payload, fu_payload_size);
            if(!flagPacketHasGoneMissing){
                // To better measure latency we can actually use the timestamp from when the first bytes for this packet were received
                forwardNALU(timePointStartOfReceivingNALU);
            }
            mNALU_DATA_LENGTH=0;
        } else if (fu_header.s == 1) {
            //MLOGD<<"Start of fu-a";
            timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
            // Beginning of new fu sequence - we can remove the 'drop packet' flag
            if(flagPacketHasGoneMissing){
                std::cerr<<"Got fu-a start - clearing missing packet flag";
                flagPacketHasGoneMissing=false;
            }
            // start of fu-a
            write_h264_h265_nalu_start();
            const uint8_t h264_nal_header = (uint8_t)(fu_header.type & 0x1f)
                                            | (nalu_header.nri << 5)
                                            | (nalu_header.f << 7);
            mNALU_DATA[mNALU_DATA_LENGTH]=h264_nal_header;
            mNALU_DATA_LENGTH++;
            append_nalu_data(fu_payload, fu_payload_size);
        } else {
            //MLOGD<<"Middle of fu-a";
            // middle of fu-a
            append_nalu_data(fu_payload, fu_payload_size);
        }
    } else if(nalu_header.type>0 && nalu_header.type<24){
        qDebug()<<"Got RTP H264 type [1..23] (single) payload size:"<<rtpPacket.rtpPayloadSize;
        h264_reconstruct_and_forward_one_nalu(rtpPacket.rtpPayload,rtpPacket.rtpPayloadSize);
    }else if(nalu_header.type==24){
        qDebug()<<"Got RTP H264 type 24 (aggregated NALUs) payload size:"<<rtpPacket.rtpPayloadSize;
        const uint8_t* rtp_payload=rtpPacket.rtpPayload;
        const auto rtp_payload_size=rtpPacket.rtpPayloadSize;
        int offset=0;
        while(true){
            // the size of the (n-th) nalu starts at offset+1 (1 byte STAP-A NAL HDR )
            const uint16_t* nalu_size_network=(const uint16_t*)&rtp_payload[offset+1];
            const uint16_t nalu_size= htons(*nalu_size_network);
            // While the NALU HDR of the (n-th) nalu starts at offset+3 (1 byte STAP-A NAL HDR, 2 bytes nalu size)
            const uint8_t* actual_nalu_data_p=&rtp_payload[offset+1+2];
            const auto actual_nalu_size=nalu_size;
            qDebug()<<"XNALU of size:"<<(int)actual_nalu_size;
            h264_reconstruct_and_forward_one_nalu(actual_nalu_data_p,actual_nalu_size);
            offset+=2+actual_nalu_size;
            if(!(rtp_payload_size>offset+3)){
                break;
            }
        }
    }else{
        std::cerr<<"Got unsupported H264 RTP packet. NALU type:"<<(int)nalu_header.type<<"\n";
    }
}

// https://github.com/ireader/media-server/blob/master/librtp/payload/rtp-h265-unpack.c

#define FU_START(v) (v & 0x80)
#define FU_END(v)	(v & 0x40)
#define FU_NAL(v)	(v & 0x3F)

void RTPDecoder::h265_forward_one_nalu(const uint8_t *data, int data_size,bool write_4_bytes_for_start_code)
{
    timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
    if(flagPacketHasGoneMissing){
        std::cerr<<"Got full NALU - clearing missing packet flag";
        flagPacketHasGoneMissing= false;
    }
    write_h264_h265_nalu_start(write_4_bytes_for_start_code);
    // I do not know what about the 'DONL' field but it seems to be never present
    // copy the NALU header and NALU data, other than h264 here nothing has to be 'reconstructed'
    append_nalu_data(data, data_size);
    forwardNALU(timePointStartOfReceivingNALU,true);
    mNALU_DATA_LENGTH=0;
}

void RTPDecoder::parseRTPH265toNALU(const uint8_t* rtp_data, const size_t data_length){
    // 12 rtp header bytes and 1 nalu_header_t type byte
    if(data_length <= sizeof(rtp_header_t)+sizeof(nal_unit_header_h265_t)){
        std::cerr<<"Not enough rtp data";
        return;
    }
    //MLOGD<<"Got rtp data";
    const RTP::RTPPacketH265 rtpPacket(rtp_data,data_length);
    //MLOGD<<"RTP Header: "<<rtp_header->asString();
    if(!validateRTPPacket(rtpPacket.header)){
        return;
    }
    const auto& nal_unit_header_h265=rtpPacket.getNALUHeaderH265();
    if (nal_unit_header_h265.type > 50){
        std::cerr<<"Unsupported (HEVC) NAL type "<<(int)nal_unit_header_h265.type;
        return;
    }
    if(nal_unit_header_h265.type==48){
        qDebug()<<"Got RTP H265 type 48 (aggregated) payload size:"<<rtpPacket.rtpPayloadSize;
        const uint8_t* rtp_payload=rtpPacket.rtpPayload;
        const auto rtp_payload_size=rtpPacket.rtpPayloadSize;
        int offset=0;
        while(true){
            // the size of the (n-th) nalu starts at offset+1 (1 byte STAP-A NAL HDR )
            // WTF DOND ?!
            const int don_offset=1;
            const uint16_t* nalu_size_network=(const uint16_t*)&rtp_payload[offset+don_offset+1];
            const uint16_t nalu_size= htons(*nalu_size_network);
            // While the NALU HDR of the (n-th) nalu starts at offset+3 (1 byte STAP-A NAL HDR, 2 bytes nalu size)
            const uint8_t* actual_nalu_data_p=&rtp_payload[offset+don_offset+1+2];
            const auto actual_nalu_size=nalu_size;
            qDebug()<<"XNALU of size:"<<(int)actual_nalu_size;
            h265_forward_one_nalu(actual_nalu_data_p,actual_nalu_size);
            offset+=2+actual_nalu_size;
            if(!(rtp_payload_size>offset+3)){
                break;
            }
        }
        return;
    }else if(nal_unit_header_h265.type==49){
        // FU-X packet
        qDebug()<<"Got RTP H265 type 49 (fragmented) payload size:"<<rtpPacket.rtpPayloadSize;
        const auto& fu_header=rtpPacket.getFuHeader();
        const auto fu_payload=rtpPacket.getFuPayload();
        const auto fu_payload_size=rtpPacket.getFuPayloadSize();
        if(fu_header.e){
            //MLOGD<<"end of fu packetization";
            append_nalu_data(fu_payload, fu_payload_size);
            forwardNALU(timePointStartOfReceivingNALU,true);
            mNALU_DATA_LENGTH=0;
        }else if(fu_header.s){
            //MLOGD<<"start of fu packetization";
            //MLOGD<<"Bytes "<<StringHelper::vectorAsString(std::vector<uint8_t>(rtp_data,rtp_data+data_length));
            timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
            if(flagPacketHasGoneMissing){
                std::cerr<<"Got fu-a start - clearing missing packet flag";
                flagPacketHasGoneMissing=false;
            }
            write_h264_h265_nalu_start(false);
            // copy header and reconstruct ?!!!
            const uint8_t* ptr=&rtp_data[sizeof(rtp_header_t)];
            uint8_t variableNoIdea=rtp_data[sizeof(rtp_header_t) + sizeof(nal_unit_header_h265_t)];
            // replace NAL Unit Type Bits - I have no idea how that works, but this manipulation works :)
            mNALU_DATA[mNALU_DATA_LENGTH] = (FU_NAL(variableNoIdea) << 1) | (ptr[0] & 0x81);
            mNALU_DATA_LENGTH++;
            mNALU_DATA[mNALU_DATA_LENGTH] = ptr[1];
            mNALU_DATA_LENGTH++;
            // copy the rest of the data
            append_nalu_data(fu_payload, fu_payload_size);
        }else{
            //MLOGD<<"middle of fu packetization";
            append_nalu_data(fu_payload, fu_payload_size);
        }
    }else{
        // single NAL unit
        qDebug()<<"Got RTP H265 type any (single) payload size:"<<rtpPacket.rtpPayloadSize;
        h265_forward_one_nalu(rtpPacket.rtpPayload,rtpPacket.rtpPayloadSize,false);
    }
}

void RTPDecoder::forwardNALU(const std::chrono::steady_clock::time_point creationTime,const bool isH265) {
    if(cb!= nullptr){
        cb(mNALU_DATA.data(),mNALU_DATA_LENGTH);
    }
    mNALU_DATA_LENGTH=0;
}


void RTPDecoder::append_nalu_data(const uint8_t *data, size_t data_len) {
    memcpy(&mNALU_DATA[mNALU_DATA_LENGTH],data,data_len);
    mNALU_DATA_LENGTH+=data_len;
}

void RTPDecoder::write_h264_h265_nalu_start(const bool use_4_bytes)
{
    if(use_4_bytes){
        mNALU_DATA[0]=0;
        mNALU_DATA[1]=0;
        mNALU_DATA[2]=0;
        mNALU_DATA[3]=1;
        mNALU_DATA_LENGTH=4;
    }else{
        mNALU_DATA[0]=0;
        mNALU_DATA[1]=0;
        mNALU_DATA[2]=1;
        mNALU_DATA_LENGTH=3;
    }
}

