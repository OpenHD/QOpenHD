/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_profile_tier_level_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265ProfileTierLevelParserTest : public ::testing::Test {
 public:
  H265ProfileTierLevelParserTest() {}
  ~H265ProfileTierLevelParserTest() override {}
};

TEST_F(H265ProfileTierLevelParserTest, TestSampleValue) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x60, 0x00, 0x00, 0x03, 0x00, 0xb0, 0x00,
      0x00, 0x03, 0x00, 0x00, 0x03, 0x00, 0x5d, 0xac,
      0x59
  };
  // fuzzer::conv: begin
  auto ptls = H265ProfileTierLevelParser::ParseProfileTierLevel(
      buffer, arraysize(buffer), true, 0);
  // fuzzer::conv: end

  EXPECT_TRUE(ptls != nullptr);

  EXPECT_EQ(0, ptls->general->profile_space);
  EXPECT_EQ(0, ptls->general->tier_flag);
  EXPECT_EQ(1, ptls->general->profile_idc);
  EXPECT_THAT(ptls->general->profile_compatibility_flag,
              ::testing::ElementsAreArray({0, 1, 1, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0}));
  EXPECT_EQ(1, ptls->general->progressive_source_flag);
  EXPECT_EQ(0, ptls->general->interlaced_source_flag);
  EXPECT_EQ(1, ptls->general->non_packed_constraint_flag);
  EXPECT_EQ(1, ptls->general->frame_only_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_12bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_10bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_8bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_422chroma_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_420chroma_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_monochrome_constraint_flag);
  EXPECT_EQ(0, ptls->general->intra_constraint_flag);
  EXPECT_EQ(0, ptls->general->one_picture_only_constraint_flag);
  EXPECT_EQ(0, ptls->general->lower_bit_rate_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_14bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->reserved_zero_33bits);
  EXPECT_EQ(0, ptls->general->reserved_zero_34bits);
  EXPECT_EQ(0, ptls->general->reserved_zero_43bits);
  EXPECT_EQ(0, ptls->general->inbld_flag);
  EXPECT_EQ(0, ptls->general->reserved_zero_bit);
  EXPECT_EQ(93, ptls->general_level_idc);

  EXPECT_EQ(0, ptls->sub_layer_profile_present_flag.size());
  EXPECT_EQ(0, ptls->sub_layer_level_present_flag.size());
  EXPECT_EQ(0, ptls->reserved_zero_2bits.size());
  EXPECT_EQ(0, ptls->sub_layer.size());
}

TEST_F(H265ProfileTierLevelParserTest, Test022018Standard) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x01, 0x60, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00,
      0x00, 0x00, 0x00, 0xba, 0x00, 0x00, 0x2c, 0x09
  };
  // fuzzer::conv: begin
  auto ptls = H265ProfileTierLevelParser::ParseProfileTierLevel(
      buffer, arraysize(buffer), true, 0);
  // fuzzer::conv: end

  EXPECT_TRUE(ptls != nullptr);

  EXPECT_EQ(0, ptls->general->profile_space);
  EXPECT_EQ(0, ptls->general->tier_flag);
  EXPECT_EQ(1, ptls->general->profile_idc);
  EXPECT_THAT(ptls->general->profile_compatibility_flag,
              ::testing::ElementsAreArray({0, 1, 1, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0}));
  EXPECT_EQ(1, ptls->general->progressive_source_flag);
  EXPECT_EQ(0, ptls->general->interlaced_source_flag);
  EXPECT_EQ(0, ptls->general->non_packed_constraint_flag);
  EXPECT_EQ(0, ptls->general->frame_only_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_12bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_10bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_8bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_422chroma_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_420chroma_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_monochrome_constraint_flag);
  EXPECT_EQ(0, ptls->general->intra_constraint_flag);
  EXPECT_EQ(0, ptls->general->one_picture_only_constraint_flag);
  EXPECT_EQ(0, ptls->general->lower_bit_rate_constraint_flag);
  EXPECT_EQ(0, ptls->general->max_14bit_constraint_flag);
  EXPECT_EQ(0, ptls->general->reserved_zero_33bits);
  EXPECT_EQ(0, ptls->general->reserved_zero_34bits);
  EXPECT_EQ(0, ptls->general->reserved_zero_43bits);
  EXPECT_EQ(0, ptls->general->inbld_flag);
  EXPECT_EQ(0, ptls->general->reserved_zero_bit);
  EXPECT_EQ(186, ptls->general_level_idc);

  EXPECT_EQ(0, ptls->sub_layer_profile_present_flag.size());
  EXPECT_EQ(0, ptls->sub_layer_level_present_flag.size());
  EXPECT_EQ(0, ptls->reserved_zero_2bits.size());
  EXPECT_EQ(0, ptls->sub_layer.size());
}

}  // namespace h265nal
