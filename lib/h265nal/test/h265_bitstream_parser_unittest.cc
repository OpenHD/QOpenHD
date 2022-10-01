/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_bitstream_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_utils.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265BitstreamParserTest : public ::testing::Test {
 public:
  H265BitstreamParserTest() {}
  ~H265BitstreamParserTest() override {}
};

// VPS, SPS, PPS for a 1280x720 camera capture.
// fuzzer::conv: data
const uint8_t buffer[] = {
    // VPS
    0x00, 0x00, 0x00, 0x01,
    0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
    0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x59,
    // SPS
    0x00, 0x00, 0x00, 0x01,
    0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
    0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
    0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
    0x13, 0x96, 0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82,
    0x83, 0x03, 0x01, 0x76, 0x85, 0x09, 0x40,
    // PPS
    0x00, 0x00, 0x00, 0x01,
    0x44, 0x01, 0xc0, 0xf3, 0xc0, 0x02, 0x10,
    // slice
    0x00, 0x00, 0x00, 0x01,
    0x26, 0x01, 0xaf, 0x09, 0x40, 0xf3, 0xb8, 0xd5,
    0x39, 0xba, 0x1f, 0xe4, 0xa6, 0x08, 0x5c, 0x6e,
    0xb1, 0x8f, 0x00, 0x38, 0xf1, 0xa6, 0xfc, 0xf1,
    0x40, 0x04, 0x3a, 0x86, 0xcb, 0x90, 0x74, 0xce,
    0xf0, 0x46, 0x61, 0x93, 0x72, 0xd6, 0xfc, 0x35,
    0xe3, 0xc5, 0x6f, 0x0a, 0xc4, 0x9e, 0x27, 0xc4,
    0xdb, 0xe3, 0xfb, 0x38, 0x98, 0xd0, 0x8b, 0xd5,
    0xb9, 0xb9, 0x15, 0xb4, 0x92, 0x49, 0x97, 0xe5,
    0x3d, 0x36, 0x4d, 0x45, 0x32, 0x5c, 0xe6, 0x89,
    0x53, 0x76, 0xce, 0xbb, 0x83, 0xa1, 0x27, 0x35,
    0xfb, 0xf3, 0xc7, 0xd4, 0x85, 0x32, 0x37, 0x94,
    0x09, 0xec, 0x10
};

TEST_F(H265BitstreamParserTest, TestSampleBitstream) {
  // fuzzer::conv: begin
  // init the BitstreamParserState
  H265BitstreamParserState bitstream_parser_state;

  auto bitstream = H265BitstreamParser::ParseBitstream(
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
  EXPECT_EQ(NalUnitType::VPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xbf, 0xa2, 0x45, 0x94}));

  // check the 2nd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::SPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x00, 0x3d, 0xc2, 0x9d}));

  // check the 3rd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xfb, 0xfc, 0x2f, 0x0b}));

  // check the 4th NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x6c, 0x88, 0x0c, 0xe4}));
}

TEST_F(H265BitstreamParserTest, TestSampleBitstreamAlt) {
  // init the BitstreamParserState
  bool add_offset = true;
  bool add_length = true;
  bool add_parsed_length = true;
  bool add_checksum = true;
  auto bitstream = H265BitstreamParser::ParseBitstream(
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
  length = 0x17;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(20, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xbf, 0xa2, 0x45, 0x94}));

  index += 1;
  counter += length;
  // 2nd NAL unit
  length = 0x27;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(36, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x00, 0x3d, 0xc2, 0x9d}));
  index += 1;
  counter += length;
  // 3rd NAL unit
  length = 0x7;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(7, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xfb, 0xfc, 0x2f, 0x0b}));
  index += 1;
  counter += length;
  // 4th NAL unit
  length = 0x5b;
  counter += 4;
  EXPECT_EQ(counter, bitstream->nal_units[index]->offset);
  EXPECT_EQ(length, bitstream->nal_units[index]->length);
  EXPECT_EQ(5, bitstream->nal_units[index]->parsed_length);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x6c, 0x88, 0x0c, 0xe4}));
  // index += 1;
  // counter += length;
}

