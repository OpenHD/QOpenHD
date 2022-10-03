/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an RTP STAP-A (Aggregated Packet) data.
class H264RtpStapAParser {
 public:
  // The parsed state of the RTP STAP-A.
  struct RtpStapAState {
    RtpStapAState() = default;
    ~RtpStapAState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    RtpStapAState(const RtpStapAState&) = delete;
    RtpStapAState(RtpStapAState&&) = delete;
    RtpStapAState& operator=(const RtpStapAState&) = delete;
    RtpStapAState& operator=(RtpStapAState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // common header
    std::unique_ptr<struct H264NalUnitHeaderParser::NalUnitHeaderState> header;

    // payload
    std::vector<size_t> nal_unit_sizes;
    std::vector<
        std::unique_ptr<struct H264NalUnitHeaderParser::NalUnitHeaderState>>
        nal_unit_headers;
    std::vector<
        std::unique_ptr<struct H264NalUnitPayloadParser::NalUnitPayloadState>>
        nal_unit_payloads;
  };

  // Unpack RBSP and parse RTP AP state from the supplied buffer.
  static std::unique_ptr<RtpStapAState> ParseRtpStapA(
      const uint8_t* data, size_t length,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpStapAState> ParseRtpStapA(
      rtc::BitBuffer* bit_buffer,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
