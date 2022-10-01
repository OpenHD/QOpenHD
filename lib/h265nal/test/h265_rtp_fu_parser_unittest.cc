/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_fu_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265RtpFuParserTest : public ::testing::Test {
 public:
  H265RtpFuParserTest() {}
  ~H265RtpFuParserTest() override {}
};

TEST_F(H265RtpFuParserTest, TestSampleStart) {
  // FU (Aggregation Packet) containing the start of an IDR_W_RADL.
  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x62, 0x01, 0x93, 0xaf, 0x0d, 0x70, 0xfd, 0xf4,
    0x6e, 0xf0, 0x3c, 0x7e, 0x63, 0xc8, 0x15, 0xf5,
    0xf7, 0x6e, 0x52, 0x0f, 0xd3, 0xb5, 0x44, 0x61,
    0x58, 0x24, 0x68, 0xe0
  };
  // fuzzer::conv: begin
  // get some mock state
  H265BitstreamParserState bitstream_parser_state;
  auto vps = std::make_shared<H265VpsParser::VpsState>();
  bitstream_parser_state.vps[0] = vps;
  auto sps = std::make_shared<H265SpsParser::SpsState>();
  sps->sample_adaptive_offset_enabled_flag = 1;
  sps->chroma_format_idc = 1;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<H265PpsParser::PpsState>();
  bitstream_parser_state.pps[0] = pps;

  auto rtp_fu = H265RtpFuParser::ParseRtpFu(buffer, arraysize(buffer),
                                            &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(rtp_fu != nullptr);

  // check the common header
  auto& header = rtp_fu->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::FU, header->nal_unit_type);
  EXPECT_EQ(0, header->nuh_layer_id);
  EXPECT_EQ(1, header->nuh_temporal_id_plus1);

  // check the fu header
  EXPECT_EQ(1, rtp_fu->s_bit);
  EXPECT_EQ(0, rtp_fu->e_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL, rtp_fu->fu_type);

  // check some values
  auto& nal_unit_payload = rtp_fu->nal_unit_payload;
  ASSERT_TRUE(nal_unit_payload != nullptr);

  auto& slice_segment_layer = nal_unit_payload->slice_segment_layer;
  ASSERT_TRUE(slice_segment_layer != nullptr);

  auto& slice_segment_header = slice_segment_layer->slice_segment_header;
  ASSERT_TRUE(slice_segment_header != nullptr);

  EXPECT_EQ(NalUnitType::IDR_W_RADL, slice_segment_header->nal_unit_type);
  EXPECT_EQ(1, slice_segment_header->first_slice_segment_in_pic_flag);
  EXPECT_EQ(0, slice_segment_header->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, slice_segment_header->slice_pic_parameter_set_id);
  EXPECT_EQ(2, slice_segment_header->slice_type);
}

TEST_F(H265RtpFuParserTest, TestSampleMiddle) {
  // FU (Aggregation Packet) containing the middle of an IDR_W_RADL.
  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x62, 0x01, 0x13, 0x8e, 0xaa, 0x12, 0xcc, 0xef,
    0x6a, 0xf6, 0xb0, 0x7b, 0x7a, 0xbf, 0xea, 0xf1,
    0x3c, 0xa7, 0x20, 0xe8, 0x05, 0x9a, 0xfe, 0x6b
  };
  H265BitstreamParserState bitstream_parser_state;
  auto rtp_fu = H265RtpFuParser::ParseRtpFu(buffer, arraysize(buffer),
                                            &bitstream_parser_state);

  EXPECT_TRUE(rtp_fu != nullptr);

  // check the common header
  auto& header = rtp_fu->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::FU, header->nal_unit_type);
  EXPECT_EQ(0, header->nuh_layer_id);
  EXPECT_EQ(1, header->nuh_temporal_id_plus1);

  // check the fu header
  EXPECT_EQ(0, rtp_fu->s_bit);
  EXPECT_EQ(0, rtp_fu->e_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL, rtp_fu->fu_type);
}

TEST_F(H265RtpFuParserTest, TestSampleEnd) {
  // FU (Aggregation Packet) containing the end of an IDR_W_RADL.
  // fuzzer::conv: data
  const uint8_t buffer[] = {
    0x62, 0x01, 0x53, 0x85, 0xfe, 0xde, 0xe8, 0x9c,
    0x2f, 0xd5, 0xed, 0xb9, 0x2c, 0xec, 0x8f, 0x08,
    0x5b, 0x95, 0x02, 0x79, 0xc3, 0xb7, 0x47, 0x16
  };
  H265BitstreamParserState bitstream_parser_state;
  auto rtp_fu = H265RtpFuParser::ParseRtpFu(buffer, arraysize(buffer),
                                            &bitstream_parser_state);

  EXPECT_TRUE(rtp_fu != nullptr);

  // check the common header
  auto& header = rtp_fu->header;
  EXPECT_EQ(0, header->forbidden_zero_bit);
  EXPECT_EQ(NalUnitType::FU, header->nal_unit_type);
  EXPECT_EQ(0, header->nuh_layer_id);
  EXPECT_EQ(1, header->nuh_temporal_id_plus1);

  // check the fu header
  EXPECT_EQ(0, rtp_fu->s_bit);
  EXPECT_EQ(1, rtp_fu->e_bit);
  EXPECT_EQ(NalUnitType::IDR_W_RADL, rtp_fu->fu_type);
}

}  // namespace h265nal
