/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_profile_tier_level_parser_unittest.cc.
// Do not edit directly.

#include "h265_profile_tier_level_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  auto ptls = h265nal::H265ProfileTierLevelParser::ParseProfileTierLevel(
      data, size, true, 0);
  }
  {
  auto ptls = h265nal::H265ProfileTierLevelParser::ParseProfileTierLevel(
      data, size, true, 0);
  }
  return 0;
}
