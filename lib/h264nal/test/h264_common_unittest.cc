/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_common.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <vector>

#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264CommonTest : public ::testing::Test {
 public:
  H264CommonTest() {}
  ~H264CommonTest() override {}
};

TEST_F(H264CommonTest, TestIsNalUnitTypeReserved) {
  EXPECT_TRUE(IsNalUnitTypeReserved(RSV16_NUT));
  EXPECT_TRUE(IsNalUnitTypeReserved(RSV23_NUT));
  EXPECT_FALSE(IsNalUnitTypeReserved(UNSPEC24_NUT));
}

TEST_F(H264CommonTest, TestIsNalUnitTypeUnspecified) {
  EXPECT_TRUE(IsNalUnitTypeUnspecified(UNSPEC24_NUT));
  EXPECT_TRUE(IsNalUnitTypeUnspecified(UNSPEC31_NUT));
  EXPECT_FALSE(IsNalUnitTypeUnspecified(RSV16_NUT));
}

struct H264CommonMoreRbspDataParameterTestData {
  std::string description;
  std::vector<uint8_t> buffer;
  size_t cur_byte_offset;
  size_t cur_bit_offset;
  bool expected_result;
};

class H264CommonMoreRbspDataTest
    : public ::testing::TestWithParam<H264CommonMoreRbspDataParameterTestData> {
};

const auto& kH264CommonMoreRbspDataParameterTestcases = *new std::vector<
    H264CommonMoreRbspDataParameterTestData>{
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

TEST_P(H264CommonMoreRbspDataTest, Run) {
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
    Parameter, H264CommonMoreRbspDataTest,
    ::testing::ValuesIn(kH264CommonMoreRbspDataParameterTestcases));

}  // namespace h264nal
