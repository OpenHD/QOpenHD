/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out an RTP AP (Aggregated Packet) data.
class H265RtpApParser {
 public:
  // The parsed state of the RTP AP.
  struct RtpApState {
    RtpApState() = default;
    ~RtpApState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    RtpApState(const RtpApState&) = delete;
    RtpApState(RtpApState&&) = delete;
    RtpApState& operator=(const RtpApState&) = delete;
    RtpApState& operator=(RtpApState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // common header
    std::unique_ptr<struct H265NalUnitHeaderParser::NalUnitHeaderState> header;

    // payload
    std::vector<size_t> nal_unit_sizes;
    std::vector<
        std::unique_ptr<struct H265NalUnitHeaderParser::NalUnitHeaderState>>
        nal_unit_headers;
    std::vector<
        std::unique_ptr<struct H265NalUnitPayloadParser::NalUnitPayloadState>>
        nal_unit_payloads;
  };

  // Unpack RBSP and parse RTP AP state from the supplied buffer.
  static std::unique_ptr<RtpApState> ParseRtpAp(
      const uint8_t* data, size_t length,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<RtpApState> ParseRtpAp(
      rtc::BitBuffer* bit_buffer,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
