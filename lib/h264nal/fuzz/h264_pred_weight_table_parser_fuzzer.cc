/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_pred_weight_table_parser_unittest.cc.
// Do not edit directly.

#include "h264_pred_weight_table_parser.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t chroma_array_type = 1;
  uint32_t slice_type = h264nal::SliceType::P_ALL;
  uint32_t num_ref_idx_l0_active_minus1 = 0;
  uint32_t num_ref_idx_l1_active_minus1 = 0;
  auto pred_weight_table = h264nal::H264PredWeightTableParser::ParsePredWeightTable(
      data, size, chroma_array_type, slice_type,
      num_ref_idx_l0_active_minus1, num_ref_idx_l1_active_minus1);
  }
  {
  uint32_t chroma_array_type = 1;
  uint32_t slice_type = h264nal::SliceType::P_ALL;
  uint32_t num_ref_idx_l0_active_minus1 = 12;
  uint32_t num_ref_idx_l1_active_minus1 = 0;
  auto pred_weight_table = h264nal::H264PredWeightTableParser::ParsePredWeightTable(
      data, size, chroma_array_type, slice_type,
      num_ref_idx_l0_active_minus1, num_ref_idx_l1_active_minus1);
  }
  return 0;
}
