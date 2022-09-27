/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_pred_weight_table_parser_unittest.cc.
// Do not edit directly.

#include "h265_pred_weight_table_parser.h"
#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  auto pred_weight_table = h265nal::H265PredWeightTableParser::ParsePredWeightTable(
      data, size, 1, 0);
  }
  {
  auto pred_weight_table = h265nal::H265PredWeightTableParser::ParsePredWeightTable(
      data, size, 1, 2);
  }
  return 0;
}
