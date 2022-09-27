/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_range_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SpsRangeExtensionParserTest : public ::testing::Test {
 public:
  H265SpsRangeExtensionParserTest() {}
  ~H265SpsRangeExtensionParserTest() override {}
};

TEST_F(H265SpsRangeExtensionParserTest, TestSampleSpsRangeExtension) {
  // sps_range_extension
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xaa, 0xaa};
  // fuzzer::conv: begin
  auto sps_range_extension =
      H265SpsRangeExtensionParser::ParseSpsRangeExtension(buffer,
                                                          arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(sps_range_extension != nullptr);

  EXPECT_EQ(1, sps_range_extension->transform_skip_rotation_enabled_flag);
  EXPECT_EQ(0, sps_range_extension->transform_skip_context_enabled_flag);
  EXPECT_EQ(1, sps_range_extension->implicit_rdpcm_enabled_flag);
  EXPECT_EQ(0, sps_range_extension->explicit_rdpcm_enabled_flag);
  EXPECT_EQ(1, sps_range_extension->extended_precision_processing_flag);
  EXPECT_EQ(0, sps_range_extension->intra_smoothing_disabled_flag);
  EXPECT_EQ(1, sps_range_extension->high_precision_offsets_enabled_flag);
  EXPECT_EQ(0, sps_range_extension->persistent_rice_adaptation_enabled_flag);
  EXPECT_EQ(1, sps_range_extension->cabac_bypass_alignment_enabled_flag);
}

}  // namespace h265nal
