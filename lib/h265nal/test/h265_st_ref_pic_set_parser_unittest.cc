/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_st_ref_pic_set_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "h265_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265StRefPicSetParserTest : public ::testing::Test {
 public:
  H265StRefPicSetParserTest() {}
  ~H265StRefPicSetParserTest() override {}
};

TEST_F(H265StRefPicSetParserTest, TestSampleStRefPicSet) {
  // st_ref_pic_set
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x5d};
  // fuzzer::conv: begin
  auto sps = std::make_shared<H265SpsParser::SpsState>();
  sps->num_short_term_ref_pic_sets = 0;
  uint32_t max_num_pics = 1;
  auto st_ref_pic_set = H265StRefPicSetParser::ParseStRefPicSet(
      buffer, arraysize(buffer), 0, 1, &(sps->st_ref_pic_set), max_num_pics);
  // fuzzer::conv: end

  EXPECT_TRUE(st_ref_pic_set != nullptr);

  EXPECT_EQ(1, st_ref_pic_set->num_negative_pics);
  EXPECT_EQ(0, st_ref_pic_set->num_positive_pics);
  EXPECT_THAT(st_ref_pic_set->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({0}));
  EXPECT_THAT(st_ref_pic_set->delta_poc_s0_minus1,
              ::testing::ElementsAreArray({0}));
}

}  // namespace h265nal
