/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_common.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <vector>

#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265CommonTest : public ::testing::Test {
 public:
  H265CommonTest() {}
  ~H265CommonTest() override {}
};

TEST_F(H265CommonTest, TestIsSliceSegment) {
  EXPECT_TRUE(IsSliceSegment(TRAIL_N));
  EXPECT_FALSE(IsSliceSegment(VPS_NUT));
}

TEST_F(H265CommonTest, TestIsNalUnitTypeVcl) {
  EXPECT_TRUE(IsNalUnitTypeVcl(BLA_W_LP));
  EXPECT_TRUE(IsNalUnitTypeVcl(BLA_W_LP));
  EXPECT_FALSE(IsNalUnitTypeVcl(VPS_NUT));
  EXPECT_FALSE(IsNalUnitTypeVcl(RSV_NVCL43));
}

TEST_F(H265CommonTest, TestIsNalUnitTypeNonVcl) {
  EXPECT_TRUE(IsNalUnitTypeNonVcl(VPS_NUT));
  EXPECT_TRUE(IsNalUnitTypeNonVcl(RSV_NVCL43));
  EXPECT_FALSE(IsNalUnitTypeNonVcl(BLA_W_LP));
}

TEST_F(H265CommonTest, TestIsNalUnitTypeUnspecified) {
  EXPECT_TRUE(IsNalUnitTypeUnspecified(UNSPEC50));
  EXPECT_TRUE(IsNalUnitTypeUnspecified(UNSPEC63));
  EXPECT_FALSE(IsNalUnitTypeUnspecified(BLA_W_LP));
  EXPECT_FALSE(IsNalUnitTypeUnspecified(RSV_NVCL47));
}

struct H265CommonMoreRbspDataParameterTestData {
  std::string description;
  std::vector<uint8_t> buffer;
  size_t cur_byte_offset;
  size_t cur_bit_offset;
  bool expected_result;
};

class H265CommonMoreRbspDataTest
    : public ::testing::TestWithParam<H265CommonMoreRbspDataParameterTestData> {
};

const auto& kH265CommonMoreRbspDataParameterTestcases = *new std::vector<
    H265CommonMoreRbspDataParameterTestData>{
    {"case 1: no more data in the bit buffer", {0x00, 0x00}, 2, 0, false},
    {"case 2: more than 1 byte left",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0xb0},
     4,
     4,
     true},
    {"case 3: at last byte (begin), with 1000,0000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x80},
     5,
     0,
     false},
    {"case 4: at last byte (begin), with 1000,1000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x88},
     5,
     0,
     true},
    {"case 5: at last byte (bit 1), with 1-100,0000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0xc0},
     5,
     1,
     false},
    {"case 6: at last byte (bit 1), with 0-100,0000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x40},
     5,
     1,
     false},
    {"case 7: at last byte (bit 1), with 0-000,0000 (no rbsp_trailing_bits())",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x00},
     5,
     1,
     true},
    {"case 8: at last byte (bit 1), with 0-100,1000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x48},
     5,
     1,
     true},
    {"case 9: at last byte (bit 4), with 1-1000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x18},
     5,
     4,
     false},
    {"case 10: at last byte (bit 4), with 0-1000",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x08},
     5,
     4,
     false},
    {"case 11: at last byte (bit 4), with 0000 (no rbsp_trailing_bits())",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x00},
     5,
     4,
     true},
    {"case 12: at last byte (bit 4), with 0010",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x02},
     5,
     4,
     true},
    {"case 13: at last byte (bit 7), with 1",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x01},
     5,
     7,
     false},
    {"case 14: at last byte (bit 7), with 0 (no rbsp_trailing_bits())",
     {0xe8, 0x43, 0x82, 0x92, 0xc8, 0x00},
     5,
     7,
     true},
};

TEST_P(H265CommonMoreRbspDataTest, Run) {
  const auto& testcase = GetParam();
  rtc::BitBuffer bit_buffer(testcase.buffer.data(), testcase.buffer.size());
  bit_buffer.Seek(testcase.cur_byte_offset, testcase.cur_bit_offset);
  // 1: store the bit buffer status before the more_rbsp_data call
  size_t pre_out_byte_offset;
  size_t pre_out_bit_offset;
  bit_buffer.GetCurrentOffset(&pre_out_byte_offset, &pre_out_bit_offset);
  // 2: check more_rbsp_data
  EXPECT_EQ(testcase.expected_result, more_rbsp_data(&bit_buffer))
      << "description: " << testcase.description;
  // 3: store the bit buffer status after the more_rbsp_data call
  size_t post_out_byte_offset;
  size_t post_out_bit_offset;
  bit_buffer.GetCurrentOffset(&post_out_byte_offset, &post_out_bit_offset);
  // then make sure the function is a const
  EXPECT_EQ(pre_out_byte_offset, post_out_byte_offset);
  EXPECT_EQ(pre_out_bit_offset, post_out_bit_offset);
}

INSTANTIATE_TEST_SUITE_P(
    Parameter, H265CommonMoreRbspDataTest,
    ::testing::ValuesIn(kH265CommonMoreRbspDataParameterTestcases));

}  // namespace h265nal
