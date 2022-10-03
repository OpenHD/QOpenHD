/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_pps_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264PpsParserTest : public ::testing::Test {
 public:
  H264PpsParserTest() {}
  ~H264PpsParserTest() override {}
};

TEST_F(H264PpsParserTest, TestSamplePPS601) {
  // PPS example (601.264)
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xc8, 0x42, 0x02, 0x32, 0xc8};
  // fuzzer::conv: begin
  uint32_t chroma_format_idc = 1;
  auto pps = H264PpsParser::ParsePps(buffer, arraysize(buffer), chroma_format_idc);
  // fuzzer::conv: end

  EXPECT_TRUE(pps != nullptr);

  EXPECT_EQ(0, pps->pic_parameter_set_id);
  EXPECT_EQ(0, pps->seq_parameter_set_id);
  EXPECT_EQ(0, pps->entropy_coding_mode_flag);
  EXPECT_EQ(0, pps->bottom_field_pic_order_in_frame_present_flag);
  EXPECT_EQ(0, pps->num_slice_groups_minus1);
  EXPECT_EQ(15, pps->num_ref_idx_l0_active_minus1);
  EXPECT_EQ(0, pps->num_ref_idx_l1_active_minus1);
  EXPECT_EQ(0, pps->weighted_pred_flag);
  EXPECT_EQ(0, pps->weighted_bipred_idc);
  EXPECT_EQ(-8, pps->pic_init_qp_minus26);
  EXPECT_EQ(0, pps->pic_init_qs_minus26);
  EXPECT_EQ(-2, pps->chroma_qp_index_offset);
  EXPECT_EQ(1, pps->deblocking_filter_control_present_flag);
  EXPECT_EQ(0, pps->constrained_intra_pred_flag);
  EXPECT_EQ(0, pps->redundant_pic_cnt_present_flag);

#if 0
  EXPECT_EQ(1, pps->rbsp_stop_one_bit);
#endif
}

TEST_F(H264PpsParserTest, TestSamplePPS2012) {
  // PPS example (2012 source)
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xe8, 0x43, 0x82, 0x92, 0xc8, 0xb0};

  // fuzzer::conv: begin
  uint32_t chroma_format_idc = 1;
  auto pps = H264PpsParser::ParsePps(buffer, arraysize(buffer), chroma_format_idc);
  // fuzzer::conv: end

  EXPECT_TRUE(pps != nullptr);

  EXPECT_EQ(0, pps->pic_parameter_set_id);
  EXPECT_EQ(0, pps->seq_parameter_set_id);
  EXPECT_EQ(1, pps->entropy_coding_mode_flag);
  EXPECT_EQ(0, pps->bottom_field_pic_order_in_frame_present_flag);
  EXPECT_EQ(0, pps->num_slice_groups_minus1);
  EXPECT_EQ(15, pps->num_ref_idx_l0_active_minus1);
  EXPECT_EQ(0, pps->num_ref_idx_l1_active_minus1);
  EXPECT_EQ(1, pps->weighted_pred_flag);
  EXPECT_EQ(2, pps->weighted_bipred_idc);
  EXPECT_EQ(10, pps->pic_init_qp_minus26);
  EXPECT_EQ(0, pps->pic_init_qs_minus26);
  EXPECT_EQ(-2, pps->chroma_qp_index_offset);
  EXPECT_EQ(1, pps->deblocking_filter_control_present_flag);
  EXPECT_EQ(0, pps->constrained_intra_pred_flag);
  EXPECT_EQ(0, pps->redundant_pic_cnt_present_flag);
  EXPECT_EQ(1, pps->transform_8x8_mode_flag);
  EXPECT_EQ(0, pps->pic_scaling_matrix_present_flag);
  EXPECT_EQ(-2, pps->second_chroma_qp_index_offset);
}

}  // namespace h264nal
