/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h265_rtp_ap_parser.h"
#include "h265_rtp_fu_parser.h"
#include "h265_rtp_single_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out an RTP NAL Unit data.
class H265RtpParser {
 public:
  // The parsed state of the RTP NAL Unit.
  struct RtpState {
    RtpState() = default;
    ~RtpState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    RtpState(const RtpState&) = delete;
    RtpState(RtpState&&) = delete;
    RtpState& operator=(const RtpState&) = delete;
    RtpState& operator=(RtpState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    std::unique_ptr<struct H265NalUnitHeaderParser::NalUnitHeaderState>
        nal_unit_header;
    std::unique_ptr<struct H265RtpSingleParser::RtpSingleState> rtp_single;
    std::unique_ptr<struct H265RtpApParser::RtpApState> rtp_ap;
    std::unique_ptr<struct H265RtpFuParser::RtpFuState> rtp_fu;
  };

  // Unpack RBSP and parse RTP NAL Unit state from the supplied buffer.
  static std::unique_ptr<RtpState> ParseRtp(
      const uint8_t* data, size_t length,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpState> ParseRtp(
      rtc::BitBuffer* bit_buffer,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
