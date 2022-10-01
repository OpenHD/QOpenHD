/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_slice_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_nal_unit_parser.h"
#include "h265_pps_parser.h"
#include "h265_sps_parser.h"
#include "h265_vps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SliceSegmentLayerParserTest : public ::testing::Test {
 public:
  H265SliceSegmentLayerParserTest() {}
  ~H265SliceSegmentLayerParserTest() override {}
};

TEST_F(H265SliceSegmentLayerParserTest, TestSampleSlice) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xaf, 0x09, 0x40, 0xf3, 0xb8, 0xd5, 0x39, 0xba,
      0x1f, 0xe4, 0xa6, 0x08, 0x5c, 0x6e, 0xb1, 0x8f,
      0x00, 0x38, 0xf1, 0xa6, 0xfc, 0xf1, 0x40, 0x04,
      0x3a, 0x86, 0xcb, 0x90, 0x74, 0xce, 0xf0, 0x46,
      0x61, 0x93, 0x72, 0xd6, 0xfc, 0x35, 0xe3, 0xc5
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

  auto slice_segment_layer =
      H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
          buffer, arraysize(buffer), NalUnitType::IDR_W_RADL,
          &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(slice_segment_layer != nullptr);

  auto& slice_segment_header = slice_segment_layer->slice_segment_header;

  EXPECT_EQ(1, slice_segment_header->first_slice_segment_in_pic_flag);
  EXPECT_EQ(0, slice_segment_header->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, slice_segment_header->slice_pic_parameter_set_id);
  EXPECT_EQ(2, slice_segment_header->slice_type);
  EXPECT_EQ(1, slice_segment_header->slice_sao_luma_flag);
  EXPECT_EQ(1, slice_segment_header->slice_sao_chroma_flag);
  EXPECT_EQ(9, slice_segment_header->slice_qp_delta);

#if 0
  EXPECT_EQ(1, slice_segment_header->alignment_bit_equal_to_one);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
#endif
}

TEST_F(H265SliceSegmentLayerParserTest, TestSampleSlice2) {
  const uint8_t buffer[] = {
      0x26, 0x01, 0x20, 0xf3, 0xc3, 0x5c, 0xfd, 0xfe,
      0xd6, 0x25, 0xbc, 0x0d, 0xb1, 0xfa, 0x81, 0x63,
      0xde, 0x0a, 0xc4, 0xa7, 0xea, 0x42, 0x89, 0xb6,
      0x1e, 0xbb, 0x5e, 0x3f, 0xfd, 0x6c, 0x8a, 0x2d
  };

  // get some mock state
  H265BitstreamParserState bitstream_parser_state;
  auto vps = std::make_shared<H265VpsParser::VpsState>();
  bitstream_parser_state.vps[0] = vps;
  auto sps = std::make_shared<H265SpsParser::SpsState>();
  sps->sample_adaptive_offset_enabled_flag = 1;
  sps->chroma_format_idc = 1;
  sps->log2_min_luma_coding_block_size_minus3 = 0;
  sps->log2_diff_max_min_luma_coding_block_size = 2;
  sps->pic_width_in_luma_samples = 1280;
  sps->pic_height_in_luma_samples = 736;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<H265PpsParser::PpsState>();
  bitstream_parser_state.pps[0] = pps;

  auto slice_segment_layer =
      H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
          buffer, arraysize(buffer), NalUnitType::IDR_W_RADL,
          &bitstream_parser_state);
  EXPECT_TRUE(slice_segment_layer != nullptr);

  auto& slice_segment_header = slice_segment_layer->slice_segment_header;

  EXPECT_EQ(0, slice_segment_header->first_slice_segment_in_pic_flag);
  EXPECT_EQ(0, slice_segment_header->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, slice_segment_header->slice_pic_parameter_set_id);
  EXPECT_EQ(192, slice_segment_header->slice_segment_address);
  EXPECT_EQ(3, slice_segment_header->slice_type);
  EXPECT_EQ(1, slice_segment_header->slice_sao_luma_flag);
  EXPECT_EQ(0, slice_segment_header->slice_sao_chroma_flag);
  EXPECT_EQ(15, slice_segment_header->slice_qp_delta);

#if 0
  EXPECT_EQ(1, slice_segment_header->alignment_bit_equal_to_one);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
  EXPECT_EQ(0, slice_segment_header->alignment_bit_equal_to_zero);
#endif
}

