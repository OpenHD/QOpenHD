/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_bitstream_parser_unittest.cc.
// Do not edit directly.

#include "h265_bitstream_parser.h"
#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_utils.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  // init the BitstreamParserState
  h265nal::H265BitstreamParserState bitstream_parser_state;
  auto bitstream = h265nal::H265BitstreamParser::ParseBitstream(
      data, size, &bitstream_parser_state,
      /* add_checksum */ true);
  }
  return 0;
}
