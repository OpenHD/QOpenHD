/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_prefix_nal_unit_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "h264_nal_unit_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264PrefixNalUnitRbspParserTest : public ::testing::Test {
 public:
  H264PrefixNalUnitRbspParserTest() {}
  ~H264PrefixNalUnitRbspParserTest() override {}
};

TEST_F(H264PrefixNalUnitRbspParserTest, TestPrefixNalUnitParser01) {
  // foreman.svc.264
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x20
  };
  // fuzzer::conv: begin
  uint32_t svc_extension_flag = 1;
  uint32_t nal_ref_idc = 2;
  uint32_t use_ref_base_pic_flag = 1;
  uint32_t idr_flag = 1;
  auto prefix_nal_unit_rbsp =
      H264PrefixNalUnitRbspParser::ParsePrefixNalUnitRbsp(
          buffer, arraysize(buffer), svc_extension_flag, nal_ref_idc,
          use_ref_base_pic_flag, idr_flag);
  // fuzzer::conv: end

  EXPECT_TRUE(prefix_nal_unit_rbsp != nullptr);

  // prefix_nal_unit_svc()
  auto& prefix_nal_unit_svc = prefix_nal_unit_rbsp->prefix_nal_unit_svc;
  EXPECT_TRUE(prefix_nal_unit_svc != nullptr);

  EXPECT_EQ(0, prefix_nal_unit_svc->store_ref_base_pic_flag);
  EXPECT_EQ(0, prefix_nal_unit_svc->additional_prefix_nal_unit_extension_flag);
  EXPECT_EQ(
      0, prefix_nal_unit_svc->additional_prefix_nal_unit_extension_data_flag);
}

TEST_F(H264PrefixNalUnitRbspParserTest, TestSampleNalUnit01) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x6e, 0xc0, 0x80, 0x0f
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto nal_unit = H264NalUnitParser::ParseNalUnit(buffer, arraysize(buffer),
                                                  &bitstream_parser_state,
                                                  /* add checksum */ true);
  // fuzzer::conv: end

  ASSERT_TRUE(nal_unit != nullptr);

  // check the parsed length
  EXPECT_EQ(4, nal_unit->parsed_length);

  // check the header
  auto& nal_unit_header = nal_unit->nal_unit_header;
  ASSERT_TRUE(nal_unit_header != nullptr);
  EXPECT_EQ(0, nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::PREFIX_NUT, nal_unit_header->nal_unit_type);
  EXPECT_EQ(1, nal_unit_header->svc_extension_flag);
  EXPECT_EQ(0, nal_unit_header->avc_3d_extension_flag);

  // check the nal_unit_header_svc_extension
  auto& nal_unit_header_svc_extension =
      nal_unit_header->nal_unit_header_svc_extension;
  ASSERT_TRUE(nal_unit_header_svc_extension != nullptr);
  EXPECT_EQ(1, nal_unit_header_svc_extension->idr_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->priority_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->no_inter_layer_pred_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->dependency_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->quality_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->temporal_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->use_ref_base_pic_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->discardable_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->output_flag);
  EXPECT_EQ(3, nal_unit_header_svc_extension->reserved_three_2bits);

  // check the payload
  auto& nal_unit_payload = nal_unit->nal_unit_payload;
  ASSERT_TRUE(nal_unit_payload != nullptr);

  // check prefix_nal_unit_rbsp
  auto& prefix_nal_unit = nal_unit->nal_unit_payload->prefix_nal_unit;
  ASSERT_TRUE(prefix_nal_unit == nullptr);
}

TEST_F(H264PrefixNalUnitRbspParserTest, TestSampleNalUnit01Fixed) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x6e, 0xc0, 0x80, 0x0f, 0xff
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto nal_unit = H264NalUnitParser::ParseNalUnit(buffer, arraysize(buffer),
                                                  &bitstream_parser_state,
                                                  /* add checksum */ true);
  // fuzzer::conv: end

  ASSERT_TRUE(nal_unit != nullptr);

  // check the parsed length
  EXPECT_EQ(5, nal_unit->parsed_length);

  // check the header
  auto& nal_unit_header = nal_unit->nal_unit_header;
  ASSERT_TRUE(nal_unit_header != nullptr);
  EXPECT_EQ(0, nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::PREFIX_NUT, nal_unit_header->nal_unit_type);
  EXPECT_EQ(1, nal_unit_header->svc_extension_flag);
  EXPECT_EQ(0, nal_unit_header->avc_3d_extension_flag);

  // check the nal_unit_header_svc_extension
  auto& nal_unit_header_svc_extension =
      nal_unit_header->nal_unit_header_svc_extension;
  ASSERT_TRUE(nal_unit_header_svc_extension != nullptr);
  EXPECT_EQ(1, nal_unit_header_svc_extension->idr_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->priority_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->no_inter_layer_pred_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->dependency_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->quality_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->temporal_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->use_ref_base_pic_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->discardable_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->output_flag);
  EXPECT_EQ(3, nal_unit_header_svc_extension->reserved_three_2bits);

  // check the payload
  auto& nal_unit_payload = nal_unit->nal_unit_payload;
  ASSERT_TRUE(nal_unit_payload != nullptr);

  // check prefix_nal_unit_rbsp
  auto& prefix_nal_unit = nal_unit->nal_unit_payload->prefix_nal_unit;
  ASSERT_TRUE(prefix_nal_unit != nullptr);

  // incomplete NALU means prefix_nal_unit_svc() is empty
  auto& prefix_nal_unit_svc = prefix_nal_unit->prefix_nal_unit_svc;
  ASSERT_TRUE(prefix_nal_unit_svc != nullptr);
  EXPECT_EQ(3, prefix_nal_unit_svc->nal_ref_idc);
  EXPECT_EQ(0, prefix_nal_unit_svc->use_ref_base_pic_flag);
  EXPECT_EQ(1, prefix_nal_unit_svc->idr_flag);
  EXPECT_EQ(1, prefix_nal_unit_svc->store_ref_base_pic_flag);
  EXPECT_EQ(1, prefix_nal_unit_svc->additional_prefix_nal_unit_extension_flag);
  EXPECT_EQ(1,
      prefix_nal_unit_svc->additional_prefix_nal_unit_extension_data_flag);
}

}  // namespace h264nal
