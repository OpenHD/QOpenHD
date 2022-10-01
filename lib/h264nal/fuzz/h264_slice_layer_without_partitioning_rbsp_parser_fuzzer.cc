/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// h264_slice_layer_without_partitioning_rbsp_parser_unittest.cc.
// Do not edit directly.

#include "h264_slice_layer_without_partitioning_rbsp_parser.h"
#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_pps_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "h264_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"


// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  {
  // get some mock state
  h264nal::H264BitstreamParserState bitstream_parser_state;
  auto sps = std::make_shared<h264nal::H264SpsParser::SpsState>();
  sps->sps_data = std::make_unique<h264nal::H264SpsDataParser::SpsDataState>();
  sps->sps_data->log2_max_frame_num_minus4 = 1;
  sps->sps_data->frame_mbs_only_flag = 1;
  sps->sps_data->pic_order_cnt_type = 2;
  sps->sps_data->delta_pic_order_always_zero_flag = 0;
  sps->sps_data->pic_width_in_mbs_minus1 = 0;
  sps->sps_data->pic_height_in_map_units_minus1 = 0;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<h264nal::H264PpsParser::PpsState>();
  pps->bottom_field_pic_order_in_frame_present_flag = 0;
  pps->redundant_pic_cnt_present_flag = 0;
  pps->weighted_pred_flag = 0;
  pps->weighted_bipred_idc = 0;
  pps->entropy_coding_mode_flag = 0;
  pps->deblocking_filter_control_present_flag = 1;
  pps->num_slice_groups_minus1 = 0;
  pps->slice_group_map_type = 0;
  pps->slice_group_change_rate_minus1 = 0;
  ;
  bitstream_parser_state.pps[0] = pps;
  uint32_t nal_ref_idc = 3;
  uint32_t nal_unit_type = h264nal::NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT;
  auto slice_layer_without_partitioning_rbsp =
      h264nal::H264SliceLayerWithoutPartitioningRbspParser::
          ParseSliceLayerWithoutPartitioningRbsp(data, size,
                                                 nal_ref_idc, nal_unit_type,
                                                 &bitstream_parser_state);
  }
  {
  // get some mock state
  h264nal::H264BitstreamParserState bitstream_parser_state;
  auto sps = std::make_shared<h264nal::H264SpsParser::SpsState>();
  sps->sps_data = std::make_unique<h264nal::H264SpsDataParser::SpsDataState>();
  sps->sps_data->log2_max_frame_num_minus4 = 1;
  sps->sps_data->frame_mbs_only_flag = 1;
  sps->sps_data->pic_order_cnt_type = 2;
  sps->sps_data->delta_pic_order_always_zero_flag = 0;
  sps->sps_data->pic_width_in_mbs_minus1 = 0;
  sps->sps_data->pic_height_in_map_units_minus1 = 0;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<h264nal::H264PpsParser::PpsState>();
  pps->bottom_field_pic_order_in_frame_present_flag = 0;
  pps->redundant_pic_cnt_present_flag = 0;
  pps->weighted_pred_flag = 0;
  pps->weighted_bipred_idc = 0;
  pps->entropy_coding_mode_flag = 0;
  pps->deblocking_filter_control_present_flag = 1;
  pps->num_slice_groups_minus1 = 0;
  pps->slice_group_map_type = 0;
  pps->slice_group_change_rate_minus1 = 0;
  ;
  bitstream_parser_state.pps[0] = pps;
  uint32_t nal_ref_idc = 2;
  uint32_t nal_unit_type = h264nal::NalUnitType::CODED_SLICE_OF_NON_IDR_PICTURE_NUT;
  auto slice_layer_without_partitioning_rbsp =
      h264nal::H264SliceLayerWithoutPartitioningRbspParser::
          ParseSliceLayerWithoutPartitioningRbsp(data, size,
                                                 nal_ref_idc, nal_unit_type,
                                                 &bitstream_parser_state);
  }
  return 0;
}
