/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SpsParserTest : public ::testing::Test {
 public:
  H265SpsParserTest() {}
  ~H265SpsParserTest() override {}
};

TEST_F(H265SpsParserTest, TestSampleSPS) {
  // SPS for a 1280x736 camera capture.
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x01, 0x60, 0x00, 0x00, 0x03, 0x00, 0xb0,
      0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00, 0x5d,
      0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f, 0x13, 0x96,
      0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82, 0x83, 0x03,
      0x01, 0x76, 0x85, 0x09, 0x40
  };
  // fuzzer::conv: begin
  auto sps = H265SpsParser::ParseSps(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(sps != nullptr);

  EXPECT_EQ(0, sps->sps_video_parameter_set_id);
  EXPECT_EQ(0, sps->sps_max_sub_layers_minus1);
  EXPECT_EQ(1, sps->sps_temporal_id_nesting_flag);
  // profile_tier_level start
  EXPECT_EQ(0, sps->profile_tier_level->general->profile_space);
  EXPECT_EQ(0, sps->profile_tier_level->general->tier_flag);
  EXPECT_EQ(1, sps->profile_tier_level->general->profile_idc);
  EXPECT_THAT(sps->profile_tier_level->general->profile_compatibility_flag,
              ::testing::ElementsAreArray({0, 1, 1, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0}));
  EXPECT_EQ(1, sps->profile_tier_level->general->progressive_source_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->interlaced_source_flag);
  EXPECT_EQ(1, sps->profile_tier_level->general->non_packed_constraint_flag);
  EXPECT_EQ(1, sps->profile_tier_level->general->frame_only_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_12bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_10bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_8bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_422chroma_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_420chroma_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->max_monochrome_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->intra_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->one_picture_only_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->lower_bit_rate_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_14bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_33bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_34bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_43bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->inbld_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_bit);
  EXPECT_EQ(93, sps->profile_tier_level->general_level_idc);
  EXPECT_EQ(0, sps->profile_tier_level->sub_layer_profile_present_flag.size());
  EXPECT_EQ(0, sps->profile_tier_level->sub_layer_level_present_flag.size());
  EXPECT_EQ(0, sps->profile_tier_level->reserved_zero_2bits.size());
  EXPECT_EQ(0, sps->profile_tier_level->sub_layer.size());
  // profile_tier_level end
  EXPECT_EQ(0, sps->sps_seq_parameter_set_id);
  EXPECT_EQ(1, sps->chroma_format_idc);
  EXPECT_EQ(1280, sps->pic_width_in_luma_samples);
  EXPECT_EQ(736, sps->pic_height_in_luma_samples);
  EXPECT_EQ(1, sps->conformance_window_flag);
  EXPECT_EQ(0, sps->conf_win_left_offset);
  EXPECT_EQ(0, sps->conf_win_right_offset);
  EXPECT_EQ(0, sps->conf_win_top_offset);
  EXPECT_EQ(8, sps->conf_win_bottom_offset);
  EXPECT_EQ(0, sps->bit_depth_luma_minus8);
  EXPECT_EQ(0, sps->bit_depth_chroma_minus8);
  EXPECT_EQ(4, sps->log2_max_pic_order_cnt_lsb_minus4);
  EXPECT_EQ(1, sps->sps_sub_layer_ordering_info_present_flag);
  EXPECT_THAT(sps->sps_max_dec_pic_buffering_minus1,
              ::testing::ElementsAreArray({1}));
  EXPECT_THAT(sps->sps_max_num_reorder_pics, ::testing::ElementsAreArray({0}));
  EXPECT_THAT(sps->sps_max_latency_increase_plus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_EQ(0, sps->log2_min_luma_coding_block_size_minus3);
  EXPECT_EQ(2, sps->log2_diff_max_min_luma_coding_block_size);
  EXPECT_EQ(0, sps->log2_min_luma_transform_block_size_minus2);
  EXPECT_EQ(3, sps->log2_diff_max_min_luma_transform_block_size);
  EXPECT_EQ(0, sps->max_transform_hierarchy_depth_inter);
  EXPECT_EQ(0, sps->max_transform_hierarchy_depth_intra);
  EXPECT_EQ(0, sps->scaling_list_enabled_flag);
  EXPECT_EQ(0, sps->amp_enabled_flag);
  EXPECT_EQ(1, sps->sample_adaptive_offset_enabled_flag);
  EXPECT_EQ(0, sps->pcm_enabled_flag);
  EXPECT_EQ(1, sps->num_short_term_ref_pic_sets);

  // st_ref_pic_set(i)
  EXPECT_EQ(1, sps->st_ref_pic_set[0]->num_negative_pics);
  EXPECT_EQ(0, sps->st_ref_pic_set[0]->num_positive_pics);
  EXPECT_THAT(sps->st_ref_pic_set[0]->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(sps->st_ref_pic_set[0]->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({0}));

  EXPECT_EQ(0, sps->long_term_ref_pics_present_flag);
  EXPECT_EQ(1, sps->sps_temporal_mvp_enabled_flag);
  EXPECT_EQ(1, sps->strong_intra_smoothing_enabled_flag);
  EXPECT_EQ(1, sps->vui_parameters_present_flag);

  // vui_parameters()
  EXPECT_EQ(0, sps->vui_parameters->aspect_ratio_info_present_flag);
  EXPECT_EQ(0, sps->vui_parameters->overscan_info_present_flag);
  EXPECT_EQ(1, sps->vui_parameters->video_signal_type_present_flag);
  EXPECT_EQ(2, sps->vui_parameters->video_format);
  EXPECT_EQ(1, sps->vui_parameters->video_full_range_flag);
  EXPECT_EQ(1, sps->vui_parameters->colour_description_present_flag);
  EXPECT_EQ(5, sps->vui_parameters->colour_primaries);
  EXPECT_EQ(6, sps->vui_parameters->transfer_characteristics);
  EXPECT_EQ(6, sps->vui_parameters->matrix_coeffs);
  EXPECT_EQ(0, sps->vui_parameters->chroma_loc_info_present_flag);
  EXPECT_EQ(0, sps->vui_parameters->neutral_chroma_indication_flag);
  EXPECT_EQ(0, sps->vui_parameters->field_seq_flag);
  EXPECT_EQ(0, sps->vui_parameters->frame_field_info_present_flag);
  EXPECT_EQ(0, sps->vui_parameters->default_display_window_flag);
  EXPECT_EQ(0, sps->vui_parameters->vui_timing_info_present_flag);
  EXPECT_EQ(1, sps->vui_parameters->bitstream_restriction_flag);
  EXPECT_EQ(0, sps->vui_parameters->tiles_fixed_structure_flag);
  EXPECT_EQ(1, sps->vui_parameters->motion_vectors_over_pic_boundaries_flag);
  EXPECT_EQ(1, sps->vui_parameters->restricted_ref_pic_lists_flag);
  EXPECT_EQ(0, sps->vui_parameters->min_spatial_segmentation_idc);
  EXPECT_EQ(2, sps->vui_parameters->max_bytes_per_pic_denom);
  EXPECT_EQ(1, sps->vui_parameters->max_bits_per_min_cu_denom);
  EXPECT_EQ(9, sps->vui_parameters->log2_max_mv_length_horizontal);
  EXPECT_EQ(8, sps->vui_parameters->log2_max_mv_length_vertical);

  EXPECT_EQ(0, sps->sps_extension_present_flag);
  EXPECT_EQ(0, sps->sps_range_extension_flag);
  EXPECT_EQ(0, sps->sps_multilayer_extension_flag);
  EXPECT_EQ(0, sps->sps_3d_extension_flag);
  EXPECT_EQ(0, sps->sps_scc_extension_flag);
  EXPECT_EQ(0, sps->sps_extension_4bits);
#if 0
  EXPECT_EQ(1, sps->rbsp_stop_one_bit);
  EXPECT_EQ(0, sps->rbsp_alignment_zero_bit);
#endif

  // derived values
  EXPECT_EQ(920, sps->getPicSizeInCtbsY());
}

TEST_F(H265SpsParserTest, TestSPSBadWidth) {
  // SPS for a 1926x736 camera capture (1926 does not divide 8)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x01, 0x60, 0x00, 0x00, 0x03, 0x00, 0xb0,
      0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00, 0x5d,
      0xa1, 0x02, 0x80, 0x80, 0x2e, 0x1f, 0x13, 0x96,
      0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82, 0x83, 0x03,
      0x01, 0x76, 0x85, 0x09, 0x40
  };
  auto sps = H265SpsParser::ParseSps(buffer, arraysize(buffer));

  EXPECT_TRUE(sps == nullptr);
}

TEST_F(H265SpsParserTest, TestSPSBadHeight) {
  // SPS for a 8x7 camera capture (7 does not divide 8)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x01, 0x60, 0x00, 0x00, 0x03, 0x00, 0xb0,
      0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00, 0x5d,
      0xa0, 0x02, 0x80, 0x80, 0x1e, 0x1f, 0x13, 0x96,
      0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82, 0x83, 0x03,
      0x01, 0x76, 0x85, 0x09, 0x40
  };
  auto sps = H265SpsParser::ParseSps(buffer, arraysize(buffer));

  EXPECT_TRUE(sps == nullptr);
}

