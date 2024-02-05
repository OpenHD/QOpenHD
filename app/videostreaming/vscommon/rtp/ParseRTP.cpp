//
// Created by Constantin on 2/6/2019.
//

#include "ParseRTP.h"
#include <cstring>
#include <iostream>
#include <qdebug.h>

#define MLOGD qDebug()

static int diff_between_packets(int last_packet,int curr_packet){
    if(last_packet==curr_packet){
        MLOGD<<"Duplicate?!";
    }
    if(curr_packet<last_packet){
        // This is not neccessarily an error, the rtp seq nr is of type uint16_t and therefore loops around in regular intervals
        //MLOGD<<"Assuming overflow";
        // We probably have overflown the uin16_t range of rtp
        const auto diff=curr_packet+UINT16_MAX+1-last_packet;
        //MLOGD<<"last:"<<last_packet<<" curr:"<<curr_packet<<" diff:"<<diff;
        return diff;
    }else{
        return curr_packet-last_packet;
    }
}


RTPDecoder::RTPDecoder(RTP_FRAME_DATA_CALLBACK cb,bool feed_incomplete_frames): m_cb(std::move(cb)),m_feed_incomplete_frames(feed_incomplete_frames){
}

void RTPDecoder::reset(){
    m_nalu_data_length=0;
    lastSequenceNumber=-1;
    flagPacketHasGoneMissing=false;
    m_n_gaps=0;
    //nalu_data.reserve(NALU::NALU_MAXLEN);
}

