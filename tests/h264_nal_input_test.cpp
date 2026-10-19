#include "../app/videostreaming/avcodec/nal_access_unit_parser.hpp"

#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <vector>

int main(int argc, char** argv) {
    if (argc < 2) return 2;
    av_log_set_level(AV_LOG_QUIET);
    std::ifstream input(argv[1], std::ios::binary);
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(input)), {});
    std::vector<size_t> starts;
    for (size_t i = 0; i + 3 < bytes.size(); ++i) {
        if (!bytes[i] && !bytes[i+1] && bytes[i+2] == 1) {
            starts.push_back(i); i += 2;
        } else if (!bytes[i] && !bytes[i+1] && !bytes[i+2] && bytes[i+3] == 1) {
            starts.push_back(i); i += 3;
        }
    }
    starts.push_back(bytes.size());
    auto* context = avcodec_alloc_context3(avcodec_find_decoder(AV_CODEC_ID_H264));
    if (!context) return 2;
    context->thread_count = 1;
    context->flags |= AV_CODEC_FLAG_LOW_DELAY | AV_CODEC_FLAG_OUTPUT_CORRUPT;
    context->flags2 |= AV_CODEC_FLAG2_SHOW_ALL;
    if (avcodec_open2(context, context->codec, nullptr) < 0) return 2;
    auto* frame = av_frame_alloc();
    int decoded = 0, corrupt = 0, errors = 0, slices = 0;
    auto drain = [&] {
        while (avcodec_receive_frame(context, frame) == 0) {
            ++decoded;
            if (frame->decode_error_flags || (frame->flags & AV_FRAME_FLAG_CORRUPT)) ++corrupt;
            av_frame_unref(frame);
        }
    };
    std::vector<uint8_t> config;
    auto send = [&](const uint8_t* data, size_t size, bool picture) {
        auto* packet = av_packet_alloc();
        av_new_packet(packet, static_cast<int>(size));
        std::memcpy(packet->data, data, size);
        if (avcodec_send_packet(context, packet) < 0 && picture) ++errors;
        drain(); av_packet_free(&packet);
    };
    NalAccessUnitParser parser(AV_CODEC_ID_H264);
    auto feed = [&](const uint8_t* data, size_t size, bool picture) {
        if (argc > 2) { send(data, size, picture); return; }
        parser.feed(context, data, size, AV_NOPTS_VALUE,
                    [&](const uint8_t* frame, int length, int64_t) {
            send(frame, length, true);
        });
    };
    bool configured = false;
    for (size_t i = 0; i + 1 < starts.size(); ++i) {
        const auto begin = starts[i], end = starts[i+1];
        const size_t prefix = bytes[begin+2] == 1 ? 3 : 4;
        if (end <= begin + prefix) continue;
        const int type = bytes[begin+prefix] & 31;
        if (type == 7 || type == 8) {
            config.insert(config.end(), bytes.begin()+begin, bytes.begin()+end);
        } else if (type == 1 || type == 5) {
            if (!configured) { feed(config.data(), config.size(), false); configured = true; }
            ++slices;
            feed(bytes.data()+begin, end-begin, true);
        }
    }
    if (argc == 2) feed(nullptr, 0, true);
    avcodec_send_packet(context, nullptr); drain();
    av_frame_free(&frame); avcodec_free_context(&context);
    std::cout << "slices=" << slices << " decoded=" << decoded
              << " corrupt=" << corrupt << " send_errors=" << errors << '\n';
    return slices > 30 && decoded == 30 && corrupt == 0 && errors == 0 ? 0 : 1;
}
