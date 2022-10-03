/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_prefix_nal_unit_parser_unittest.cc.
// Do not edit directly.

#include "h264_prefix_nal_unit_parser.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t svc_extension_flag = 1;
  uint32_t nal_ref_idc = 2;
  uint32_t use_ref_base_pic_flag = 1;
  uint32_t idr_flag = 1;
  auto prefix_nal_unit_rbsp =
      h264nal::H264PrefixNalUnitRbspParser::ParsePrefixNalUnitRbsp(
          data, size, svc_extension_flag, nal_ref_idc,
          use_ref_base_pic_flag, idr_flag);
  }
  return 0;
}
