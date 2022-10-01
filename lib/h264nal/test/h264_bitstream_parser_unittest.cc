/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_bitstream_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264BitstreamParserTest : public ::testing::Test {
 public:
  H264BitstreamParserTest() {}
  ~H264BitstreamParserTest() override {}
};

// SPS, PPS, slice IDR, slice non-IDR (601.264)
// fuzzer::conv: data
const uint8_t buffer[] = {
    // SPS
    0x00, 0x00, 0x00, 0x01,
    0x67, 0x42, 0xc0, 0x16, 0xa6, 0x11, 0x05, 0x07,
    0xe9, 0xb2, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00,
    0x00, 0x03, 0x00, 0x64, 0x1e, 0x2c, 0x5c, 0x23,
    // PPS
    0x00, 0x00, 0x00, 0x01,
    0x68, 0xc8, 0x42, 0x02, 0x32, 0xc8,
    // slice (IDR)
    0x00, 0x00, 0x00, 0x01,
    0x65, 0x88, 0x82, 0x06, 0x78, 0x8c, 0x50, 0x00,
    0x1c, 0xab, 0x8e, 0x00, 0x02, 0xfb, 0x31, 0xc0,
    0x00, 0x5f, 0x66, 0xfb, 0xef, 0xbe,
    // slice (non-IDR)
    0x00, 0x00, 0x00, 0x01,
    0x41, 0x9a, 0x1c, 0x0c, 0xf0, 0x09, 0x6c
};

TEST_F(H264BitstreamParserTest, TestSampleBitstream601) {
  // SPS/PPS (601.264)
  // fuzzer::conv: begin
  // init the BitstreamParserState
  H264BitstreamParserState bitstream_parser_state;

  auto bitstream = H264BitstreamParser::ParseBitstream(
      buffer, arraysize(buffer), &bitstream_parser_state,
      /* add_checksum */ true);
  // fuzzer::conv: end

  EXPECT_TRUE(bitstream != nullptr);

  // check there are 4 NAL units
  EXPECT_EQ(4, bitstream->nal_units.size());

  // check the 1st NAL unit
  int index = 0;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xac, 0x71, 0x1c, 0xb4}));

  // check the 2nd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x64, 0x6f, 0xbd, 0xfd}));

  // check the 3rd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x12, 0x27, 0x07, 0x3d}));

  // check the 4th NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(2, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_NON_IDR_PICTURE_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xce, 0x5c, 0x77, 0xf2}));
}

TEST_F(H264BitstreamParserTest, TestSampleBitstream601Alt) {
  // init the BitstreamParserState
  bool add_offset = true;
  bool add_length = true;
  bool add_parsed_length = true;
  bool add_checksum = true;
  auto bitstream = H264BitstreamParser::ParseBitstream(
      buffer, arraysize(buffer), add_offset, add_length, add_parsed_length,
      add_checksum);
  EXPECT_TRUE(bitstream != nullptr);

  // check there are 4 NAL units
  EXPECT_EQ(4, bitstream->nal_units.size());

  // check the NAL unit locations
  int length = 0;
  int counter = 0;
  // 1st NAL unit
  int index = 0;
  length = 24;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(22, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xac, 0x71, 0x1c, 0xb4}));
  index += 1;
  counter += length;
  // 2nd NAL unit
  length = 6;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(6, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x64, 0x6f, 0xbd, 0xfd}));
  index += 1;
  counter += length;
  // 3rd NAL unit
  length = 22;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(5, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x12, 0x27, 0x07, 0x3d}));
  index += 1;
  counter += length;
  // 4th NAL unit
  length = 7;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(5, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xce, 0x5c, 0x77, 0xf2}));
  // index += 1;
  // counter += length;
}

}  // namespace h264nal
