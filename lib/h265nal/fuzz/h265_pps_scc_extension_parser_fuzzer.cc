/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_pps_scc_extension_parser_unittest.cc.
// Do not edit directly.

#include "h265_pps_scc_extension_parser.h"
#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  auto pps_scc_extension = h265nal::H265PpsSccExtensionParser::ParsePpsSccExtension(
      data, size);
  }
  return 0;
}
