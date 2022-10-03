/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_pred_weight_table_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264PredWeightTableParserTest : public ::testing::Test {
 public:
  H264PredWeightTableParserTest() {}
  ~H264PredWeightTableParserTest() override {}
};

TEST_F(H264PredWeightTableParserTest, TestSamplePredWeightTable1) {
  // pred_weight_table
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x6c};
  // fuzzer::conv: begin
  uint32_t chroma_array_type = 1;
  uint32_t slice_type = SliceType::P_ALL;
  uint32_t num_ref_idx_l0_active_minus1 = 0;
  uint32_t num_ref_idx_l1_active_minus1 = 0;

  auto pred_weight_table = H264PredWeightTableParser::ParsePredWeightTable(
      buffer, arraysize(buffer), chroma_array_type, slice_type,
      num_ref_idx_l0_active_minus1, num_ref_idx_l1_active_minus1);
  // fuzzer::conv: end

  EXPECT_TRUE(pred_weight_table != nullptr);

  EXPECT_EQ(2, pred_weight_table->luma_log2_weight_denom);
  EXPECT_EQ(2, pred_weight_table->chroma_log2_weight_denom);
  EXPECT_EQ(1, pred_weight_table->luma_weight_l0_flag.size());
  EXPECT_THAT(pred_weight_table->luma_weight_l0_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_EQ(0, pred_weight_table->luma_weight_l0.size());
  EXPECT_EQ(0, pred_weight_table->luma_offset_l0.size());
  EXPECT_EQ(1, pred_weight_table->chroma_weight_l0_flag.size());
  EXPECT_THAT(pred_weight_table->chroma_weight_l0_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_EQ(0, pred_weight_table->chroma_weight_l0.size());
  EXPECT_EQ(0, pred_weight_table->chroma_offset_l0.size());
  EXPECT_EQ(0, pred_weight_table->luma_weight_l1_flag.size());
  EXPECT_EQ(0, pred_weight_table->luma_weight_l1.size());
  EXPECT_EQ(0, pred_weight_table->luma_offset_l1.size());
  EXPECT_EQ(0, pred_weight_table->chroma_weight_l1_flag.size());
  EXPECT_EQ(0, pred_weight_table->chroma_weight_l1.size());
  EXPECT_EQ(0, pred_weight_table->chroma_offset_l1.size());
}

TEST_F(H264PredWeightTableParserTest, TestSamplePredWeightTable2) {
  // pred_weight_table
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x81, 0x01, 0x6d, 0x6d, 0x6a, 0x74, 0x69, 0x6d,
      0x1b, 0x4a, 0xc9, 0x94, 0xc0, 0x00, 0x00, 0x00,
      0xaf, 0xff, 0x22, 0x99, 0xae, 0xc6, 0x58, 0x42,
      0x89, 0x35, 0x86, 0x40, 0x23
};

  // fuzzer::conv: begin
  uint32_t chroma_array_type = 1;
  uint32_t slice_type = SliceType::P_ALL;
  uint32_t num_ref_idx_l0_active_minus1 = 12;
  uint32_t num_ref_idx_l1_active_minus1 = 0;

  auto pred_weight_table = H264PredWeightTableParser::ParsePredWeightTable(
      buffer, arraysize(buffer), chroma_array_type, slice_type,
      num_ref_idx_l0_active_minus1, num_ref_idx_l1_active_minus1);
  // fuzzer::conv: end

  EXPECT_TRUE(pred_weight_table != nullptr);

  EXPECT_EQ(0, pred_weight_table->luma_log2_weight_denom);
  EXPECT_EQ(63, pred_weight_table->chroma_log2_weight_denom);
  EXPECT_THAT(
      pred_weight_table->luma_weight_l0_flag,
      ::testing::ElementsAreArray({0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0}));
  EXPECT_THAT(pred_weight_table->luma_weight_l0,
              ::testing::ElementsAreArray({-1, -1, -1, 2}));
  EXPECT_THAT(pred_weight_table->luma_offset_l0,
              ::testing::ElementsAreArray({1, 2, 6, 0}));
  EXPECT_THAT(
      pred_weight_table->chroma_weight_l0_flag,
      ::testing::ElementsAreArray({1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0}));

  EXPECT_THAT(pred_weight_table->chroma_offset_l0,
              ::testing::ElementsAreArray({
                  ::testing::ElementsAreArray({-1, 0}),
                  ::testing::ElementsAreArray({1, -3}),
                  ::testing::ElementsAreArray({-2, -1}),
                  ::testing::ElementsAreArray({0, 1}),
                  ::testing::ElementsAreArray({-2, 0x15ffe453}),
                  ::testing::ElementsAreArray({1, 0}),
                  ::testing::ElementsAreArray({8, 1}),
                  ::testing::ElementsAreArray({0, -12}),
              }));

  EXPECT_THAT(pred_weight_table->chroma_weight_l0,
              ::testing::ElementsAreArray({
                  ::testing::ElementsAreArray({-1, 1}),
                  ::testing::ElementsAreArray({0, 0}),
                  ::testing::ElementsAreArray({-6, 0}),
                  ::testing::ElementsAreArray({-6, 1}),
                  ::testing::ElementsAreArray({0, 3}),
                  ::testing::ElementsAreArray({0, 0}),
                  ::testing::ElementsAreArray({-1, 0}),
                  ::testing::ElementsAreArray({1, 0}),
              }));

  EXPECT_EQ(0, pred_weight_table->luma_weight_l1_flag.size());
  EXPECT_EQ(0, pred_weight_table->luma_weight_l1.size());
  EXPECT_EQ(0, pred_weight_table->luma_offset_l1.size());
  EXPECT_EQ(0, pred_weight_table->chroma_weight_l1_flag.size());
  EXPECT_EQ(0, pred_weight_table->chroma_weight_l1.size());
  EXPECT_EQ(0, pred_weight_table->chroma_offset_l1.size());
}

}  // namespace h264nal
