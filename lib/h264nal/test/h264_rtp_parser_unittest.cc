/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264RtpParserTest : public ::testing::Test {
 public:
  H264RtpParserTest() {}
  ~H264RtpParserTest() override {}
};

TEST_F(H264RtpParserTest, TestSampleSingle) {
  // Single NAL Unit Packet (SPS)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x67, 0x42, 0xc0, 0x16, 0xa6, 0x11, 0x05, 0x07,
      0xe9, 0xb2, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00,
      0x00, 0x03, 0x00, 0x64, 0x1e, 0x2c, 0x5c, 0x23,
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto rtp = H264RtpParser::ParseRtp(buffer, arraysize(buffer),
                                     &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp != nullptr);

  // check the header
  auto &header = rtp->nal_unit_header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(3, header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SPS_NUT, header->nal_unit_type);

  // check some values
  auto &rtp_single = rtp->rtp_single;
  auto &sps = rtp_single->nal_unit_payload->sps;
  EXPECT_EQ(66, sps->sps_data->profile_idc);
  EXPECT_EQ(19, sps->sps_data->pic_width_in_mbs_minus1);
  EXPECT_EQ(14, sps->sps_data->pic_height_in_map_units_minus1);
  auto sps_id = sps->sps_data->seq_parameter_set_id;
  EXPECT_EQ(66, bitstream_parser_state.sps[sps_id]->sps_data->profile_idc);
  EXPECT_EQ(19, bitstream_parser_state.sps[sps_id]->sps_data->pic_width_in_mbs_minus1);
  EXPECT_EQ(14,
            bitstream_parser_state.sps[sps_id]->sps_data->pic_height_in_map_units_minus1);
}

TEST_F(H264RtpParserTest, TestSampleApAndFu) {
  // STAP-A (Aggregation Packet) containing PPS, SPS
  // fuzzer::conv: data
  const uint8_t buffer1[] = {
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
  H264BitstreamParserState bitstream_parser_state;
  auto rtp = H264RtpParser::ParseRtp(buffer1, arraysize(buffer1),
                                     &bitstream_parser_state);

  EXPECT_TRUE(rtp != nullptr);

  // check the common header
  auto &stapa_header = rtp->nal_unit_header;
  // also: auto &stapa_header = rtp->rtp_stapa->header;
  EXPECT_EQ(0, stapa_header->forbidden_zero_bit);
  EXPECT_EQ(3, stapa_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_STAPA_NUT, stapa_header->nal_unit_type);

  // check there are 2 valid NAL units
  auto &rtp_stapa = rtp->rtp_stapa;
  EXPECT_EQ(2, rtp_stapa->nal_unit_sizes.size());
  EXPECT_EQ(2, rtp_stapa->nal_unit_headers.size());
  EXPECT_EQ(2, rtp_stapa->nal_unit_payloads.size());

  // check the types
  EXPECT_EQ(NalUnitType::SPS_NUT,
            rtp_stapa->nal_unit_headers[0]->nal_unit_type);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            rtp_stapa->nal_unit_headers[1]->nal_unit_type);

  // FU-A (Aggregation Packet) containing the start of an
  // CODED_SLICE_OF_IDR_PICTURE_NUT.

  const uint8_t buffer2[] = {
      0x7c,  // rtp nal_header
      0x85,  // fu_header
      0x88, 0x82, 0x06, 0x78, 0x8c, 0x50, 0x00
  };
  rtp = H264RtpParser::ParseRtp(buffer2, arraysize(buffer2),
                                &bitstream_parser_state);
  EXPECT_TRUE(rtp != nullptr);

  // check the main header
  auto &fua_header = rtp->nal_unit_header;
  // also: auto &fua_header = rtp->rtp_fua->header;
  EXPECT_EQ(0, fua_header->forbidden_zero_bit);
  EXPECT_EQ(3, fua_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_FUA_NUT, fua_header->nal_unit_type);

  // check the fu header
  auto &rtp_fua = rtp->rtp_fua;
  EXPECT_EQ(1, rtp_fua->s_bit);
  EXPECT_EQ(0, rtp_fua->e_bit);
  EXPECT_EQ(0, rtp_fua->r_bit);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT, rtp_fua->fu_type);

  // check some values
  auto &slice_header =
      rtp_fua->nal_unit_payload->slice_layer_without_partitioning_rbsp
          ->slice_header;
  EXPECT_EQ(0, slice_header->first_mb_in_slice);
  EXPECT_EQ(7, slice_header->slice_type);
}

}  // namespace h264nal
