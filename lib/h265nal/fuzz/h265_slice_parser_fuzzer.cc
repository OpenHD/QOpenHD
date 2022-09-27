/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h265_slice_parser_unittest.cc.
// Do not edit directly.

#include "h265_slice_parser.h"
#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_nal_unit_parser.h"
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
  bitstream_parser_state.pps[0] = pps;
  auto slice_segment_layer =
      h265nal::H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
          data, size, h265nal::NalUnitType::IDR_W_RADL,
          &bitstream_parser_state);
  }
  return 0;
}
