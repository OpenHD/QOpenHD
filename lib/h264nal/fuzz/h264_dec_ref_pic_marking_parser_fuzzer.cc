/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_dec_ref_pic_marking_parser_unittest.cc.
// Do not edit directly.

#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t nal_unit_type = h264nal::NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT;
  auto dec_ref_pic_marking = h264nal::H264DecRefPicMarkingParser::ParseDecRefPicMarking(
      data, size, nal_unit_type);
  }
  {
  uint32_t nal_unit_type = h264nal::NalUnitType::CODED_SLICE_OF_NON_IDR_PICTURE_NUT;
  auto dec_ref_pic_marking = h264nal::H264DecRefPicMarkingParser::ParseDecRefPicMarking(
      data, size, nal_unit_type);
  }
  return 0;
}
