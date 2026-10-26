#include "videostreaming/nxp/RtpAccessUnit.hpp"
#include <cassert>
#include <cstdio>
using Bytes=std::vector<uint8_t>;
static Bytes packet(uint16_t seq, uint32_t ts, bool marker, Bytes payload, uint32_t source=1) {
    Bytes p={0x80,uint8_t(96|(marker?128:0)),uint8_t(seq>>8),uint8_t(seq),
             uint8_t(ts>>24),uint8_t(ts>>16),uint8_t(ts>>8),uint8_t(ts),
             uint8_t(source>>24),uint8_t(source>>16),uint8_t(source>>8),uint8_t(source)};
    p.insert(p.end(),payload.begin(),payload.end()); return p;
}
int main() {
    for(bool hevc: {false,true}) {
        std::vector<Bytes> out;
        nxp::RtpAccessUnit r(hevc,[&](Bytes bytes,bool){out.push_back(std::move(bytes));});
        auto send=[&](uint16_t seq,uint32_t ts,bool mark,Bytes bytes,uint32_t source=1) {
            auto p=packet(seq,ts,mark,std::move(bytes),source); r.push(p.data(),p.size());
        };
        Bytes key=hevc?Bytes{38,1,0x80,0x44}:Bytes{0x65,0x80,0x44};
        Bytes delta=hevc?Bytes{2,1,0x80,0x55}:Bytes{0x41,0x80,0x55};
        send(65534,1,true,delta); assert(out.empty());
        send(65535,2,true,key); assert(out.size()==1);
        send(0,3,true,delta); assert(out.size()==2); // sequence wrap
        send(0,3,true,delta); assert(out.size()==2); // duplicate
        send(2,4,true,delta); assert(out.size()==2); // missing packet
        send(3,5,true,delta); assert(out.size()==2); // no stale references
        send(4,6,true,key); assert(out.size()==3);
        // Reassemble fragmented keyframe, including multi-slice access unit.
        Bytes start=hevc?Bytes{98,1,uint8_t(128|19),0x80}:Bytes{0x7c,0x85,0x80};
        Bytes end=hevc?Bytes{98,1,uint8_t(64|19),0x44}:Bytes{0x7c,0x45,0x44};
        send(5,7,false,start); assert(out.size()==3);
        send(6,7,false,end); assert(out.size()==3);
        send(7,7,true,delta); assert(out.size()==4);
        // An unfinished FU at marker never reaches the VPU.
        send(8,8,true,start); assert(out.size()==4);
        send(9,9,true,delta); assert(out.size()==4);
        send(10,10,true,key); assert(out.size()==5);
        // Source restart can use a completely different sequence number.
        send(1,1,true,key,2); assert(out.size()==6);
        // Malformed aggregation and extension must not read beyond packet.
        send(2,2,true,hevc?Bytes{96,1,0xff,0xff,38}:Bytes{24,0xff,0xff,0x65},2);
        assert(out.size()==6);
        Bytes malformed={0x90,0xe0,0,3,0,0,0,3,0,0,0,2,0,0,0xff,0xff};
        r.push(malformed.data(),malformed.size()); assert(out.size()==6);
        // A new clean IDR always recovers after malformed input.
        send(3,3,true,key,2); assert(out.size()==7);
        // OpenHD reuses SSRC 0 across process restarts. A quiet stream must
        // reacquire even if the sequence number has moved backwards.
        auto restart=packet(0,0,true,key,2);
        r.push(restart.data(),restart.size(),nxp::RtpAccessUnit::Clock::now()+std::chrono::seconds(1));
        assert(out.size()==8);
    }
    puts("NXP RTP tests passed: H264/H265, loss, wrap, FU, multislice, restart, malformed input");
}
