/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_pred_weight_table_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265PredWeightTableParserTest : public ::testing::Test {
 public:
  H265PredWeightTableParserTest() {}
  ~H265PredWeightTableParserTest() override {}
};

TEST_F(H265PredWeightTableParserTest, TestSamplePredWeightTable1) {
  // pred_weight_table
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x10, 0xc6};
  // fuzzer::conv: begin
  auto pred_weight_table = H265PredWeightTableParser::ParsePredWeightTable(
      buffer, arraysize(buffer), 1, 0);
  // fuzzer::conv: end

  EXPECT_TRUE(pred_weight_table != nullptr);

  EXPECT_EQ(7, pred_weight_table->luma_log2_weight_denom);
  EXPECT_EQ(-1, pred_weight_table->delta_chroma_log2_weight_denom);
  EXPECT_THAT(pred_weight_table->luma_weight_l0_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(pred_weight_table->chroma_weight_l0_flag,
              ::testing::ElementsAreArray({0}));
}

TEST_F(H265PredWeightTableParserTest, TestSamplePredWeightTable2) {
  // pred_weight_table
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x10, 0xc0, 0x60};
  // fuzzer::conv: begin
  auto pred_weight_table = H265PredWeightTableParser::ParsePredWeightTable(
      buffer, arraysize(buffer), 1, 2);
  // fuzzer::conv: end

  EXPECT_TRUE(pred_weight_table != nullptr);

  EXPECT_EQ(7, pred_weight_table->luma_log2_weight_denom);
  EXPECT_EQ(-1, pred_weight_table->delta_chroma_log2_weight_denom);
  EXPECT_THAT(pred_weight_table->luma_weight_l0_flag,
              ::testing::ElementsAreArray({0, 0, 0}));
  EXPECT_THAT(pred_weight_table->chroma_weight_l0_flag,
              ::testing::ElementsAreArray({0, 0, 0}));
}

}  // namespace h265nal
