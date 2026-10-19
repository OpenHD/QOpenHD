#pragma once

extern "C" {
#include <libavcodec/avcodec.h>
}
#include <algorithm>
#include <functional>
#include <vector>

// The RTP receiver produces NALs; avcodec_send_packet expects whole pictures.
// Let FFmpeg recognize H.264/HEVC picture boundaries, including sliced pictures.
class NalAccessUnitParser {
public:
    explicit NalAccessUnitParser(AVCodecID codec) : parser_(av_parser_init(codec)) {}
    ~NalAccessUnitParser() { if (parser_) av_parser_close(parser_); }
    NalAccessUnitParser(const NalAccessUnitParser&) = delete;
    NalAccessUnitParser& operator=(const NalAccessUnitParser&) = delete;
    bool valid() const { return parser_ != nullptr; }
    using Callback = std::function<void(const uint8_t*, int, int64_t)>;
    bool feed(AVCodecContext* context, const uint8_t* data, size_t size,
              int64_t pts, const Callback& callback) {
        if (!parser_) return false;
        input_.resize(size + AV_INPUT_BUFFER_PADDING_SIZE);
        if (size) std::copy(data, data + size, input_.begin());
        std::fill(input_.begin() + size, input_.end(), 0);
        const uint8_t* current = size ? input_.data() : nullptr;
        int remaining = static_cast<int>(size);
        do {
            uint8_t* output = nullptr;
            int output_size = 0;
            const int consumed = av_parser_parse2(parser_, context, &output,
                &output_size, current, remaining, pts, pts, AV_NOPTS_VALUE);
            if (consumed < 0) return false;
            if (output_size) callback(output, output_size, parser_->pts);
            if (!remaining || (!consumed && !output_size)) break;
            current += consumed;
            remaining -= consumed;
        } while (remaining > 0);
        return true;
    }
private:
    AVCodecParserContext* parser_;
    std::vector<uint8_t> input_;
};
