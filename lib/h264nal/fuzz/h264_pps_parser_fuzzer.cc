/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_pps_parser_unittest.cc.
// Do not edit directly.

#include "h264_pps_parser.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t chroma_format_idc = 1;
  auto pps = h264nal::H264PpsParser::ParsePps(data, size, chroma_format_idc);
  }
  {
  uint32_t chroma_format_idc = 1;
  auto pps = h264nal::H264PpsParser::ParsePps(data, size, chroma_format_idc);
  }
  return 0;
}
