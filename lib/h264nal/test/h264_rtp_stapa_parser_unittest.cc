/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_stapa_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264RtpStapAParserTest : public ::testing::Test {
 public:
  H264RtpStapAParserTest() {}
  ~H264RtpStapAParserTest() override {}
};

TEST_F(H264RtpStapAParserTest, TestSampleAUD) {
  // STAP-A (Aggregation Packet) containing PPS, SPS
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      // STAP-A header
      0x78,
      // NALU 1 size
      0x00, 0x18,
      // NALU 1 (SPS)
      0x67, 0x42, 0xc0, 0x16, 0xa6, 0x11, 0x05, 0x07,
      0xe9, 0xb2, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00,
      0x00, 0x03, 0x00, 0x64, 0x1e, 0x2c, 0x5c, 0x23,
      // NALU 2 size
      0x00, 0x05,
      // NALU 2 (PPS)
      0x68, 0xc8, 0x42, 0x02, 0x32, 0xc8
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto rtp_stapa = H264RtpStapAParser::ParseRtpStapA(buffer, arraysize(buffer),
                                                     &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_stapa != nullptr);

  // check the common header
  auto& header = rtp_stapa->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(3, header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_STAPA_NUT, header->nal_unit_type);

  // check there are 2 valid NAL units
  EXPECT_EQ(2, rtp_stapa->nal_unit_sizes.size());
  EXPECT_EQ(2, rtp_stapa->nal_unit_headers.size());
  EXPECT_EQ(2, rtp_stapa->nal_unit_payloads.size());

  // check the types
  EXPECT_EQ(NalUnitType::SPS_NUT,
            rtp_stapa->nal_unit_headers[0]->nal_unit_type);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            rtp_stapa->nal_unit_headers[1]->nal_unit_type);

  // check the parser state
}

}  // namespace h264nal
