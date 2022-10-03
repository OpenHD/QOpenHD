/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an RTP FU-A (Fragmentation Units) data.
class H264RtpFuAParser {
 public:
  // The parsed state of the RTP FU-A.
  struct RtpFuAState {
    RtpFuAState() = default;
    ~RtpFuAState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    RtpFuAState(const RtpFuAState&) = delete;
    RtpFuAState(RtpFuAState&&) = delete;
    RtpFuAState& operator=(const RtpFuAState&) = delete;
    RtpFuAState& operator=(RtpFuAState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input values
    uint32_t nal_ref_idc;

    // common header
    std::unique_ptr<struct H264NalUnitHeaderParser::NalUnitHeaderState> header;

    // fu-a header
    uint32_t s_bit;
    uint32_t e_bit;
    uint32_t r_bit;
    uint32_t fu_type;

    // optional payload
    std::unique_ptr<struct H264NalUnitPayloadParser::NalUnitPayloadState>
        nal_unit_payload;
  };

  // Unpack RBSP and parse RTP FU-A state from the supplied buffer.
  static std::unique_ptr<RtpFuAState> ParseRtpFuA(
      const uint8_t* data, size_t length, uint32_t nal_ref_idc,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpFuAState> ParseRtpFuA(
      rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
