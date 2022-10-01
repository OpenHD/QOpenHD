/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_ref_pic_list_modification_parser_unittest.cc.
// Do not edit directly.

#include "h264_ref_pic_list_modification_parser.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  uint32_t slice_type = h264nal::SliceType::P_ALL;
  auto ref_pic_list_modification =
      h264nal::H264RefPicListModificationParser::ParseRefPicListModification(
          data, size, slice_type);
  }
  return 0;
}
