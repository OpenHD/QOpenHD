/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_subset_sps_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "h264_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264SubsetSpsParserTest : public ::testing::Test {
 public:
  H264SubsetSpsParserTest() {}
  ~H264SubsetSpsParserTest() override {}
};

TEST_F(H264SubsetSpsParserTest, TestSample01) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x53, 0x00, 0x0b, 0xac, 0x4d, 0x02, 0xc1, 0x2c,
      0x81, 0x20
  };
  // fuzzer::conv: begin
  auto subset_sps =
      H264SubsetSpsParser::ParseSubsetSps(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(subset_sps != nullptr);

  // seq_parameter_set_data()
  auto& sps_data = subset_sps->seq_parameter_set_data;
  EXPECT_TRUE(sps_data != nullptr);

  EXPECT_EQ(83, sps_data->profile_idc);
  EXPECT_EQ(0, sps_data->constraint_set0_flag);
  EXPECT_EQ(0, sps_data->constraint_set1_flag);
  EXPECT_EQ(0, sps_data->constraint_set2_flag);
  EXPECT_EQ(0, sps_data->constraint_set3_flag);
  EXPECT_EQ(0, sps_data->constraint_set4_flag);
  EXPECT_EQ(0, sps_data->constraint_set5_flag);
  EXPECT_EQ(0, sps_data->reserved_zero_2bits);
  EXPECT_EQ(11, sps_data->level_idc);
  EXPECT_EQ(0, sps_data->seq_parameter_set_id);
  EXPECT_EQ(1, sps_data->log2_max_frame_num_minus4);
  EXPECT_EQ(2, sps_data->pic_order_cnt_type);
  EXPECT_EQ(1, sps_data->max_num_ref_frames);
  EXPECT_EQ(0, sps_data->gaps_in_frame_num_value_allowed_flag);
  EXPECT_EQ(21, sps_data->pic_width_in_mbs_minus1);
  EXPECT_EQ(17, sps_data->pic_height_in_map_units_minus1);
  EXPECT_EQ(1, sps_data->frame_mbs_only_flag);
  EXPECT_EQ(1, sps_data->direct_8x8_inference_flag);
  EXPECT_EQ(0, sps_data->frame_cropping_flag);
  EXPECT_EQ(0, sps_data->vui_parameters_present_flag);
}

}  // namespace h264nal