TEST_F(H265SliceSegmentLayerParserTest, TestSampleSlicePpsId15) {
  const uint8_t buffer[] = {
			0x02, 0x01, 0xd2, 0x78, 0xf7, 0x55, 0xdc, 0xbf,
			0x2c, 0x44, 0x00, 0x41, 0xa8, 0xd1, 0x66, 0x44,
			0xb3, 0x12, 0x93, 0xbc, 0x96, 0x54, 0x62, 0x42,
			0x53, 0xee, 0xd6, 0x14, 0x3a, 0xf4, 0x39, 0xfd,
			0x9a, 0x61, 0x28, 0xe2, 0x52, 0x7b, 0x50, 0x48,
			0x4d, 0x1c, 0xe3, 0xc5, 0x63, 0xe6, 0x7d, 0xa5,
			0xb0, 0x87, 0xd4, 0x5f, 0x8a, 0x07, 0x4d, 0x99,
			0x40, 0xcc, 0xe6, 0x21, 0xe3, 0x48, 0xc0, 0x06,
			0x33, 0x2c, 0x0c, 0x04, 0x77, 0x39, 0x22, 0xb6,
			0x7b, 0xe1, 0x40, 0x59, 0xec, 0x19, 0x04, 0xfc,
			0x9a, 0xa5, 0x3f, 0x3a, 0x80, 0x5a, 0x62, 0x3d,
			0xcf, 0xc1, 0x38, 0xe3, 0x8c, 0xed, 0xf1, 0x44,
			0xa8, 0x54, 0xe9, 0x16, 0xf1, 0x22, 0x7b, 0x86,
			0x3a, 0x8a, 0x7f, 0x9b, 0xac, 0x64, 0xe6, 0xa2,
			0xd7, 0x0f, 0x3d, 0x6e, 0xe8, 0xc2, 0x0d, 0xa7,
			0x48, 0xbd, 0x55, 0x53, 0x71, 0x89, 0x8b, 0x82,
			0x59, 0x5c, 0xce, 0x18, 0x1e, 0xa5, 0x9f, 0xcd,
			0x1a, 0xdd, 0x1e, 0x81, 0x69, 0x3d, 0x2d, 0x2d,
			0xb2, 0xab, 0x29, 0xdc, 0xdf, 0x65, 0x28, 0x48,
			0x34, 0x46, 0x01, 0x56, 0xdd, 0xae, 0x93, 0x19,
  };

  // get some mock state
  H265BitstreamParserState bitstream_parser_state;
  auto vps = std::make_shared<H265VpsParser::VpsState>();
  bitstream_parser_state.vps[0] = vps;
  auto sps = std::make_shared<H265SpsParser::SpsState>();
  sps->sample_adaptive_offset_enabled_flag = 1;
  sps->chroma_format_idc = 1;
  sps->log2_min_luma_coding_block_size_minus3 = 0;
  sps->log2_diff_max_min_luma_coding_block_size = 2;
  sps->pic_width_in_luma_samples = 1280;
  sps->pic_height_in_luma_samples = 736;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<H265PpsParser::PpsState>();
  bitstream_parser_state.pps[15] = pps;

  auto slice_segment_layer =
      H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
          buffer, arraysize(buffer), NalUnitType::IDR_W_RADL,
          &bitstream_parser_state);
  ASSERT_TRUE(slice_segment_layer != nullptr);

  // invalid slice_segment_header
  auto& slice_segment_header = slice_segment_layer->slice_segment_header;
  ASSERT_TRUE(slice_segment_header != nullptr);
  EXPECT_EQ(19, slice_segment_header->nal_unit_type);
}

TEST_F(H265SliceSegmentLayerParserTest, TestSliceContainsShortTermRefPicSet) {
  const uint8_t vps[] = {
      0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
      0x00, 0x00, 0x03, 0x00, 0xb0, 0x00, 0x00, 0x03,
      0x00, 0x00, 0x03, 0x00, 0x96, 0x70, 0x20, 0x00
  };
  const uint8_t sps[] = {
      0x42, 0x01, 0x01, 0x01, 0x60, 0x00, 0x00, 0x03,
      0x00, 0xb0, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
      0x00, 0x96, 0xa0, 0x05, 0x82, 0x00, 0x50, 0x16,
      0x20, 0x5e, 0xe4, 0x59, 0x14, 0xbf, 0xf2, 0xe7,
      0xf1, 0x3f, 0xa9, 0xb8, 0x10, 0x00, 0x00, 0x00
  };
  const uint8_t pps[] = {
      0x44, 0x01, 0xc0, 0x72, 0xf0, 0x53, 0x24
  };
  H265BitstreamParserState bitstream_parser_state;
  H265NalUnitParser::ParseNalUnit(vps, arraysize(vps), &bitstream_parser_state);
  H265NalUnitParser::ParseNalUnit(sps, arraysize(sps), &bitstream_parser_state);
  H265NalUnitParser::ParseNalUnit(pps, arraysize(pps), &bitstream_parser_state);
  // check the parsing went well
  ASSERT_EQ(1, bitstream_parser_state.vps.size());
  ASSERT_TRUE(bitstream_parser_state.vps.find(0) !=
              bitstream_parser_state.vps.end());
  ASSERT_EQ(1, bitstream_parser_state.sps.size());
  ASSERT_TRUE(bitstream_parser_state.sps.find(0) !=
              bitstream_parser_state.sps.end());
  ASSERT_EQ(1, bitstream_parser_state.pps.size());
  ASSERT_TRUE(bitstream_parser_state.pps.find(0) !=
              bitstream_parser_state.pps.end());

  const uint8_t slice[] = {
      0x02, 0x01, 0xd0, 0x53, 0x17, 0x62, 0x0a, 0x05,
      0x02, 0x70, 0x34, 0x38, 0x56, 0x0e, 0xc3, 0x48,
      0x7c, 0xbf, 0x9d, 0xaa, 0xe5, 0x51, 0x8c, 0x8b,
      0x40, 0x91, 0xbd, 0x9e, 0x49, 0x95, 0x1a, 0x61,
      0x90, 0x6f, 0x42, 0x25, 0x19, 0x50, 0xe6, 0xfb,
      0x5d, 0x4f, 0x12, 0x72, 0x44, 0xdc, 0x6c, 0x96,
      0x0a, 0xbd, 0x7e, 0x87, 0x60, 0xc0,
  };
  auto result = H265NalUnitParser::ParseNalUnit(slice, arraysize(slice),
                                                &bitstream_parser_state);

  ASSERT_TRUE(result != nullptr);
  ASSERT_TRUE(result->nal_unit_payload != nullptr);
  ASSERT_TRUE(result->nal_unit_payload->slice_segment_layer != nullptr);

  auto& slice_segment_header =
      result->nal_unit_payload->slice_segment_layer->slice_segment_header;
  ASSERT_TRUE(slice_segment_header != nullptr);

  EXPECT_EQ(39, slice_segment_header->num_entry_point_offsets);
}

}  // namespace h265nal
