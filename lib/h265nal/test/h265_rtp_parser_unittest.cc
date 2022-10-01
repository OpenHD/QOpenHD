/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "h265_utils.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265RtpParserTest : public ::testing::Test {
 public:
  H265RtpParserTest() {}
  ~H265RtpParserTest() override {}
};

TEST_F(H265RtpParserTest, TestSampleSingle) {
  // Single NAL Unit Packet (SPS for a 1280x736 camera capture).
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
      0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
      0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
      0x13, 0x96, 0xbb, 0x93, 0x24, 0xbb, 0x95, 0x82,
      0x83, 0x03, 0x01, 0x76, 0x85, 0x09, 0x40
  };
  // fuzzer::conv: begin
  H265BitstreamParserState bitstream_parser_state;
  auto rtp = H265RtpParser::ParseRtp(buffer, arraysize(buffer),
                                     &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp != nullptr);

  // check the header
  auto &header = rtp->nal_unit_header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::SPS_NUT, header->nal_unit_type);
  EXPECT_EQ(0, header->nuh_layer_id);
  EXPECT_EQ(1, header->nuh_temporal_id_plus1);

  // check some values
  auto &rtp_single = rtp->rtp_single;
  auto &sps = rtp_single->nal_unit_payload->sps;
  EXPECT_EQ(1280, sps->pic_width_in_luma_samples);
  EXPECT_EQ(736, sps->pic_height_in_luma_samples);
  auto sps_id = sps->sps_seq_parameter_set_id;
  EXPECT_EQ(1280,
            bitstream_parser_state.sps[sps_id]->pic_width_in_luma_samples);
  EXPECT_EQ(736,
            bitstream_parser_state.sps[sps_id]->pic_height_in_luma_samples);
}

TEST_F(H265RtpParserTest, TestSampleApAndFu) {
  // AP (Aggregation Packet) containing VPS, PPS, SPS
  // fuzzer::conv: data
  const uint8_t buffer1[] = {
      // AP header
      0x60, 0x01,
      // NALU 1 size
      0x00, 0x17,
      // NALU 1 (VPS)
      0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
      0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
      0x00, 0x00, 0x03, 0x00, 0x5d, 0xac, 0x09,
      // NALU 2 size
      0x00, 0x27,
      // NALU 2 (SPS)
      0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
      0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
      0x00, 0x5d, 0xa0, 0x02, 0x80, 0x80, 0x2e, 0x1f,
      0x13, 0x96, 0xbb, 0x93, 0x24, 0xba, 0x94, 0x82,
      0x81, 0x01, 0x01, 0x76, 0x85, 0x09, 0x40,
      // NALU 3 size
      0x00, 0x0a,
      // NALU 3 (PPS)
      0x44, 0x01, 0xc0, 0xe2, 0x4f, 0x09, 0x41, 0xec,
      0x10, 0x80
  };
  H265BitstreamParserState bitstream_parser_state;
  auto rtp = H265RtpParser::ParseRtp(buffer1, arraysize(buffer1),
                                     &bitstream_parser_state);

  EXPECT_TRUE(rtp != nullptr);

  // check the common header
  auto &ap_header = rtp->nal_unit_header;
  // also: auto &ap_header = rtp->rtp_ap->header;
  EXPECT_EQ(0, ap_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::AP, ap_header->nal_unit_type);
  EXPECT_EQ(0, ap_header->nuh_layer_id);
  EXPECT_EQ(1, ap_header->nuh_temporal_id_plus1);

  // check there are 3 valid NAL units
  auto &rtp_ap = rtp->rtp_ap;
  EXPECT_EQ(3, rtp_ap->nal_unit_sizes.size());
  EXPECT_EQ(3, rtp_ap->nal_unit_headers.size());
  EXPECT_EQ(3, rtp_ap->nal_unit_payloads.size());

  // check the types
  EXPECT_EQ(NalUnitType::VPS_NUT, rtp_ap->nal_unit_headers[0]->nal_unit_type);
  EXPECT_EQ(NalUnitType::SPS_NUT, rtp_ap->nal_unit_headers[1]->nal_unit_type);
  EXPECT_EQ(NalUnitType::PPS_NUT, rtp_ap->nal_unit_headers[2]->nal_unit_type);

  // check some values
  auto &sps = rtp_ap->nal_unit_payloads[1]->sps;
  EXPECT_EQ(1280, sps->pic_width_in_luma_samples);
  EXPECT_EQ(736, sps->pic_height_in_luma_samples);
  auto sps_id = sps->sps_seq_parameter_set_id;
  EXPECT_EQ(1280,
            bitstream_parser_state.sps[sps_id]->pic_width_in_luma_samples);
  EXPECT_EQ(736,
            bitstream_parser_state.sps[sps_id]->pic_height_in_luma_samples);
  auto &pps = rtp_ap->nal_unit_payloads[2]->pps;
  EXPECT_EQ(-4, pps->init_qp_minus26);
  auto pps_id = pps->pps_pic_parameter_set_id;
  EXPECT_EQ(-4, bitstream_parser_state.pps[pps_id]->init_qp_minus26);

  // FU (Aggregation Packet) containing the start of an IDR_W_RADL.
  const uint8_t buffer2[] = {
      0x62, 0x01, 0x93, 0xaf, 0x0d, 0x70, 0xfd, 0xf4,
      0x6e, 0xf0, 0x3c, 0x7e, 0x63, 0xc8, 0x15, 0xf5,
      0xf7, 0x6e, 0x52, 0x0f, 0xd3, 0xb5, 0x44, 0x61,
      0x58, 0x24, 0x68, 0xe0
  };
  rtp = H265RtpParser::ParseRtp(buffer2, arraysize(buffer2),
                                &bitstream_parser_state);
  EXPECT_TRUE(rtp != nullptr);

  // check the main header
  auto &fu_header = rtp->nal_unit_header;
  // also: auto &fu_header = rtp->rtp_fu->header;
  EXPECT_EQ(0, fu_header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::FU, fu_header->nal_unit_type);
  EXPECT_EQ(0, fu_header->nuh_layer_id);
  EXPECT_EQ(1, fu_header->nuh_temporal_id_plus1);

  // check the fu header
  auto &rtp_fu = rtp->rtp_fu;
  EXPECT_EQ(1, rtp_fu->s_bit);
  EXPECT_EQ(0, rtp_fu->e_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL, rtp_fu->fu_type);

  // check some values
  auto &slice_segment_header =
      rtp_fu->nal_unit_payload->slice_segment_layer->slice_segment_header;
  EXPECT_EQ(13, slice_segment_header->slice_qp_delta);

  auto slice_qpy = H265Utils::GetSliceQpY(rtp, &bitstream_parser_state);
  EXPECT_TRUE(slice_qpy != nullptr);
  EXPECT_EQ(35, *slice_qpy);
}

}  // namespace h265nal
