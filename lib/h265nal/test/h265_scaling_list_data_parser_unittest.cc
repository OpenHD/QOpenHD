/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_scaling_list_data_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265ScalingListDataParserTest : public ::testing::Test {
 public:
  H265ScalingListDataParserTest() {}
  ~H265ScalingListDataParserTest() override {}
};

TEST_F(H265ScalingListDataParserTest, TestSampleScalingListData01) {
  // scaling_list_data
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
  };
  // fuzzer::conv: begin
  auto scaling_list_data = H265ScalingListDataParser::ParseScalingListData(
      buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(scaling_list_data != nullptr);

  // scaling_list_pred_mode_flag
  EXPECT_EQ(4, scaling_list_data->scaling_list_pred_mode_flag.size());
  EXPECT_THAT(scaling_list_data->scaling_list_pred_mode_flag[0],
              ::testing::ElementsAreArray({1, 1, 1, 1, 1, 1}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_mode_flag[1],
              ::testing::ElementsAreArray({1, 1, 1, 1, 1, 1}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_mode_flag[2],
              ::testing::ElementsAreArray({1, 1, 1, 1, 1, 1}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_mode_flag[3],
              ::testing::ElementsAreArray({1, 0, 0, 1, 0, 0}));

  // scaling_list_pred_matrix_id_delta[]
  EXPECT_EQ(4, scaling_list_data->scaling_list_pred_matrix_id_delta.size());
  EXPECT_THAT(scaling_list_data->scaling_list_pred_matrix_id_delta[0],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_matrix_id_delta[1],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_matrix_id_delta[2],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_pred_matrix_id_delta[3],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));

  // scaling_list_dc_coef_minus8[]
  EXPECT_EQ(4, scaling_list_data->scaling_list_dc_coef_minus8.size());
  EXPECT_THAT(scaling_list_data->scaling_list_dc_coef_minus8[0],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_dc_coef_minus8[1],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_dc_coef_minus8[2],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));
  EXPECT_THAT(scaling_list_data->scaling_list_dc_coef_minus8[3],
              ::testing::ElementsAreArray({0, 0, 0, 0, 0, 0}));

  // ScalingList[]
  EXPECT_EQ(4, scaling_list_data->ScalingList.size());

  // ScalingList[0]
  EXPECT_EQ(6, scaling_list_data->ScalingList[0].size());
  for (uint32_t matrixId = 0; matrixId < 6; matrixId += 1) {
    EXPECT_THAT(scaling_list_data->ScalingList[0][matrixId],
                ::testing::ElementsAreArray({8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8}));
  }

  // ScalingList[1]
  EXPECT_EQ(6, scaling_list_data->ScalingList[1].size());
  for (uint32_t matrixId = 0; matrixId < 6; matrixId += 1) {
    EXPECT_THAT(scaling_list_data->ScalingList[1][matrixId],
                ::testing::ElementsAreArray({8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8}));
  }

  // ScalingList[2]
  EXPECT_EQ(6, scaling_list_data->ScalingList[2].size());
  for (uint32_t matrixId = 0; matrixId < 6; matrixId += 1) {
    EXPECT_THAT(scaling_list_data->ScalingList[2][matrixId],
                ::testing::ElementsAreArray({8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8,
                                             8, 8, 8, 8, 8, 8, 8, 8}));
  }

  // ScalingList[3]
  EXPECT_EQ(6, scaling_list_data->ScalingList[3].size());
  EXPECT_THAT(scaling_list_data->ScalingList[3][0],
              ::testing::ElementsAreArray({8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8}));
  EXPECT_EQ(0, scaling_list_data->ScalingList[3][1].size());
  EXPECT_EQ(0, scaling_list_data->ScalingList[3][2].size());
  EXPECT_THAT(scaling_list_data->ScalingList[3][3],
              ::testing::ElementsAreArray({8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8,
                                           8, 8, 8, 8, 8, 8, 8, 8}));
  EXPECT_EQ(0, scaling_list_data->ScalingList[3][4].size());
  EXPECT_EQ(0, scaling_list_data->ScalingList[3][5].size());
}

}  // namespace h265nal