bool RTPDecoder::validateRTPPacket(const rtp_header_t& rtp_header) {
    if(rtp_header.payload!=RTP_PAYLOAD_TYPE_GENERIC){
        if(std::chrono::steady_clock::now()-m_last_log_wrong_rtp_payload_time>std::chrono::seconds(3)){
            // For some reason uvgRtp uses 106 for h264
            // accept it anways, some rtp impl are a bit weird in this regard. Limit logging to not flood the log completely
            MLOGD<<"Unsupported payload type "<<(int)rtp_header.payload;
            m_last_log_wrong_rtp_payload_time=std::chrono::steady_clock::now();
        }
        //return false;
    }
    // Testing regarding sequence numbers.This stuff can be removed without issues
    const int seqNr=rtp_header.getSequence();
    //MLOGD<<"Sequence:"<<seqNr<<" gaps:"<<m_n_gaps;
    if(seqNr==lastSequenceNumber){
        // duplicate. This should never happen for 'normal' rtp streams, but can be usefully when testing bitrates
        // (Since you can send the same packet multiple times to emulate a higher bitrate)
        MLOGD<<"Same seqNr";
        return false;
    }
    if(lastSequenceNumber==-1){
        // first packet in stream
        flagPacketHasGoneMissing=false;
    }else{
        curr_packet_diff=diff_between_packets(lastSequenceNumber,seqNr);
        if(curr_packet_diff!=1){
            //MLOGD<<"X diff:"<<diff_between_packets(lastSequenceNumber,seqNr);
        }
        // Don't forget that the sequence number loops every UINT16_MAX packets
        //if(seqNr != ((lastSequenceNumber+1) % UINT16_MAX)){
        if(seqNr != ((lastSequenceNumber+1) % (UINT16_MAX+1))){
            // We are missing a Packet !
            //MLOGD<<"missing a packet. Last:"<<lastSequenceNumber<<" Curr:"<<seqNr<<" Diff:"<<(seqNr-(int)lastSequenceNumber)<<" total:"<<m_n_gaps;
            flagPacketHasGoneMissing=true;
            m_n_gaps++;
            const auto gap_size=seqNr-(int)lastSequenceNumber;
            m_n_lost_packets+=gap_size;
            // Feed it anyways (buggy / hacky)
            if(m_feed_incomplete_frames){
                MLOGD<<"Ignoring missing packet flag";
                flagPacketHasGoneMissing=false;
            }
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
        //MLOGD<<"Got full NALU - clearing missing packet flag";
        flagPacketHasGoneMissing= false;
    }
    write_h264_h265_nalu_start();
    const uint8_t h264_nal_header = (uint8_t )(nalu_header.type & 0x1f)
                                    | (nalu_header.nri << 5)
                                    | (nalu_header.f << 7);
    // write the reconstructed NAL header (the h264 "type")
    append_nalu_data_byte(h264_nal_header);
    // write the rest of the data
    append_nalu_data(&data[1], (size_t)data_size - 1);
    // forward via callback
    forwardNALU();
    // reset length after forwarding
    m_nalu_data_length=0;
}

void RTPDecoder::parseRTPH264toNALU(const uint8_t* rtp_data, const size_t data_length){
    //12 rtp header bytes and 1 nalu_header_t type byte
    if(data_length <= sizeof(rtp_header_t)+sizeof(nalu_header_t)){
        MLOGD<<"Not enough rtp data";
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
        //MLOGD<<"Got RTP H264 type 28 (fragmented) payload size:"<<rtpPacket.rtpPayloadSize;
        const auto& fu_header=rtpPacket.getFuHeader();
        const auto fu_payload=rtpPacket.getFuPayload();
        const auto fu_payload_size=rtpPacket.getFuPayloadSize();
        if (fu_header.e == 1) {
            //MLOGD<<"End of fu-a";
            // end of fu-a
            append_nalu_data(fu_payload, fu_payload_size);
            if(!flagPacketHasGoneMissing){
                // To better measure latency we can actually use the timestamp from when the first bytes for this packet were received
                forwardNALU();
            }
            m_total_n_fragments_for_current_fu++;
            //MLOGD<<"N fragments for this fu:"<<m_total_n_fragments_for_current_fu;
            m_total_n_fragments_for_current_fu=0;
            m_nalu_data_length=0;
        } else if (fu_header.s == 1) {
            //MLOGD<<"Start of fu-a";
            timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
            m_total_n_fragments_for_current_fu=0;
            // Beginning of new fu sequence - we can remove the 'drop packet' flag
            if(flagPacketHasGoneMissing){
                //MLOGD<<"Got fu-a start - clearing missing packet flag";
                flagPacketHasGoneMissing=false;
            }
            // start of fu-a
            write_h264_h265_nalu_start();
            const uint8_t h264_nal_header = (uint8_t)(fu_header.type & 0x1f)
                                            | (nalu_header.nri << 5)
                                            | (nalu_header.f << 7);
            append_nalu_data_byte(h264_nal_header);
            append_nalu_data(fu_payload, fu_payload_size);
        } else {
            //MLOGD<<"Middle of fu-a";
            // middle of fu-a
            // experiment
            /*if(curr_packet_diff>1){
                MLOGD<<"Doing werid things";
                //m_nalu_data_length+=(curr_packet_diff-1)*1024;
                append_empty((curr_packet_diff-1)*1024);
            }*/
            append_nalu_data(fu_payload, fu_payload_size);
            m_total_n_fragments_for_current_fu++;
        }
    } else if(nalu_header.type>0 && nalu_header.type<24){
        //MLOGD<<"Got RTP H264 type [1..23] (single) payload size:"<<rtpPacket.rtpPayloadSize;
        h264_reconstruct_and_forward_one_nalu(rtpPacket.rtpPayload,rtpPacket.rtpPayloadSize);
    }else if(nalu_header.type==24){
       //MLOGD<<"Got RTP H264 type 24 (aggregated NALUs) payload size:"<<rtpPacket.rtpPayloadSize;
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
            //MLOGD<<"XNALU of size:"<<(int)actual_nalu_size;
            h264_reconstruct_and_forward_one_nalu(actual_nalu_data_p,actual_nalu_size);
            offset+=2+actual_nalu_size;
            if(!(rtp_payload_size>offset+3)){
                break;
            }
        }
    }else{
        MLOGD<<"Got unsupported H264 RTP packet. NALU type:"<<(int)nalu_header.type;
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
        //MLOGD<<"Got full NALU - clearing missing packet flag";
        flagPacketHasGoneMissing= false;
    }
    write_h264_h265_nalu_start(write_4_bytes_for_start_code);
    // I do not know what about the 'DONL' field but it seems to be never present
    // copy the NALU header and NALU data, other than h264 here nothing has to be 'reconstructed'
    append_nalu_data(data, data_size);
    forwardNALU(true);
    m_nalu_data_length=0;
}

