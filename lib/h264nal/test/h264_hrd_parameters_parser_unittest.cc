/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_hrd_parameters_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264HrdParametersParserTest : public ::testing::Test {
 public:
  H264HrdParametersParserTest() {}
  ~H264HrdParametersParserTest() override {}
};

TEST_F(H264HrdParametersParserTest, TestSampleHrdParameters601IDR) {
  // hrd_parameters
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x9a, 0x80, 0x00, 0x4c, 0x4b, 0x40, 0x00, 0x26,
      0x25, 0xaf, 0xd6, 0xb8, 0x1e, 0x30, 0x62, 0x24
  };

  // fuzzer::conv: begin
  auto hrd_parameters =
      H264HrdParametersParser::ParseHrdParameters(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(hrd_parameters != nullptr);

  EXPECT_EQ(0, hrd_parameters->cpb_cnt_minus1);
  EXPECT_EQ(3, hrd_parameters->bit_rate_scale);
  EXPECT_EQ(5, hrd_parameters->cpb_size_scale);
  EXPECT_THAT(hrd_parameters->bit_rate_value_minus1,
              ::testing::ElementsAreArray({78124}));
  EXPECT_THAT(hrd_parameters->cpb_size_value_minus1,
              ::testing::ElementsAreArray({78124}));
  EXPECT_THAT(hrd_parameters->cbr_flag, ::testing::ElementsAreArray({0}));
  EXPECT_EQ(31, hrd_parameters->initial_cpb_removal_delay_length_minus1);
  EXPECT_EQ(21, hrd_parameters->cpb_removal_delay_length_minus1);
  EXPECT_EQ(21, hrd_parameters->dpb_output_delay_length_minus1);
  EXPECT_EQ(24, hrd_parameters->time_offset_length);
}

}  // namespace h264nal
