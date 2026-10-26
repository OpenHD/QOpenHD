#include "videostreaming/nxp/HantroDecoder.hpp"
#include "videostreaming/nxp/UdpVideo.hpp"
#include <imxdmabuffer/imxdmabuffer.h>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <thread>
#include <chrono>
#include <stdexcept>

int main(int argc, char** argv) {
    if (argc < 3) { std::fprintf(stderr, "Usage: nxp-decode-probe h264|h265 file [loops]\n       nxp-decode-probe h264|h265 --udp [seconds]\n"); return 2; }
    bool hevc = std::string(argv[1]) == "h265";
    try {
        if (std::string(argv[2]) == "--udp") {
            nxp::UdpVideo receiver(hevc, "0.0.0.0", 5600, [](auto) {});
            std::this_thread::sleep_for(std::chrono::seconds(argc > 3 ? std::atoi(argv[3]) : 10));
            std::printf("UDP decoded=%llu dropped=%llu errors=%llu\n", (unsigned long long)receiver.decoded.load(),
                (unsigned long long)receiver.dropped.load(), (unsigned long long)receiver.errors.load());
            return receiver.decoded > 0 && receiver.errors == 0 ? 0 : 1;
        }
        std::ifstream file(argv[2], std::ios::binary);
        if (!file) throw std::runtime_error("cannot open stream");
        std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(file)), {});
        std::vector<std::vector<uint8_t>> units;
        // Probe accepts AUD-separated streams, or one-slice-per-picture IPPP
        // streams produced by the OpenHD/ORQA test encoder.
        std::vector<uint8_t> au; bool picture = false;
        auto prefix = [&](size_t i) -> size_t {
            if (i+3 <= bytes.size() && bytes[i]==0 && bytes[i+1]==0 && bytes[i+2]==1) return 3;
            if (i+4 <= bytes.size() && bytes[i]==0 && bytes[i+1]==0 && bytes[i+2]==0 && bytes[i+3]==1) return 4;
            return 0;
        };
        for (size_t pos=0; pos<bytes.size();) {
            size_t start=prefix(pos);
            if (!start) { ++pos; continue; }
            size_t end=pos+start;
            while (end<bytes.size() && !prefix(end)) ++end;
            unsigned type=hevc ? ((bytes[pos+start]>>1)&63) : bytes[pos+start]&31;
            bool vcl=hevc ? type<32 : type==1 || type==5;
            bool aud=hevc ? type==35 : type==9;
            bool first=vcl && (hevc ? (pos+start+2<end && (bytes[pos+start+2]&128)) :
                                      (pos+start+1<end && (bytes[pos+start+1]&128)));
            bool config=hevc ? type>=32 && type<=34 : type==7 || type==8;
            if (!au.empty() && (aud || (picture && (first || config)))) {
                units.push_back(std::move(au)); au.clear(); picture=false;
            }
            au.insert(au.end(), bytes.begin()+pos, bytes.begin()+end); picture |= vcl; pos=end;
        }
        if (!au.empty()) units.push_back(std::move(au));
        unsigned loops=argc>3 ? std::max(1, std::atoi(argv[3])) : 1;
        uint64_t frames=0, totalUs=0, maxUs=0;
        uint64_t start=nxp::monotonicUs();
        for (unsigned loop=0; loop<loops; ++loop) {
            auto decoder=std::make_shared<nxp::HantroDecoder>(hevc);
            for (auto& unit: units) {
                auto pushed=nxp::monotonicUs();
                decoder->push(unit, pushed, [&](auto frame) {
                    auto elapsed=nxp::monotonicUs()-frame->raw.pts;
                    totalUs+=elapsed; maxUs=std::max(maxUs, elapsed); ++frames;
                    if (frames==1) {
                        auto& m=frame->info.decoded_frame_framebuffer_metrics;
                        std::printf("First frame: %zux%zu DMA-BUF fd=%d strides=%zu/%zu offsets=%zu/%zu\n",
                            m.actual_frame_width, m.actual_frame_height, frame->dmaFd(),
                            m.y_stride,m.uv_stride,m.y_offset,m.u_offset);
                    }
                });
            }
        }
        auto elapsed=nxp::monotonicUs()-start;
        std::printf("decoded=%llu throughput_fps=%.2f mean_submit_to_decode_us=%.1f max_us=%llu\n",
            (unsigned long long)frames, frames*1000000.0/elapsed, frames ? double(totalUs)/frames : 0,
            (unsigned long long)maxUs);
        return frames ? 0 : 1;
    } catch (const std::exception& error) { std::fprintf(stderr,"probe: %s\n", error.what()); return 1; }
}
