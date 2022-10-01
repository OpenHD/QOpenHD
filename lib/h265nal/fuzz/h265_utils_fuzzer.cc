/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_utils_unittest.cc.
// Do not edit directly.

#include "h265_utils.h"
#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_pps_parser.h"
#include "h265_sps_parser.h"
#include "h265_vps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  // get some mock state
  h265nal::H265BitstreamParserState bitstream_parser_state;
  auto vps = std::make_shared<h265nal::H265VpsParser::VpsState>();
  bitstream_parser_state.vps[0] = vps;
  auto sps = std::make_shared<h265nal::H265SpsParser::SpsState>();
  sps->sample_adaptive_offset_enabled_flag = 1;
  sps->chroma_format_idc = 1;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<h265nal::H265PpsParser::PpsState>();
  pps->init_qp_minus26 = 0;
  bitstream_parser_state.pps[0] = pps;
  // parse buffer
  std::vector<int32_t> slice_qp_y_vector;
  slice_qp_y_vector = h265nal::H265Utils::GetSliceQpY(data, size,
                                             &bitstream_parser_state);
  }
  return 0;
}
