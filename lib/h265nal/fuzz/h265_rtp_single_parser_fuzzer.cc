/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_rtp_single_parser_unittest.cc.
// Do not edit directly.

#include "h265_rtp_single_parser.h"
#include <vector>
#include "h265_common.h"
#include "h265_utils.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  h265nal::H265BitstreamParserState bitstream_parser_state;
  auto rtp_single = h265nal::H265RtpSingleParser::ParseRtpSingle(
      data, size, &bitstream_parser_state);
  }
  return 0;
}
