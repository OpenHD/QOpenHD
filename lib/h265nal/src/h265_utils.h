/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_bitstream_parser_state.h"
#ifdef RTP_DEFINE
#include "h265_rtp_parser.h"
#endif  // RTP_DEFINE

namespace h265nal {

// A class for unclassified utilities.
class H265Utils {
 public:
  // Get the slice QP for the Y component (Equation 7-54)
#ifdef RTP_DEFINE
  static std::unique_ptr<int32_t> GetSliceQpY(
      std::unique_ptr<struct H265RtpParser::RtpState> const& rtp,
      const H265BitstreamParserState* bitstream_parser_state) noexcept;
#endif  // RTP_DEFINE
  static std::vector<int32_t> GetSliceQpY(
      const uint8_t* data, size_t length,
      H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
