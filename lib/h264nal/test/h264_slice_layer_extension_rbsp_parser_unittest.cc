/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_slice_layer_extension_rbsp_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_pps_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "h264_sps_parser.h"
#include "h264_sps_svc_extension_parser.h"
#include "h264_subset_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264SliceLayerExtensionRbspParserTest : public ::testing::Test {
 public:
  H264SliceLayerExtensionRbspParserTest() {}
  ~H264SliceLayerExtensionRbspParserTest() override {}
};

TEST_F(H264SliceLayerExtensionRbspParserTest, TestSampleSlice01) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xb4, 0x04, 0x5f, 0xc0, 0xc4, 0x42, 0x00, 0x04,
      0xe0, 0xcf, 0xc0, 0xf8, 0x00, 0x1a, 0x64, 0x05,
      0x63, 0xfb, 0x13, 0x9f
  };

  // fuzzer::conv: begin
  // get some mock state
  H264BitstreamParserState bitstream_parser_state;

  auto sps = std::make_shared<H264SpsParser::SpsState>();
  sps->sps_data = std::make_unique<H264SpsDataParser::SpsDataState>();
  sps->sps_data->profile_idc = 66;
  sps->sps_data->seq_parameter_set_id = 0;
  sps->sps_data->log2_max_frame_num_minus4 = 1;
  sps->sps_data->frame_mbs_only_flag = 1;
  sps->sps_data->pic_order_cnt_type = 2;
  sps->sps_data->delta_pic_order_always_zero_flag = 0;
  sps->sps_data->pic_width_in_mbs_minus1 = 10;
  sps->sps_data->pic_height_in_map_units_minus1 = 8;
  bitstream_parser_state.sps[0] = sps;

  auto pps = std::make_shared<H264PpsParser::PpsState>();
  pps->pic_parameter_set_id = 0;
  pps->bottom_field_pic_order_in_frame_present_flag = 0;
  pps->redundant_pic_cnt_present_flag = 0;
  pps->weighted_pred_flag = 0;
  pps->weighted_bipred_idc = 0;
  pps->entropy_coding_mode_flag = 0;
  pps->deblocking_filter_control_present_flag = 1;
  pps->num_slice_groups_minus1 = 0;
  pps->slice_group_map_type = 0;
  pps->slice_group_change_rate_minus1 = 0;
  bitstream_parser_state.pps[0] = pps;

  auto pps2 = std::make_shared<H264PpsParser::PpsState>();
  pps2->pic_parameter_set_id = 1;
  pps2->bottom_field_pic_order_in_frame_present_flag = 0;
  pps2->redundant_pic_cnt_present_flag = 0;
  pps2->weighted_pred_flag = 0;
  pps2->weighted_bipred_idc = 0;
  pps2->entropy_coding_mode_flag = 0;
  pps2->deblocking_filter_control_present_flag = 1;
  pps2->num_slice_groups_minus1 = 0;
  pps2->slice_group_map_type = 0;
  pps2->slice_group_change_rate_minus1 = 0;
  bitstream_parser_state.pps[1] = pps2;

  auto subset_sps = std::make_shared<H264SubsetSpsParser::SubsetSpsState>();
  subset_sps->seq_parameter_set_data =
      std::make_unique<H264SpsDataParser::SpsDataState>();
  subset_sps->seq_parameter_set_data->profile_idc = 83;
  subset_sps->seq_parameter_set_data->seq_parameter_set_id = 0;
  subset_sps->seq_parameter_set_data->log2_max_frame_num_minus4 = 1;
  subset_sps->seq_parameter_set_data->frame_mbs_only_flag = 1;
  subset_sps->seq_parameter_set_data->pic_order_cnt_type = 2;
  subset_sps->seq_parameter_set_data->delta_pic_order_always_zero_flag = 0;
  subset_sps->seq_parameter_set_data->pic_width_in_mbs_minus1 = 21;
  subset_sps->seq_parameter_set_data->pic_height_in_map_units_minus1 = 17;
  subset_sps->seq_parameter_set_svc_extension =
      std::make_unique<H264SpsSvcExtensionParser::SpsSvcExtensionState>();
  subset_sps->seq_parameter_set_svc_extension
      ->inter_layer_deblocking_filter_control_present_flag = 1;
  subset_sps->seq_parameter_set_svc_extension->slice_header_restriction_flag =
      1;
  bitstream_parser_state.subset_sps[0] = subset_sps;

  H264NalUnitHeaderParser::NalUnitHeaderState nal_unit_header;
  nal_unit_header.nal_ref_idc = 3;
  nal_unit_header.nal_unit_type = NalUnitType::CODED_SLICE_EXTENSION;
  nal_unit_header.svc_extension_flag = 1;
  nal_unit_header.avc_3d_extension_flag = 0;

  nal_unit_header.nal_unit_header_svc_extension = std::make_unique<
      H264NalUnitHeaderSvcExtensionParser::NalUnitHeaderSvcExtensionState>();
  auto& nal_unit_header_svc_extension =
      nal_unit_header.nal_unit_header_svc_extension;
  nal_unit_header_svc_extension->idr_flag = 1;
  nal_unit_header_svc_extension->priority_id = 0;
  nal_unit_header_svc_extension->no_inter_layer_pred_flag = 1;
  nal_unit_header_svc_extension->dependency_id = 1;
  nal_unit_header_svc_extension->quality_id = 0;
  nal_unit_header_svc_extension->temporal_id = 0;
  nal_unit_header_svc_extension->use_ref_base_pic_flag = 0;
  nal_unit_header_svc_extension->discardable_flag = 1;
  nal_unit_header_svc_extension->output_flag = 1;
  nal_unit_header_svc_extension->reserved_three_2bits = 3;

  auto slice_layer_extension_rbsp =
      H264SliceLayerExtensionRbspParser::ParseSliceLayerExtensionRbsp(
          buffer, arraysize(buffer), nal_unit_header, &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(slice_layer_extension_rbsp != nullptr);

  auto& slice_header_in_scalable_extension =
      slice_layer_extension_rbsp->slice_header_in_scalable_extension;
  ASSERT_TRUE(slice_header_in_scalable_extension != nullptr);
  EXPECT_EQ(0, slice_header_in_scalable_extension->first_mb_in_slice);
  EXPECT_EQ(2, slice_header_in_scalable_extension->slice_type);
  EXPECT_EQ(1, slice_header_in_scalable_extension->pic_parameter_set_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->colour_plane_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->frame_num);
  EXPECT_EQ(0, slice_header_in_scalable_extension->field_pic_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->bottom_field_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->idr_pic_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->pic_order_cnt_lsb);
  EXPECT_EQ(0, slice_header_in_scalable_extension->delta_pic_order_cnt_bottom);
  EXPECT_EQ(0, slice_header_in_scalable_extension->delta_pic_order_cnt.size());
  EXPECT_EQ(0, slice_header_in_scalable_extension->direct_spatial_mv_pred_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->num_ref_idx_active_override_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->num_ref_idx_l0_active_minus1);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->num_ref_idx_l1_active_minus1);
  // ref_pic_list_modification()
  auto& ref_pic_list_modification =
      slice_header_in_scalable_extension->ref_pic_list_modification;
  ASSERT_TRUE(ref_pic_list_modification != nullptr);
  EXPECT_EQ(2, ref_pic_list_modification->slice_type);
  EXPECT_EQ(0, ref_pic_list_modification->ref_pic_list_modification_flag_l0);
  EXPECT_EQ(0, ref_pic_list_modification->modification_of_pic_nums_idc.size());
  EXPECT_EQ(0, ref_pic_list_modification->abs_diff_pic_num_minus1.size());
  EXPECT_EQ(0, ref_pic_list_modification->long_term_pic_num.size());
  EXPECT_EQ(0, ref_pic_list_modification->ref_pic_list_modification_flag_l1);

  EXPECT_EQ(0, slice_header_in_scalable_extension->base_pred_weight_table_flag);
  EXPECT_EQ(nullptr, slice_header_in_scalable_extension->pred_weight_table);
  // dec_ref_pic_marking()
  auto& dec_ref_pic_marking =
      slice_header_in_scalable_extension->dec_ref_pic_marking;
  ASSERT_TRUE(dec_ref_pic_marking != nullptr);
  EXPECT_EQ(20, dec_ref_pic_marking->nal_unit_type);
  EXPECT_EQ(0, dec_ref_pic_marking->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_reference_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->memory_management_control_operation.size());
  EXPECT_EQ(0, dec_ref_pic_marking->difference_of_pic_nums_minus1.size());
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_pic_num.size());
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_frame_idx.size());
  EXPECT_EQ(0, dec_ref_pic_marking->max_long_term_frame_idx_plus1.size());

  EXPECT_EQ(0, slice_header_in_scalable_extension->store_ref_base_pic_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->cabac_init_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_qp_delta);
  EXPECT_EQ(10,
            slice_header_in_scalable_extension->disable_deblocking_filter_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_alpha_c0_offset_div2);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_beta_offset_div2);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_group_change_cycle);
  EXPECT_EQ(0, slice_header_in_scalable_extension->ref_layer_dq_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension
                   ->disable_inter_layer_deblocking_filter_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension
                   ->inter_layer_slice_alpha_c0_offset_div2);
  EXPECT_EQ(
      49,
      slice_header_in_scalable_extension->inter_layer_slice_beta_offset_div2);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->constrained_intra_resampling_flag);
  EXPECT_EQ(
      0,
      slice_header_in_scalable_extension->ref_layer_chroma_phase_x_plus1_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->ref_layer_chroma_phase_y_plus1);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_left_offset);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scaled_ref_layer_top_offset);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_right_offset);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_bottom_offset);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_skip_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->num_mbs_in_slice_minus1);
  EXPECT_EQ(1, slice_header_in_scalable_extension->adaptive_base_mode_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->default_base_mode_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->adaptive_motion_prediction_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->default_motion_prediction_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->adaptive_residual_prediction_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->default_residual_prediction_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->tcoeff_level_prediction_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scan_idx_start);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scan_idx_end);
}

}  // namespace h264nal
