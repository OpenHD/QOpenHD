/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_vui_parameters_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264VuiParametersParserTest : public ::testing::Test {
 public:
  H264VuiParametersParserTest() {}
  ~H264VuiParametersParserTest() override {}
};

TEST_F(H264VuiParametersParserTest, TestSampleVuiParameters601) {
  // VUI (601.264)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x36, 0x40, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00,
      0x0c, 0x83, 0xc5, 0x8b, 0x84, 0x60
  };
  // fuzzer::conv: begin
  auto vui_parameters =
      H264VuiParametersParser::ParseVuiParameters(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(vui_parameters != nullptr);

  EXPECT_EQ(0, vui_parameters->aspect_ratio_info_present_flag);
  EXPECT_EQ(0, vui_parameters->overscan_info_present_flag);
  EXPECT_EQ(1, vui_parameters->video_signal_type_present_flag);
  EXPECT_EQ(5, vui_parameters->video_format);
  EXPECT_EQ(1, vui_parameters->video_full_range_flag);
  EXPECT_EQ(0, vui_parameters->colour_description_present_flag);
  EXPECT_EQ(0, vui_parameters->chroma_loc_info_present_flag);
  EXPECT_EQ(1, vui_parameters->timing_info_present_flag);
  EXPECT_EQ(1, vui_parameters->num_units_in_tick);
  EXPECT_EQ(50, vui_parameters->time_scale);
  EXPECT_EQ(0, vui_parameters->fixed_frame_rate_flag);
  EXPECT_EQ(0, vui_parameters->nal_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->vcl_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->pic_struct_present_flag);
  EXPECT_EQ(1, vui_parameters->bitstream_restriction_flag);
  EXPECT_EQ(1, vui_parameters->motion_vectors_over_pic_boundaries_flag);
  EXPECT_EQ(0, vui_parameters->max_bytes_per_pic_denom);
  EXPECT_EQ(0, vui_parameters->max_bits_per_mb_denom);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_horizontal);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_vertical);
  EXPECT_EQ(0, vui_parameters->max_num_reorder_frames);
  EXPECT_EQ(16, vui_parameters->max_dec_frame_buffering);
}

TEST_F(H264VuiParametersParserTest, TestSampleVuiParameters601vui) {
  // VUI (601vui.264)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x37, 0x06, 0x06, 0x06, 0x40, 0x00, 0x00, 0x00,
      0x40, 0x00, 0x00, 0x0c, 0x83, 0xc5, 0x8b, 0x84,
      0x60, 0x00
  };
  // fuzzer::conv: begin
  auto vui_parameters =
      H264VuiParametersParser::ParseVuiParameters(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(vui_parameters != nullptr);

  EXPECT_EQ(0, vui_parameters->aspect_ratio_info_present_flag);
  EXPECT_EQ(0, vui_parameters->overscan_info_present_flag);
  EXPECT_EQ(1, vui_parameters->video_signal_type_present_flag);
  EXPECT_EQ(5, vui_parameters->video_format);
  EXPECT_EQ(1, vui_parameters->video_full_range_flag);
  EXPECT_EQ(1, vui_parameters->colour_description_present_flag);
  EXPECT_EQ(6, vui_parameters->colour_primaries);
  EXPECT_EQ(6, vui_parameters->transfer_characteristics);
  EXPECT_EQ(6, vui_parameters->matrix_coefficients);
  EXPECT_EQ(0, vui_parameters->chroma_loc_info_present_flag);
  EXPECT_EQ(1, vui_parameters->timing_info_present_flag);
  EXPECT_EQ(1, vui_parameters->num_units_in_tick);
  EXPECT_EQ(50, vui_parameters->time_scale);
  EXPECT_EQ(0, vui_parameters->fixed_frame_rate_flag);
  EXPECT_EQ(0, vui_parameters->nal_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->vcl_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->pic_struct_present_flag);
  EXPECT_EQ(1, vui_parameters->bitstream_restriction_flag);
  EXPECT_EQ(1, vui_parameters->motion_vectors_over_pic_boundaries_flag);
  EXPECT_EQ(0, vui_parameters->max_bytes_per_pic_denom);
  EXPECT_EQ(0, vui_parameters->max_bits_per_mb_denom);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_horizontal);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_vertical);
  EXPECT_EQ(0, vui_parameters->max_num_reorder_frames);
  EXPECT_EQ(16, vui_parameters->max_dec_frame_buffering);
}

