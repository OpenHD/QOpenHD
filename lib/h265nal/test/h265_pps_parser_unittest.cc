/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_pps_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265PpsParserTest : public ::testing::Test {
 public:
  H265PpsParserTest() {}
  ~H265PpsParserTest() override {}
};

TEST_F(H265PpsParserTest, TestSamplePPS) {
  // PPS example
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xc0, 0xf3, 0xc0, 0x02, 0x10, 0x00
  };
  // fuzzer::conv: begin
  auto pps = H265PpsParser::ParsePps(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(pps != nullptr);

  EXPECT_EQ(0, pps->pps_pic_parameter_set_id);
  EXPECT_EQ(0, pps->pps_seq_parameter_set_id);
  EXPECT_EQ(0, pps->dependent_slice_segments_enabled_flag);
  EXPECT_EQ(0, pps->output_flag_present_flag);
  EXPECT_EQ(0, pps->num_extra_slice_header_bits);
  EXPECT_EQ(0, pps->sign_data_hiding_enabled_flag);
  EXPECT_EQ(1, pps->cabac_init_present_flag);
  EXPECT_EQ(0, pps->num_ref_idx_l0_default_active_minus1);
  EXPECT_EQ(0, pps->num_ref_idx_l1_default_active_minus1);
  EXPECT_EQ(0, pps->init_qp_minus26);
  EXPECT_EQ(0, pps->constrained_intra_pred_flag);
  EXPECT_EQ(0, pps->transform_skip_enabled_flag);
  EXPECT_EQ(1, pps->cu_qp_delta_enabled_flag);
  EXPECT_EQ(0, pps->diff_cu_qp_delta_depth);
  EXPECT_EQ(0, pps->pps_cb_qp_offset);
  EXPECT_EQ(0, pps->pps_cr_qp_offset);
  EXPECT_EQ(0, pps->pps_slice_chroma_qp_offsets_present_flag);
  EXPECT_EQ(0, pps->weighted_pred_flag);
  EXPECT_EQ(0, pps->weighted_bipred_flag);
  EXPECT_EQ(0, pps->transquant_bypass_enabled_flag);
  EXPECT_EQ(0, pps->tiles_enabled_flag);
  EXPECT_EQ(0, pps->entropy_coding_sync_enabled_flag);
  EXPECT_EQ(0, pps->pps_loop_filter_across_slices_enabled_flag);
  EXPECT_EQ(0, pps->deblocking_filter_control_present_flag);
  EXPECT_EQ(0, pps->pps_scaling_list_data_present_flag);
  EXPECT_EQ(0, pps->lists_modification_present_flag);
  EXPECT_EQ(3, pps->log2_parallel_merge_level_minus2);
  EXPECT_EQ(0, pps->slice_segment_header_extension_present_flag);
  EXPECT_EQ(0, pps->pps_extension_present_flag);

#if 0
  EXPECT_EQ(1, pps->rbsp_stop_one_bit);
#endif
}

}  // namespace h265nal
