/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_sub_layer_hrd_parameters_parser_unittest.cc.
// Do not edit directly.

#include "h265_sub_layer_hrd_parameters_parser.h"
#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t subLayerId = 0;
  uint32_t CpbCnt = 1;
  uint32_t sub_pic_hrd_params_present_flag = 0;
  auto sub_layer_hrd_parameters =
      h265nal::H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
          data, size, subLayerId, CpbCnt,
          sub_pic_hrd_params_present_flag);
  }
  return 0;
}
