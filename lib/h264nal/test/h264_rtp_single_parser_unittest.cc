/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_single_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <vector>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264RtpSingleParserTest : public ::testing::Test {
 public:
  H264RtpSingleParserTest() {}
  ~H264RtpSingleParserTest() override {}
};

TEST_F(H264RtpSingleParserTest, TestSampleSps) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x67, 0x42, 0xc0, 0x16, 0xa6, 0x11, 0x05, 0x07,
      0xe9, 0xb2, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00,
      0x00, 0x03, 0x00, 0x64, 0x1e, 0x2c, 0x5c, 0x23,
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto rtp_single = H264RtpSingleParser::ParseRtpSingle(
      buffer, arraysize(buffer), &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_single != nullptr);

  // check the header
  EXPECT_EQ(0, rtp_single->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, rtp_single->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SPS_NUT, rtp_single->nal_unit_header->nal_unit_type);
}

TEST_F(H264RtpSingleParserTest, TestMultipleRtpPackets) {
  std::vector<std::vector<uint8_t>> vbuffer = {
      // SPS
      {
          0x67, 0x42, 0xc0, 0x16, 0xa6, 0x11, 0x05, 0x07,
          0xe9, 0xb2, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00,
          0x00, 0x03, 0x00, 0x64, 0x1e, 0x2c, 0x5c, 0x23,
      },
      // PPS
      {
          0x68, 0xc8, 0x42, 0x02, 0x32, 0xc8,
      },
      // slice_layer_without_partitioning
      {
          0x65, 0x88, 0x82, 0x06, 0x78, 0x8c, 0x50, 0x00,
          0x1c, 0xab, 0x8e, 0x00, 0x02, 0xfb, 0x31, 0xc0,
          0x00, 0x5f, 0x66, 0xfb, 0xef, 0xbe,
      },
  };
  H264BitstreamParserState bitstream_parser_state;
  // parse packets one-by-one
  int i = 0;
  for (const auto &buffer : vbuffer) {
    auto rtp_single = H264RtpSingleParser::ParseRtpSingle(
        buffer.data(), buffer.size(), &bitstream_parser_state);
    EXPECT_TRUE(rtp_single != nullptr);

    // check the header
    auto &header = rtp_single->nal_unit_header;
    auto &payload = rtp_single->nal_unit_payload;

    if (i == 0) {  // SPS
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(3, header->nal_ref_idc);
      EXPECT_EQ(NalUnitType::SPS_NUT, header->nal_unit_type);
      // check some values
      auto &sps = payload->sps;
      EXPECT_EQ(66, sps->sps_data->profile_idc);
      EXPECT_EQ(19, sps->sps_data->pic_width_in_mbs_minus1);
      EXPECT_EQ(14, sps->sps_data->pic_height_in_map_units_minus1);
      auto sps_id = sps->sps_data->seq_parameter_set_id;
      EXPECT_EQ(66, bitstream_parser_state.sps[sps_id]->sps_data->profile_idc);
      EXPECT_EQ(19, bitstream_parser_state.sps[sps_id]
                        ->sps_data->pic_width_in_mbs_minus1);
      EXPECT_EQ(14, bitstream_parser_state.sps[sps_id]
                        ->sps_data->pic_height_in_map_units_minus1);

    } else if (i == 1) {  // PPS
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(3, header->nal_ref_idc);
      EXPECT_EQ(NalUnitType::PPS_NUT, header->nal_unit_type);
      // check some values
      auto &pps = payload->pps;
      EXPECT_EQ(-8, pps->pic_init_qp_minus26);
      auto pps_id = pps->pic_parameter_set_id;
      EXPECT_EQ(-8, bitstream_parser_state.pps[pps_id]->pic_init_qp_minus26);

    } else if (i == 2) {  // slice
      // check the header
      EXPECT_EQ(0, header->forbidden_zero_bit);
      EXPECT_EQ(3, header->nal_ref_idc);
      EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT,
                header->nal_unit_type);
      // check some values
      auto &slice_header =
          payload->slice_layer_without_partitioning_rbsp->slice_header;
      EXPECT_EQ(-12, slice_header->slice_qp_delta);
      auto pps_id = slice_header->pic_parameter_set_id;
      EXPECT_EQ(-8, bitstream_parser_state.pps[pps_id]->pic_init_qp_minus26);
    }

    i += 1;
  }
}

}  // namespace h264nal
