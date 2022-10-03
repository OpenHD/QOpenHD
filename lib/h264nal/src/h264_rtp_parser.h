/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_rtp_fua_parser.h"
#include "h264_rtp_single_parser.h"
#include "h264_rtp_stapa_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an RTP NAL Unit data.
class H264RtpParser {
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

    std::unique_ptr<struct H264NalUnitHeaderParser::NalUnitHeaderState>
        nal_unit_header;
    std::unique_ptr<struct H264RtpSingleParser::RtpSingleState> rtp_single;
    std::unique_ptr<struct H264RtpStapAParser::RtpStapAState> rtp_stapa;
    std::unique_ptr<struct H264RtpFuAParser::RtpFuAState> rtp_fua;
  };

  // Unpack RBSP and parse RTP NAL Unit state from the supplied buffer.
  static std::unique_ptr<RtpState> ParseRtp(
      const uint8_t* data, size_t length,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpState> ParseRtp(
      rtc::BitBuffer* bit_buffer,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