void RTPDecoder::parseRTPH265toNALU(const uint8_t* rtp_data, const size_t data_length){
    // 12 rtp header bytes and 1 nalu_header_t type byte
    if(data_length <= sizeof(rtp_header_t)+sizeof(nal_unit_header_h265_t)){
        MLOGD<<"Not enough rtp data";
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
        MLOGD<<"Unsupported (HEVC) NAL type "<<(int)nal_unit_header_h265.type;
        return;
    }
    if(nal_unit_header_h265.type==48){
        //MLOGD<<"Got RTP H265 type 48 (aggregated) payload size:"<<rtpPacket.rtpPayloadSize;
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
            //MLOGD<<"XNALU of size:"<<(int)actual_nalu_size;
            h265_forward_one_nalu(actual_nalu_data_p,actual_nalu_size);
            offset+=2+actual_nalu_size;
            if(!(rtp_payload_size>offset+3)){
                break;
            }
        }
        return;
    }else if(nal_unit_header_h265.type==49){
        // FU-X packet
        //MLOGD<<"Got RTP H265 type 49 (fragmented) payload size:"<<rtpPacket.rtpPayloadSize;
        const auto& fu_header=rtpPacket.getFuHeader();
        const auto fu_payload=rtpPacket.getFuPayload();
        const auto fu_payload_size=rtpPacket.getFuPayloadSize();
        if(fu_header.e){
            //MLOGD<<"end of fu packetization";
            append_nalu_data(fu_payload, fu_payload_size);
            forwardNALU(true);
            m_nalu_data_length=0;
        }else if(fu_header.s){
            //MLOGD<<"start of fu packetization";
            //MLOGD<<"Bytes "<<StringHelper::vectorAsString(std::vector<uint8_t>(rtp_data,rtp_data+data_length));
            timePointStartOfReceivingNALU=std::chrono::steady_clock::now();
            if(flagPacketHasGoneMissing){
                MLOGD<<"Got fu-a start - clearing missing packet flag";
                flagPacketHasGoneMissing=false;
            }
            write_h264_h265_nalu_start();
            // copy header and reconstruct ?!!!
            const uint8_t* ptr=&rtp_data[sizeof(rtp_header_t)];
            uint8_t variableNoIdea=rtp_data[sizeof(rtp_header_t) + sizeof(nal_unit_header_h265_t)];
            // replace NAL Unit Type Bits - I have no idea how that works, but this manipulation works :)
            const uint8_t tmp_unknown = (FU_NAL(variableNoIdea) << 1) | (ptr[0] & 0x81);
            append_nalu_data_byte(tmp_unknown);
            append_nalu_data_byte(ptr[1]);
            // copy the rest of the data
            append_nalu_data(fu_payload, fu_payload_size);
        }else{
            //MLOGD<<"middle of fu packetization";
            append_nalu_data(fu_payload, fu_payload_size);
        }
    }else{
        // single NAL unit
        //MLOGD<<"Got RTP H265 type any (single) payload size:"<<rtpPacket.rtpPayloadSize;
        //h265_forward_one_nalu(rtpPacket.rtpPayload,rtpPacket.rtpPayloadSize,false);
        h265_forward_one_nalu(rtpPacket.rtpPayload,rtpPacket.rtpPayloadSize,true);
    }
}

