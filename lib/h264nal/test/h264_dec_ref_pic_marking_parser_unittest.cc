/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_dec_ref_pic_marking_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264DecRefPicMarkingParserTest : public ::testing::Test {
 public:
  H264DecRefPicMarkingParserTest() {}
  ~H264DecRefPicMarkingParserTest() override {}
};

TEST_F(H264DecRefPicMarkingParserTest, TestSampleDecRefPicMarking601IDR) {
  // dec_ref_pic_marking
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x00};
  // fuzzer::conv: begin
  uint32_t nal_unit_type = NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT;
  auto dec_ref_pic_marking = H264DecRefPicMarkingParser::ParseDecRefPicMarking(
      buffer, arraysize(buffer), nal_unit_type);
  // fuzzer::conv: end

  EXPECT_TRUE(dec_ref_pic_marking != nullptr);

  EXPECT_EQ(0, dec_ref_pic_marking->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_reference_flag);
}

TEST_F(H264DecRefPicMarkingParserTest, TestSampleDecRefPicMarking601NonIDR) {
  // dec_ref_pic_marking
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x00};
  // fuzzer::conv: begin
  uint32_t nal_unit_type = NalUnitType::CODED_SLICE_OF_NON_IDR_PICTURE_NUT;
  auto dec_ref_pic_marking = H264DecRefPicMarkingParser::ParseDecRefPicMarking(
      buffer, arraysize(buffer), nal_unit_type);
  // fuzzer::conv: end

  EXPECT_TRUE(dec_ref_pic_marking != nullptr);

  EXPECT_EQ(0, dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag);
}

}  // namespace h264nal
