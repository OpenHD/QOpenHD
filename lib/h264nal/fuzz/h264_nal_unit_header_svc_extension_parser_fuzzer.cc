/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_nal_unit_header_svc_extension_parser_unittest.cc.
// Do not edit directly.

#include "h264_nal_unit_header_svc_extension_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  auto nal_unit_header_svc_extension =
      h264nal::H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
          data, size);
  }
  {
  auto nal_unit_header_svc_extension =
      h264nal::H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
          data, size);
  }
  return 0;
}
