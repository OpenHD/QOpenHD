/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_sps_svc_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264SpsSvcExtensionParserTest : public ::testing::Test {
 public:
  H264SpsSvcExtensionParserTest() {}
  ~H264SpsSvcExtensionParserTest() override {}
};

TEST_F(H264SpsSvcExtensionParserTest, TestSampleSpsSvcExtension01) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xff,
  };
  // fuzzer::conv: begin
  uint32_t ChromaArrayType = 0;
  auto sps_svc_extension = H264SpsSvcExtensionParser::ParseSpsSvcExtension(
      buffer, arraysize(buffer), ChromaArrayType);
  // fuzzer::conv: end

  EXPECT_TRUE(sps_svc_extension != nullptr);

  EXPECT_EQ(
      1, sps_svc_extension->inter_layer_deblocking_filter_control_present_flag);
  EXPECT_EQ(3, sps_svc_extension->extended_spatial_scalability_idc);
  EXPECT_EQ(1, sps_svc_extension->seq_tcoeff_level_prediction_flag);
  EXPECT_EQ(1, sps_svc_extension->slice_header_restriction_flag);
}

TEST_F(H264SpsSvcExtensionParserTest, TestSampleSpsSvcExtension02) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0xff, 0xff,
  };
  // fuzzer::conv: begin
  uint32_t ChromaArrayType = 1;
  auto sps_svc_extension = H264SpsSvcExtensionParser::ParseSpsSvcExtension(
      buffer, arraysize(buffer), ChromaArrayType);
  // fuzzer::conv: end

  EXPECT_TRUE(sps_svc_extension != nullptr);

  EXPECT_EQ(
      1, sps_svc_extension->inter_layer_deblocking_filter_control_present_flag);
  EXPECT_EQ(3, sps_svc_extension->extended_spatial_scalability_idc);
  EXPECT_EQ(1, sps_svc_extension->chroma_phase_x_plus1_flag);
  EXPECT_EQ(3, sps_svc_extension->chroma_phase_y_plus1);
  EXPECT_EQ(0, sps_svc_extension->seq_scaled_ref_layer_left_offset);
  EXPECT_EQ(0, sps_svc_extension->seq_scaled_ref_layer_top_offset);
  EXPECT_EQ(0, sps_svc_extension->seq_scaled_ref_layer_right_offset);
  EXPECT_EQ(0, sps_svc_extension->seq_scaled_ref_layer_bottom_offset);
  EXPECT_EQ(1, sps_svc_extension->seq_tcoeff_level_prediction_flag);
  EXPECT_EQ(1, sps_svc_extension->slice_header_restriction_flag);
}

TEST_F(H264SpsSvcExtensionParserTest, TestSampleSpsSvcExtension03) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x81, 0x20
  };
  // fuzzer::conv: begin
  uint32_t ChromaArrayType = 1;
  auto sps_svc_extension = H264SpsSvcExtensionParser::ParseSpsSvcExtension(
      buffer, arraysize(buffer), ChromaArrayType);
  // fuzzer::conv: end

  EXPECT_TRUE(sps_svc_extension != nullptr);

  EXPECT_EQ(
      1, sps_svc_extension->inter_layer_deblocking_filter_control_present_flag);
  EXPECT_EQ(0, sps_svc_extension->extended_spatial_scalability_idc);
  EXPECT_EQ(0, sps_svc_extension->chroma_phase_x_plus1_flag);
  EXPECT_EQ(0, sps_svc_extension->chroma_phase_y_plus1);
  EXPECT_EQ(0, sps_svc_extension->seq_tcoeff_level_prediction_flag);
  EXPECT_EQ(1, sps_svc_extension->slice_header_restriction_flag);
}

}  // namespace h264nal
