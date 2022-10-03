/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_nal_unit_header_svc_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264NalUnitHeaderSvcExtensionParserTest : public ::testing::Test {
 public:
  H264NalUnitHeaderSvcExtensionParserTest() {}
  ~H264NalUnitHeaderSvcExtensionParserTest() override {}
};

TEST_F(H264NalUnitHeaderSvcExtensionParserTest,
       TestNalUnitHeaderSvcExtension01) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xff, 0xff, 0xff};
  // fuzzer::conv: begin
  auto nal_unit_header_svc_extension =
      H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
          buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(nal_unit_header_svc_extension != nullptr);

  // check the values
  EXPECT_EQ(1, nal_unit_header_svc_extension->idr_flag);
  EXPECT_EQ(63, nal_unit_header_svc_extension->priority_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->no_inter_layer_pred_flag);
  EXPECT_EQ(7, nal_unit_header_svc_extension->dependency_id);
  EXPECT_EQ(15, nal_unit_header_svc_extension->quality_id);
  EXPECT_EQ(7, nal_unit_header_svc_extension->temporal_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->use_ref_base_pic_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->discardable_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->output_flag);
  EXPECT_EQ(3, nal_unit_header_svc_extension->reserved_three_2bits);
}

TEST_F(H264NalUnitHeaderSvcExtensionParserTest,
       TestNalUnitHeaderSvcExtensionForeman) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x81, 0x00, 0x2e};
  // fuzzer::conv: begin
  auto nal_unit_header_svc_extension =
      H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
          buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(nal_unit_header_svc_extension != nullptr);

  // check the values
  EXPECT_EQ(1, nal_unit_header_svc_extension->idr_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->priority_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->no_inter_layer_pred_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->dependency_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->quality_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->temporal_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->use_ref_base_pic_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->discardable_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->output_flag);
  EXPECT_EQ(3, nal_unit_header_svc_extension->reserved_three_2bits);
}

}  // namespace h264nal
