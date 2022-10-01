/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_fua_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264RtpFuAParserTest : public ::testing::Test {
 public:
  H264RtpFuAParserTest() {}
  ~H264RtpFuAParserTest() override {}
};

TEST_F(H264RtpFuAParserTest, TestSampleStart) {
  // FU (Aggregation Packet) containing the start of an
  // CODED_SLICE_OF_IDR_PICTURE_NUT.

  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x7c,  // rtp nal_header
    0x85,  // fu_header
    0x88, 0x82, 0x06, 0x78, 0x8c, 0x50, 0x00
  };
  // fuzzer::conv: begin
  // get some mock state
  H264BitstreamParserState bitstream_parser_state;
  auto sps = std::make_shared<H264SpsParser::SpsState>();
  sps->sps_data = std::make_unique<H264SpsDataParser::SpsDataState>();
  sps->sps_data->log2_max_frame_num_minus4 = 1;
  sps->sps_data->frame_mbs_only_flag = 1;
  sps->sps_data->pic_order_cnt_type = 2;
  sps->sps_data->delta_pic_order_always_zero_flag = 0;
  sps->sps_data->pic_width_in_mbs_minus1 = 0;
  sps->sps_data->pic_height_in_map_units_minus1 = 0;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<H264PpsParser::PpsState>();
  pps->bottom_field_pic_order_in_frame_present_flag = 0;
  pps->redundant_pic_cnt_present_flag = 0;
  pps->weighted_pred_flag = 0;
  pps->weighted_bipred_idc = 0;
  pps->entropy_coding_mode_flag = 0;
  pps->deblocking_filter_control_present_flag = 1;
  pps->num_slice_groups_minus1 = 0;
  pps->slice_group_map_type = 0;
  pps->slice_group_change_rate_minus1 = 0;
  ;
  bitstream_parser_state.pps[0] = pps;

  uint32_t nal_ref_idc = 3;
  auto rtp_fua = H264RtpFuAParser::ParseRtpFuA(
      buffer, arraysize(buffer), nal_ref_idc, &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_fua != nullptr);

  // check the common header
  auto& header = rtp_fua->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(3, header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_FUA_NUT, header->nal_unit_type);

  // check the fu header
  EXPECT_EQ(1, rtp_fua->s_bit);
  EXPECT_EQ(0, rtp_fua->e_bit);
  EXPECT_EQ(0, rtp_fua->r_bit);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT, rtp_fua->fu_type);

  // check some values
  auto& slice_header =
      rtp_fua->nal_unit_payload->slice_layer_without_partitioning_rbsp
          ->slice_header;
  EXPECT_TRUE(slice_header != nullptr);
  EXPECT_EQ(0, slice_header->first_mb_in_slice);
  EXPECT_EQ(7, slice_header->slice_type);
}

TEST_F(H264RtpFuAParserTest, TestSampleMiddle) {
  // FU (Aggregation Packet) containing the middle of an
  // CODED_SLICE_OF_IDR_PICTURE_NUT.

  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x7c,  // rtp nal_header
    0x05,  // fu_header
    0x1c, 0xab, 0x8e, 0x00, 0x02, 0xfb, 0x31, 0xc0
  };
  uint32_t nal_ref_idc = 3;
  H264BitstreamParserState bitstream_parser_state;
  auto rtp_fua = H264RtpFuAParser::ParseRtpFuA(
      buffer, arraysize(buffer), nal_ref_idc, &bitstream_parser_state);

  EXPECT_TRUE(rtp_fua != nullptr);

  // check the common header
  auto& header = rtp_fua->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(3, header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_FUA_NUT, header->nal_unit_type);

  // check the fu header
  EXPECT_EQ(0, rtp_fua->s_bit);
  EXPECT_EQ(0, rtp_fua->e_bit);
  EXPECT_EQ(0, rtp_fua->r_bit);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT, rtp_fua->fu_type);
}

TEST_F(H264RtpFuAParserTest, TestSampleEnd) {
  // FU (Aggregation Packet) containing the end of an
  // CODED_SLICE_OF_IDR_PICTURE_NUT.

  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x7c,  // rtp nal_header
    0x45,  // fu_header
    0x00, 0x5f, 0x66, 0xfb, 0xef, 0xbe
  };
  H264BitstreamParserState bitstream_parser_state;
  uint32_t nal_ref_idc = 3;
  auto rtp_fua = H264RtpFuAParser::ParseRtpFuA(
      buffer, arraysize(buffer), nal_ref_idc, &bitstream_parser_state);

  EXPECT_TRUE(rtp_fua != nullptr);

  // check the common header
  auto& header = rtp_fua->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(3, header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::RTP_FUA_NUT, header->nal_unit_type);

  // check the fu header
  EXPECT_EQ(0, rtp_fua->s_bit);
  EXPECT_EQ(1, rtp_fua->e_bit);
  EXPECT_EQ(0, rtp_fua->r_bit);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT, rtp_fua->fu_type);
}

}  // namespace h264nal
