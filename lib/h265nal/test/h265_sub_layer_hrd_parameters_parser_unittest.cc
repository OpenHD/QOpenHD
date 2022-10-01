/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sub_layer_hrd_parameters_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SubLayerHrdParametersParserTest : public ::testing::Test {
 public:
  H265SubLayerHrdParametersParserTest() {}
  ~H265SubLayerHrdParametersParserTest() override {}
};

TEST_F(H265SubLayerHrdParametersParserTest, TestSampleSubLayerHrdParameters) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x00, 0x01, 0x6e, 0x36, 0x00, 0x01, 0xe8, 0x48,
      0x10
  };
  // fuzzer::conv: begin
  uint32_t subLayerId = 0;
  uint32_t CpbCnt = 1;
  uint32_t sub_pic_hrd_params_present_flag = 0;
  auto sub_layer_hrd_parameters =
      H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
          buffer, arraysize(buffer), subLayerId, CpbCnt,
          sub_pic_hrd_params_present_flag);
  // fuzzer::conv: end

  EXPECT_TRUE(sub_layer_hrd_parameters != nullptr);

  EXPECT_THAT(sub_layer_hrd_parameters->bit_rate_value_minus1,
              ::testing::ElementsAreArray({46874}));
  EXPECT_THAT(sub_layer_hrd_parameters->cpb_size_value_minus1,
              ::testing::ElementsAreArray({124999}));
  EXPECT_THAT(sub_layer_hrd_parameters->cpb_size_du_value_minus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(sub_layer_hrd_parameters->bit_rate_du_value_minus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(sub_layer_hrd_parameters->cbr_flag,
              ::testing::ElementsAreArray({0}));
}

}  // namespace h265nal
