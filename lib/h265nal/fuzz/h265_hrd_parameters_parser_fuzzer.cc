/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_hrd_parameters_parser_unittest.cc.
// Do not edit directly.

#include "h265_hrd_parameters_parser.h"
#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t commonInfPresentFlag = 1;
  uint32_t maxNumSubLayersMinus1 = 0;
  auto hrd_parameters = h265nal::H265HrdParametersParser::ParseHrdParameters(
      data, size, commonInfPresentFlag, maxNumSubLayersMinus1);
  }
  return 0;
}