// VPS, SPS, PPS for a 1280x720 camera capture.
// fuzzer::conv: data
const uint8_t buffer0[] = {
    // VPS
    0x00, 0x00, 0x00, 0x01,
    0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
    0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x59,
    // SPS
    0x00, 0x00, 0x00, 0x01,
    0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
    0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
    0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
    0x13, 0x96, 0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82,
    0x83, 0x03, 0x01, 0x76, 0x85, 0x09, 0x40,
    // PPS
    0x00, 0x00, 0x00, 0x01,
    0x44, 0x01, 0xc0, 0xf3, 0xc0, 0x02, 0x10,
    // slice (IDR)
    0x00, 0x00, 0x00, 0x01,
    0x26, 0x01, 0xaf, 0x09, 0x40, 0xfb, 0x27, 0x5b,
    0xfd, 0x5d, 0xc2, 0x4d, 0xe8, 0xb2, 0x0f, 0xcd,
    0x68, 0xdb, 0xc3, 0x41, 0x12, 0x2e, 0x13, 0x8d,
    0xdf, 0x66, 0xc9, 0x1f, 0xaa, 0xd4, 0x9b, 0x8d,
    0xdd, 0xe2, 0xa1, 0xda, 0x2e, 0xbd, 0x53, 0x74,
    0xd1, 0xbb, 0xde, 0x54, 0x8f, 0xa5, 0xe7, 0x2f,
    0xcc, 0xf7, 0x98, 0xd6, 0x33, 0xd5, 0x06, 0x01,
    0x52, 0x84, 0xbc, 0xa7, 0xe6, 0x02, 0x7f, 0xe9,
    0x50, 0x0a, 0x9a, 0x60, 0x89, 0xa0, 0xc0, 0xb4,
    0x6d, 0x60, 0x53, 0xe5, 0xdd, 0x93, 0xde, 0x03,
    0xff, 0xa8, 0xb0, 0x4d, 0x27, 0xa5, 0x82, 0xba,
    0xac, 0x63, 0x8b, 0x6f, 0x69, 0x7f, 0x93, 0xb2,
    0xe3, 0x0c, 0xfd, 0x29, 0x44, 0x42, 0xa7, 0x13,
    0xe9, 0xec, 0x37, 0xbb, 0x93, 0xe0, 0x62, 0xa9,
    0xa4, 0x44, 0x45, 0x59, 0x16, 0xf6, 0xb6, 0x5b,
    0x3a, 0xdb, 0xc3
};

// P-frame
// fuzzer::conv: data
const uint8_t buffer1[] = {
    // slice (P-frame)
    0x00, 0x00, 0x00, 0x01,
    0x02, 0x01, 0xd0, 0x0f, 0xe4, 0x16, 0x80, 0xf4,
    0x5a, 0xb4, 0x85, 0x6b, 0x17, 0xaa, 0xc1, 0x94,
    0xa8, 0x9f, 0x32, 0x11, 0xe4, 0x44, 0xa5, 0xfd,
    0xe7, 0x80, 0xda, 0xea, 0x21, 0x4c, 0x08, 0x23,
    0xea, 0x58, 0x15, 0xa3, 0x4c, 0x1a, 0xb3, 0x80,
    0x9b, 0x63, 0x50, 0x11, 0x75, 0x9a, 0xcc, 0x06,
    0x09, 0x69, 0x97, 0x75, 0xa0, 0x02, 0x24, 0x22,
    0x1c, 0x06, 0xa5, 0x69, 0x6e, 0xba, 0x9c, 0x79,
    0x58, 0x1e, 0x52, 0xa8, 0x26, 0xfe, 0x98, 0x6f,
    0x65, 0xee, 0x57, 0x10, 0x4f, 0x67, 0xe8, 0x43,
    0xde, 0x8e, 0xe6, 0x40, 0x28, 0x36, 0x45, 0x06,
    0x5e, 0xe8, 0x80, 0x34, 0xc0, 0x06, 0xf2, 0x16,
    0x4b, 0x78, 0x5f, 0x98, 0x56, 0xcc, 0xd9, 0x59,
    0x7a, 0xf3, 0x30, 0x5d, 0xa9, 0xc7, 0x84, 0x4a,
    0xe0, 0x16, 0xbf, 0x07, 0x24, 0x32, 0x65, 0xbd,
    0x39, 0xe2, 0x30, 0xbf, 0x27, 0xd3, 0x61, 0x25,
    0x02, 0xae, 0x5a, 0xa1, 0x08, 0x9b, 0x90, 0x14,
    0x2a, 0x09, 0xd1, 0x4a
};

