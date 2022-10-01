/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_single_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <vector>

#include "h265_common.h"
#include "h265_utils.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265RtpSingleParserTest : public ::testing::Test {
 public:
  H265RtpSingleParserTest() {}
  ~H265RtpSingleParserTest() override {}
};

TEST_F(H265RtpSingleParserTest, TestSampleVps) {
  // VPS for a 1280x720 camera capture.
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
                            0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
                            0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x59, 0x00};
  // fuzzer::conv: begin
  H265BitstreamParserState bitstream_parser_state;
  auto rtp_single = H265RtpSingleParser::ParseRtpSingle(
      buffer, arraysize(buffer), &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_single != nullptr);

  // check the header
  EXPECT_EQ(0, rtp_single->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::VPS_NUT, rtp_single->nal_unit_header->nal_unit_type);
  EXPECT_EQ(0, rtp_single->nal_unit_header->nuh_layer_id);
  EXPECT_EQ(1, rtp_single->nal_unit_header->nuh_temporal_id_plus1);
}

TEST_F(H265RtpSingleParserTest, TestMultipleRtpPackets) {
  std::vector<std::vector<uint8_t>> vbuffer = {
      // VPS for a 1280x720 camera capture.
      {
          0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
          0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
          0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x59, 0x00
      },
      // SPS
      {
          0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
          0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
          0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
          0x13, 0x96, 0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82,
          0x83, 0x03, 0x01, 0x76, 0x85, 0x09, 0x40, 0x00
      },
      // PPS
      {
          0x44, 0x01, 0xc0, 0xf3, 0xc0, 0x02, 0x10, 0x00
      },
      // slice
      {
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
      },
  };
  H265BitstreamParserState bitstream_parser_state;
  // parse packets one-by-one
  int i = 0;
  for (const auto &buffer : vbuffer) {
    auto rtp_single = H265RtpSingleParser::ParseRtpSingle(
        buffer.data(), buffer.size(), &bitstream_parser_state);
    EXPECT_TRUE(rtp_single != nullptr);

    // check the header
    auto &header = rtp_single->nal_unit_header;
    auto &payload = rtp_single->nal_unit_payload;

    if (i == 0) {  // VPS
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(NalUnitType::VPS_NUT, header->nal_unit_type);
      EXPECT_EQ(0, header->nuh_layer_id);
      EXPECT_EQ(1, header->nuh_temporal_id_plus1);

    } else if (i == 1) {  // SPS
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(NalUnitType::SPS_NUT, header->nal_unit_type);
      EXPECT_EQ(0, header->nuh_layer_id);
      EXPECT_EQ(1, header->nuh_temporal_id_plus1);
      // check some values
      auto &sps = payload->sps;
      EXPECT_EQ(1280, sps->pic_width_in_luma_samples);
      EXPECT_EQ(736, sps->pic_height_in_luma_samples);
      auto sps_id = sps->sps_seq_parameter_set_id;
      EXPECT_EQ(1280,
                bitstream_parser_state.sps[sps_id]->pic_width_in_luma_samples);
      EXPECT_EQ(736,
                bitstream_parser_state.sps[sps_id]->pic_height_in_luma_samples);

    } else if (i == 2) {  // PPS
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(NalUnitType::PPS_NUT, header->nal_unit_type);
      EXPECT_EQ(0, header->nuh_layer_id);
      EXPECT_EQ(1, header->nuh_temporal_id_plus1);
      // check some values
      auto &pps = payload->pps;
      EXPECT_EQ(0, pps->init_qp_minus26);
      auto pps_id = pps->pps_pic_parameter_set_id;
      EXPECT_EQ(0, bitstream_parser_state.pps[pps_id]->init_qp_minus26);

    } else if (i == 3) {  // slice
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(NalUnitType::IDR_W_RADL, header->nal_unit_type);
      EXPECT_EQ(0, header->nuh_layer_id);
      EXPECT_EQ(1, header->nuh_temporal_id_plus1);
      // check some values
      auto &slice_header = payload->slice_segment_layer->slice_segment_header;
      EXPECT_EQ(9, slice_header->slice_qp_delta);
      auto pps_id = slice_header->slice_pic_parameter_set_id;
      EXPECT_EQ(0, bitstream_parser_state.pps[pps_id]->init_qp_minus26);
    }

    i += 1;
  }
}

}  // namespace h265nal