TEST_F(H264VuiParametersParserTest, TestSampleVuiParameters709) {
  // VUI (709.264)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x37, 0x01, 0x01, 0x01, 0x40, 0x00, 0x00, 0x00,
      0x40, 0x00, 0x00, 0x0c, 0x83, 0xc5, 0x8b, 0x84,
      0x60, 0x00
  };
  // fuzzer::conv: begin
  auto vui_parameters =
      H264VuiParametersParser::ParseVuiParameters(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(vui_parameters != nullptr);

  EXPECT_EQ(0, vui_parameters->aspect_ratio_info_present_flag);
  EXPECT_EQ(0, vui_parameters->overscan_info_present_flag);
  EXPECT_EQ(1, vui_parameters->video_signal_type_present_flag);
  EXPECT_EQ(5, vui_parameters->video_format);
  EXPECT_EQ(1, vui_parameters->video_full_range_flag);
  EXPECT_EQ(1, vui_parameters->colour_description_present_flag);
  EXPECT_EQ(1, vui_parameters->colour_primaries);
  EXPECT_EQ(1, vui_parameters->transfer_characteristics);
  EXPECT_EQ(1, vui_parameters->matrix_coefficients);
  EXPECT_EQ(0, vui_parameters->chroma_loc_info_present_flag);
  EXPECT_EQ(1, vui_parameters->timing_info_present_flag);
  EXPECT_EQ(1, vui_parameters->num_units_in_tick);
  EXPECT_EQ(50, vui_parameters->time_scale);
  EXPECT_EQ(0, vui_parameters->fixed_frame_rate_flag);
  EXPECT_EQ(0, vui_parameters->nal_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->vcl_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->pic_struct_present_flag);
  EXPECT_EQ(1, vui_parameters->bitstream_restriction_flag);
  EXPECT_EQ(1, vui_parameters->motion_vectors_over_pic_boundaries_flag);
  EXPECT_EQ(0, vui_parameters->max_bytes_per_pic_denom);
  EXPECT_EQ(0, vui_parameters->max_bits_per_mb_denom);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_horizontal);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_vertical);
  EXPECT_EQ(0, vui_parameters->max_num_reorder_frames);
  EXPECT_EQ(16, vui_parameters->max_dec_frame_buffering);
}

TEST_F(H264VuiParametersParserTest, TestSampleVuiParameters709vui) {
  // VUI (709vui.264)
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x37, 0x01, 0x01, 0x01, 0x40, 0x00, 0x00, 0x00,
      0x40, 0x00, 0x00, 0x0c, 0x83, 0xc5, 0x8b, 0x84,
      0x60, 0x00
  };
  // fuzzer::conv: begin
  auto vui_parameters =
      H264VuiParametersParser::ParseVuiParameters(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(vui_parameters != nullptr);

  EXPECT_EQ(0, vui_parameters->aspect_ratio_info_present_flag);
  EXPECT_EQ(0, vui_parameters->overscan_info_present_flag);
  EXPECT_EQ(1, vui_parameters->video_signal_type_present_flag);
  EXPECT_EQ(5, vui_parameters->video_format);
  EXPECT_EQ(1, vui_parameters->video_full_range_flag);
  EXPECT_EQ(1, vui_parameters->colour_description_present_flag);
  EXPECT_EQ(1, vui_parameters->colour_primaries);
  EXPECT_EQ(1, vui_parameters->transfer_characteristics);
  EXPECT_EQ(1, vui_parameters->matrix_coefficients);
  EXPECT_EQ(0, vui_parameters->chroma_loc_info_present_flag);
  EXPECT_EQ(1, vui_parameters->timing_info_present_flag);
  EXPECT_EQ(1, vui_parameters->num_units_in_tick);
  EXPECT_EQ(50, vui_parameters->time_scale);
  EXPECT_EQ(0, vui_parameters->fixed_frame_rate_flag);
  EXPECT_EQ(0, vui_parameters->nal_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->vcl_hrd_parameters_present_flag);
  EXPECT_EQ(0, vui_parameters->pic_struct_present_flag);
  EXPECT_EQ(1, vui_parameters->bitstream_restriction_flag);
  EXPECT_EQ(1, vui_parameters->motion_vectors_over_pic_boundaries_flag);
  EXPECT_EQ(0, vui_parameters->max_bytes_per_pic_denom);
  EXPECT_EQ(0, vui_parameters->max_bits_per_mb_denom);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_horizontal);
  EXPECT_EQ(10, vui_parameters->log2_max_mv_length_vertical);
  EXPECT_EQ(0, vui_parameters->max_num_reorder_frames);
  EXPECT_EQ(16, vui_parameters->max_dec_frame_buffering);
}

}  // namespace h264nal