// P-frame
// fuzzer::conv: data
const uint8_t buffer2[] = {
    // slice (P-frame)
    0x00, 0x00, 0x00, 0x01,
    0x02, 0x01, 0xd0, 0x17, 0xe4, 0x08, 0x20, 0xfc,
    0xc1, 0xf5, 0x88, 0x40, 0xcf, 0xf0, 0x00, 0x00,
    0x03, 0x00, 0x05, 0xe0, 0x46, 0x9d, 0x90, 0xa1,
    0x98, 0x43, 0x28, 0x48, 0xe9, 0xc6, 0xf3, 0x11,
    0xeb, 0x29, 0x19, 0xcd, 0x34, 0x85, 0x8b, 0xc5,
    0x21, 0xf5, 0x5a, 0x46, 0xd7, 0x5a, 0xa5, 0x34,
    0xa6, 0xad, 0x91, 0xd6, 0x5e, 0x71, 0x18, 0x94,
    0xe9, 0x44, 0x2a, 0x84, 0x04, 0x2c, 0x80, 0xb0,
    0xb4, 0x03, 0xf0, 0xa0, 0xe6, 0xe6, 0x14, 0xb3,
    0xf2, 0xfa, 0x57, 0x5e, 0x29, 0xd1, 0xe1, 0x4d,
    0x9b, 0x17, 0xea, 0xf8, 0x5c, 0xd5, 0x0a, 0x72,
    0xe6, 0x5e, 0x42, 0xed, 0xdd, 0xbe, 0x64, 0x38,
    0x04, 0x5d, 0x84, 0xc7, 0x02, 0xb0, 0x50, 0x21,
    0x3f, 0x02, 0x89, 0x83
};

TEST_F(H265BitstreamParserTest, TestMultipleBuffers) {
  // init the BitstreamParserState
  H265BitstreamParserState bitstream_parser_state;

  // 0. parse buffer0
  auto bitstream = H265BitstreamParser::ParseBitstream(
      buffer0, arraysize(buffer0), &bitstream_parser_state,
      /* add_checksum */ true);
  EXPECT_TRUE(bitstream != nullptr);

  // check there are 4 NAL units
  EXPECT_EQ(4, bitstream->nal_units.size());

  // check the 1st NAL unit
  int index = 0;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::VPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xbf, 0xa2, 0x45, 0x94}));

  // check the 2nd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::SPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x00, 0x3d, 0xc2, 0x9d}));

  // check the 3rd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xfb, 0xfc, 0x2f, 0x0b}));

  // check the 4th NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x09, 0x54, 0xa9, 0x47}));

  // 1. parse buffer1
  bitstream = H265BitstreamParser::ParseBitstream(buffer1, arraysize(buffer1),
                                                  &bitstream_parser_state,
                                                  /* add_checksum */ true);
  EXPECT_TRUE(bitstream != nullptr);

  // check there is 1 NAL units
  EXPECT_EQ(1, bitstream->nal_units.size());

  // check the 1st NAL unit
  index = 0;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::TRAIL_R,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0xd9, 0xbf, 0xa1, 0xe8}));

  // 2. parse buffer2
  bitstream = H265BitstreamParser::ParseBitstream(buffer2, arraysize(buffer2),
                                                  &bitstream_parser_state,
                                                  /* add_checksum */ true);
  EXPECT_TRUE(bitstream != nullptr);

  // check there is 1 NAL units
  EXPECT_EQ(1, bitstream->nal_units.size());

  // check the 1st NAL unit
  index = 0;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::TRAIL_R,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, bitstream->nal_units[index]->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(
      1, bitstream->nal_units[index]->nal_unit_header->nuh_temporal_id_plus1);
  EXPECT_THAT(
      std::vector<char>(bitstream->nal_units[index]->checksum->GetChecksum(),
                        bitstream->nal_units[index]->checksum->GetChecksum() +
                            bitstream->nal_units[index]->checksum->GetLength()),
      ::testing::ElementsAreArray({0x82, 0x2a, 0xff, 0x1c}));
}

TEST_F(H265BitstreamParserTest, TestMultipleBuffersGetSliceQpY) {
  // init the BitstreamParserState
  H265BitstreamParserState bitstream_parser_state;

  // 0. parse buffer0
  std::vector<int32_t> slice_qp_y_vector = H265Utils::GetSliceQpY(
      buffer0, arraysize(buffer0), &bitstream_parser_state);
  // check there is 1 QP_Y value
  ASSERT_EQ(1, slice_qp_y_vector.size());
  // check the value is right
  EXPECT_EQ(35, slice_qp_y_vector[0]);

  // 1. parse buffer1
  slice_qp_y_vector = H265Utils::GetSliceQpY(buffer1, arraysize(buffer1),
                                             &bitstream_parser_state);
  // check there is 1 QP_Y value
  ASSERT_EQ(1, slice_qp_y_vector.size());
  // check the value is right
  EXPECT_EQ(37, slice_qp_y_vector[0]);

  // 2. parse buffer2
  slice_qp_y_vector = H265Utils::GetSliceQpY(buffer2, arraysize(buffer2),
                                             &bitstream_parser_state);
  // check there is 1 QP_Y value
  ASSERT_EQ(1, slice_qp_y_vector.size());
  // check the value is right
  EXPECT_EQ(42, slice_qp_y_vector[0]);
}

}  // namespace h265nal
