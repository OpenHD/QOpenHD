/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_st_ref_pic_set_parser_unittest.cc.
// Do not edit directly.

#include "h265_st_ref_pic_set_parser.h"
#include "h265_common.h"
#include "h265_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  auto sps = std::make_shared<h265nal::H265SpsParser::SpsState>();
  sps->num_short_term_ref_pic_sets = 0;
  uint32_t max_num_pics = 1;
  auto st_ref_pic_set = h265nal::H265StRefPicSetParser::ParseStRefPicSet(
      data, size, 0, 1, &(sps->st_ref_pic_set), max_num_pics);
  }
  return 0;
}
