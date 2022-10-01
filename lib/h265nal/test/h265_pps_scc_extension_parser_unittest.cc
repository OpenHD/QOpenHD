/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_pps_scc_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265PpsSccExtensionParserTest : public ::testing::Test {
 public:
  H265PpsSccExtensionParserTest() {}
  ~H265PpsSccExtensionParserTest() override {}
};

TEST_F(H265PpsSccExtensionParserTest, TestSamplePpsSccExtension) {
  // pps_scc_extension
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x00};
  // fuzzer::conv: begin
  auto pps_scc_extension = H265PpsSccExtensionParser::ParsePpsSccExtension(
      buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(pps_scc_extension != nullptr);

  EXPECT_EQ(0, pps_scc_extension->pps_curr_pic_ref_enabled_flag);
  EXPECT_EQ(0,
            pps_scc_extension->residual_adaptive_colour_transform_enabled_flag);
  EXPECT_EQ(0,
            pps_scc_extension->pps_palette_predictor_initializer_present_flag);
  EXPECT_EQ(0, pps_scc_extension->pps_palette_predictor_initializers.size());
}

}  // namespace h265nal