// MJPEG
void RTPDecoder::parse_rtp_mjpeg(const uint8_t *rtp_data, const size_t data_length)
{
    // 12 rtp header bytes and 8 main header bytes
    if(data_length <= sizeof(rtp_header_t)+8){
        MLOGD<<"Not enough rtp mjpeg data";
        return;
    }
    //MLOGD<<"Got rtp mjpeg data";
    const RTP::RTPPacket rtpPacket(rtp_data,data_length);
    const jpeg_main_header_t& jpeg_main_header=*(jpeg_main_header_t*)rtpPacket.rtpPayload;
    //MLOGD<<"X:"<<jpeg_main_header.type;
}

void RTPDecoder::forwardNALU(const bool isH265) {
    if(m_cb!= nullptr){
        // if either the rtp encoder is buggy or the premise of increasing sequence numbers is not given, this
        // callback might be called with grabage data. Try and catch that as early as possible.
        if(!check_curr_nalu_has_valid_prefix(true)){
            return;
        }
        uint8_t* p=&m_curr_nalu.at(0);
        m_cb(timePointStartOfReceivingNALU,p,m_nalu_data_length);
    }
    m_nalu_data_length=0;
}

void RTPDecoder::append_nalu_data(const uint8_t *data, size_t data_len) {
    if(m_nalu_data_length+data_len>m_curr_nalu.size()){
        MLOGD<<"Weird - not enugh space to write NALU. curr_size:"<<m_nalu_data_length<<" append:"<<data_len;
        return;
    }
    uint8_t* p=&m_curr_nalu.at(m_nalu_data_length);
    memcpy(p,data,data_len);
    m_nalu_data_length+=data_len;
}

void RTPDecoder::append_nalu_data_byte(uint8_t byte)
{
    append_nalu_data(&byte,1);
}

void RTPDecoder::append_empty(size_t data_len)
{
    if(m_nalu_data_length+data_len>m_curr_nalu.size()){
        MLOGD<<"Weird - not enugh space to write NALU. curr_size:"<<m_nalu_data_length<<" append:"<<data_len;
        return;
    }
    uint8_t* p=&m_curr_nalu.at(m_nalu_data_length);
    std::memset(p,0,data_len);
    m_nalu_data_length+=data_len;
}

void RTPDecoder::write_h264_h265_nalu_start(const bool use_4_bytes)
{
    //m_curr_nalu=std::make_shared<std::array<uint8_t,NALU_MAXLEN>>();
    m_nalu_data_length=0;
    if(use_4_bytes){
        append_nalu_data_byte(0);
        append_nalu_data_byte(0);
        append_nalu_data_byte(0);
        append_nalu_data_byte(1);
        assert(m_nalu_data_length==4);
    }else{
        append_nalu_data_byte(0);
        append_nalu_data_byte(0);
        append_nalu_data_byte(1);
        assert(m_nalu_data_length==3);
    }
}

bool RTPDecoder::check_has_valid_prefix(const uint8_t *nalu_data, int nalu_data_len, bool use_4_bytes_start_code)
{
    if(nalu_data_len<5){
        MLOGD<<"Not a valid nalu - less than 5 bytes";
        return false;
    }
    if(use_4_bytes_start_code){
        const bool valid= nalu_data[0]==0 &&
        nalu_data[1]==0 &&
        nalu_data[2]==0 &&
        nalu_data[3]==1;
        if(!valid){
            MLOGD<<"Not a valid nalu - missing start code (4 bytes)";
        }
        return valid;
    }else{
        const bool valid= nalu_data[0]==0 &&
        nalu_data[1]==0 &&
        nalu_data[2]==1;
        if(!valid){
            MLOGD<<"Not a valid nalu - missing start code (3 bytes)";
        }
        return valid;
    }
}

bool RTPDecoder::check_curr_nalu_has_valid_prefix(bool use_4_bytes_start_code)
{
    uint8_t* p=&m_curr_nalu.at(0);
    return check_has_valid_prefix(p,m_nalu_data_length,use_4_bytes_start_code);
}



