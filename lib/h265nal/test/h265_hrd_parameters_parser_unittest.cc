/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_hrd_parameters_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265HrdParametersParserTest : public ::testing::Test {
 public:
  H265HrdParametersParserTest() {}
  ~H265HrdParametersParserTest() override {}
};

TEST_F(H265HrdParametersParserTest, TestSampleHrdParameters) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x80, 0x17, 0x79, 0x44, 0x00, 0x05, 0xb8, 0xd8,
      0x00, 0x07, 0xa1, 0x20, 0x40, 0x00
  };
  // fuzzer::conv: begin
  uint32_t commonInfPresentFlag = 1;
  uint32_t maxNumSubLayersMinus1 = 0;
  auto hrd_parameters = H265HrdParametersParser::ParseHrdParameters(
      buffer, arraysize(buffer), commonInfPresentFlag, maxNumSubLayersMinus1);
  // fuzzer::conv: end

  EXPECT_TRUE(hrd_parameters != nullptr);

  EXPECT_EQ(1, hrd_parameters->nal_hrd_parameters_present_flag);
  EXPECT_EQ(0, hrd_parameters->vcl_hrd_parameters_present_flag);
  EXPECT_EQ(0, hrd_parameters->sub_pic_hrd_params_present_flag);
  EXPECT_EQ(0, hrd_parameters->tick_divisor_minus2);
  EXPECT_EQ(0, hrd_parameters->du_cpb_removal_delay_increment_length_minus1);
  EXPECT_EQ(0, hrd_parameters->sub_pic_cpb_params_in_pic_timing_sei_flag);
  EXPECT_EQ(0, hrd_parameters->dpb_output_delay_du_length_minus1);
  EXPECT_EQ(0, hrd_parameters->bit_rate_scale);
  EXPECT_EQ(0, hrd_parameters->cpb_size_scale);
  EXPECT_EQ(0, hrd_parameters->cpb_size_du_scale);
  EXPECT_EQ(23, hrd_parameters->initial_cpb_removal_delay_length_minus1);
  EXPECT_EQ(15, hrd_parameters->au_cpb_removal_delay_length_minus1);
  EXPECT_EQ(5, hrd_parameters->dpb_output_delay_length_minus1);
  EXPECT_THAT(hrd_parameters->fixed_pic_rate_general_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(hrd_parameters->fixed_pic_rate_within_cvs_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(hrd_parameters->elemental_duration_in_tc_minus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(hrd_parameters->low_delay_hrd_flag,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(hrd_parameters->cpb_cnt_minus1, ::testing::ElementsAreArray({0}));

  auto& sub_layer_hrd_parameters_vector =
      hrd_parameters->sub_layer_hrd_parameters_vector;
  EXPECT_EQ(1, sub_layer_hrd_parameters_vector.size());
  auto& sub_layer_hrd_parameters =
      hrd_parameters->sub_layer_hrd_parameters_vector[0];
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