TEST_F(H265SpsParserTest, TestComplexStRefPicSet) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x01, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x99, 0xa0, 0x03, 0xc0,
      0x80, 0x11, 0x07, 0xf9, 0x65, 0x26, 0x49, 0x1b,
      0x61, 0xa5, 0x88, 0xaa, 0x93, 0x13, 0x0c, 0xbe,
      0xcf, 0xaf, 0x37, 0xe5, 0x9f, 0x5e, 0x14, 0x46,
      0x27, 0x2e, 0xda, 0xc0, 0xff, 0xff
  };
  auto sps = H265SpsParser::ParseSps(buffer, arraysize(buffer));

  EXPECT_TRUE(sps != nullptr);

  EXPECT_EQ(0, sps->sps_video_parameter_set_id);
  EXPECT_EQ(0, sps->sps_max_sub_layers_minus1);
  EXPECT_EQ(1, sps->sps_temporal_id_nesting_flag);
  // profile_tier_level start
  EXPECT_EQ(0, sps->profile_tier_level->general->profile_space);
  EXPECT_EQ(0, sps->profile_tier_level->general->tier_flag);
  EXPECT_EQ(1, sps->profile_tier_level->general->profile_idc);
  EXPECT_THAT(sps->profile_tier_level->general->profile_compatibility_flag,
              ::testing::ElementsAreArray({0, 1, 1, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0}));
  EXPECT_EQ(0, sps->profile_tier_level->general->progressive_source_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->interlaced_source_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->non_packed_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->frame_only_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_12bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_10bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_8bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_422chroma_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_420chroma_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->max_monochrome_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->intra_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->one_picture_only_constraint_flag);
  EXPECT_EQ(0,
            sps->profile_tier_level->general->lower_bit_rate_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->max_14bit_constraint_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_33bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_34bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_43bits);
  EXPECT_EQ(0, sps->profile_tier_level->general->inbld_flag);
  EXPECT_EQ(0, sps->profile_tier_level->general->reserved_zero_bit);
  EXPECT_EQ(153, sps->profile_tier_level->general_level_idc);

  EXPECT_EQ(0, sps->profile_tier_level->sub_layer_profile_present_flag.size());
  EXPECT_EQ(0, sps->profile_tier_level->sub_layer_level_present_flag.size());
  EXPECT_EQ(0, sps->profile_tier_level->reserved_zero_2bits.size());
  EXPECT_EQ(0, sps->profile_tier_level->sub_layer.size());

  // profile_tier_level end
  EXPECT_EQ(0, sps->sps_seq_parameter_set_id);
  EXPECT_EQ(1, sps->chroma_format_idc);
  EXPECT_EQ(1920, sps->pic_width_in_luma_samples);
  EXPECT_EQ(1088, sps->pic_height_in_luma_samples);
  EXPECT_EQ(1, sps->conformance_window_flag);
  EXPECT_EQ(0, sps->conf_win_left_offset);
  EXPECT_EQ(0, sps->conf_win_right_offset);
  EXPECT_EQ(0, sps->conf_win_top_offset);
  EXPECT_EQ(0, sps->conf_win_bottom_offset);
  EXPECT_EQ(0, sps->bit_depth_luma_minus8);
  EXPECT_EQ(0, sps->bit_depth_chroma_minus8);
  EXPECT_EQ(4, sps->log2_max_pic_order_cnt_lsb_minus4);
  EXPECT_EQ(1, sps->sps_sub_layer_ordering_info_present_flag);
  EXPECT_THAT(sps->sps_max_dec_pic_buffering_minus1,
              ::testing::ElementsAreArray({4}));
  EXPECT_THAT(sps->sps_max_num_reorder_pics, ::testing::ElementsAreArray({3}));
  EXPECT_THAT(sps->sps_max_latency_increase_plus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_EQ(0, sps->log2_min_luma_coding_block_size_minus3);
  EXPECT_EQ(3, sps->log2_diff_max_min_luma_coding_block_size);
  EXPECT_EQ(0, sps->log2_min_luma_transform_block_size_minus2);
  EXPECT_EQ(3, sps->log2_diff_max_min_luma_transform_block_size);
  EXPECT_EQ(2, sps->max_transform_hierarchy_depth_inter);
  EXPECT_EQ(2, sps->max_transform_hierarchy_depth_intra);
  EXPECT_EQ(0, sps->scaling_list_enabled_flag);
  EXPECT_EQ(1, sps->amp_enabled_flag);
  EXPECT_EQ(1, sps->sample_adaptive_offset_enabled_flag);
  EXPECT_EQ(0, sps->pcm_enabled_flag);
  EXPECT_EQ(12, sps->num_short_term_ref_pic_sets);

  // st_ref_pic_set(i)
  int i = 0;
  EXPECT_EQ(4, sps->st_ref_pic_set[i]->num_negative_pics);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->num_positive_pics);
  EXPECT_THAT(sps->st_ref_pic_set[i]->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({7, 1, 1, 3}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_s0_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1}));
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_poc_s1_minus1.size());
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->used_by_curr_pic_s1_flag.size());

  i = 1;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(3, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 0, 0, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 0, 0, 1}));

  i = 2;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1}));

  i = 3;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 0, 1, 1, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 0, 1, 1, 1}));

  i = 4;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));

  i = 5;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(2, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));

  i = 6;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 0, 1, 1, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 0, 1, 1, 1}));

  i = 7;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 1, 1, 0}));

  i = 8;
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->num_negative_pics);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->num_positive_pics);
  EXPECT_THAT(sps->st_ref_pic_set[i]->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({7}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_s0_flag,
              ::testing::ElementsAreArray({1}));
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_poc_s1_minus1.size());
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->used_by_curr_pic_s1_flag.size());

  i = 9;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(3, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1}));

  i = 10;
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_rps_sign);
  EXPECT_EQ(1, sps->st_ref_pic_set[i]->abs_delta_rps_minus1);
  EXPECT_THAT(sps->st_ref_pic_set[i]->used_by_curr_pic_flag,
              ::testing::ElementsAreArray({1, 1, 1}));
  EXPECT_THAT(sps->st_ref_pic_set[i]->use_delta_flag,
              ::testing::ElementsAreArray({1, 1, 1}));

  i = 11;
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->inter_ref_pic_set_prediction_flag);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->num_negative_pics);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->num_positive_pics);
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_poc_s0_minus1.size());
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->used_by_curr_pic_s0_flag.size());
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->delta_poc_s1_minus1.size());
  EXPECT_EQ(0, sps->st_ref_pic_set[i]->used_by_curr_pic_s1_flag.size());

  EXPECT_EQ(0, sps->long_term_ref_pics_present_flag);
  EXPECT_EQ(1, sps->sps_temporal_mvp_enabled_flag);
  EXPECT_EQ(1, sps->strong_intra_smoothing_enabled_flag);
  EXPECT_EQ(0, sps->vui_parameters_present_flag);

  EXPECT_EQ(1, sps->sps_extension_present_flag);
  EXPECT_EQ(0, sps->sps_range_extension_flag);
  EXPECT_EQ(1, sps->sps_multilayer_extension_flag);
  EXPECT_EQ(1, sps->sps_3d_extension_flag);
  EXPECT_EQ(0, sps->sps_scc_extension_flag);
  EXPECT_EQ(0, sps->sps_extension_4bits);

  // derived values
  EXPECT_EQ(510, sps->getPicSizeInCtbsY());
}

}  // namespace h265nal
