/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h265_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out an RTP FU (Fragmentation Units) data.
class H265RtpFuParser {
 public:
  // The parsed state of the RTP FU.
  struct RtpFuState {
    RtpFuState() = default;
    ~RtpFuState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    RtpFuState(const RtpFuState&) = delete;
    RtpFuState(RtpFuState&&) = delete;
    RtpFuState& operator=(const RtpFuState&) = delete;
    RtpFuState& operator=(RtpFuState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // common header
    std::unique_ptr<struct H265NalUnitHeaderParser::NalUnitHeaderState> header;

    // fu header
    uint32_t s_bit;
    uint32_t e_bit;
    uint32_t fu_type;

    // optional payload
    std::unique_ptr<struct H265NalUnitPayloadParser::NalUnitPayloadState>
        nal_unit_payload;
  };

  // Unpack RBSP and parse RTP FU state from the supplied buffer.
  static std::unique_ptr<RtpFuState> ParseRtpFu(
      const uint8_t* data, size_t length,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpFuState> ParseRtpFu(
      rtc::BitBuffer* bit_buffer,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
