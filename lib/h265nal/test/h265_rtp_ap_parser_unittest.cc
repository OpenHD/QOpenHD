/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_ap_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265RtpApParserTest : public ::testing::Test {
 public:
  H265RtpApParserTest() {}
  ~H265RtpApParserTest() override {}
};

TEST_F(H265RtpApParserTest, TestSampleAUD) {
  // AP (Aggregation Packet) containing VPS, PPS, SPS
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      // AP header
      0x60, 0x01,
      // NALU 1 size
      0x00, 0x17,
      // NALU 1 (VPS)
      0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60, 0x00, 0x00, 0x03, 0x00,
      0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x09,
      // NALU 2 size
      0x00, 0x27,
      // NALU 2 (SPS)
      0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00,
      0x03, 0x00, 0x00, 0x03, 0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
      0x13, 0x96, 0xbb, 0x93, 0x24, 0xba, 0x94, 0x82, 0x81, 0x01, 0x01, 0x76,
      0x85, 0x09, 0x40,
      // NALU 3 size
      0x00, 0x0a,
      // NALU 3 (PPS)
      0x44, 0x01, 0xc0, 0xe2, 0x4f, 0x09, 0x41, 0xec, 0x10, 0x80};
  // fuzzer::conv: begin
  H265BitstreamParserState bitstream_parser_state;
  auto rtp_ap = H265RtpApParser::ParseRtpAp(buffer, arraysize(buffer),
                                            &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_ap != nullptr);

  // check the common header
  auto& header = rtp_ap->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::AP, header->nal_unit_type);
  EXPECT_EQ(0, header->nuh_layer_id);
  EXPECT_EQ(1, header->nuh_temporal_id_plus1);

  // check there are 3 valid NAL units
  EXPECT_EQ(3, rtp_ap->nal_unit_sizes.size());
  EXPECT_EQ(3, rtp_ap->nal_unit_headers.size());
  EXPECT_EQ(3, rtp_ap->nal_unit_payloads.size());

  // check the types
  EXPECT_EQ(NalUnitType::VPS_NUT, rtp_ap->nal_unit_headers[0]->nal_unit_type);
  EXPECT_EQ(NalUnitType::SPS_NUT, rtp_ap->nal_unit_headers[1]->nal_unit_type);
  EXPECT_EQ(NalUnitType::PPS_NUT, rtp_ap->nal_unit_headers[2]->nal_unit_type);

  // check the parser state
}

}  // namespace h265nal
