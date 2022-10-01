/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_scc_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SpsSccExtensionParserTest : public ::testing::Test {
 public:
  H265SpsSccExtensionParserTest() {}
  ~H265SpsSccExtensionParserTest() override {}
};

TEST_F(H265SpsSccExtensionParserTest, TestSampleSpsSccExtension) {
  // sps_scc_extension
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x80};
  // fuzzer::conv: begin
  auto sps_scc_extension = H265SpsSccExtensionParser::ParseSpsSccExtension(
      buffer, arraysize(buffer), /* sps->chroma_format_idc */ 1,
      /* sps->bit_depth_luma_minus8 */ 0, /* sps->bit_depth_chroma_minus8 */ 0);
  // fuzzer::conv: end

  EXPECT_TRUE(sps_scc_extension != nullptr);

  EXPECT_EQ(1, sps_scc_extension->sps_curr_pic_ref_enabled_flag);
  EXPECT_EQ(0, sps_scc_extension->palette_mode_enabled_flag);
  EXPECT_EQ(0, sps_scc_extension->palette_max_size);
  EXPECT_EQ(0, sps_scc_extension->delta_palette_max_predictor_size);
  EXPECT_EQ(0,
            sps_scc_extension->sps_palette_predictor_initializers_present_flag);
  EXPECT_EQ(0,
            sps_scc_extension->sps_num_palette_predictor_initializers_minus1);
  EXPECT_EQ(0, sps_scc_extension->sps_palette_predictor_initializers.size());
  EXPECT_EQ(0, sps_scc_extension->motion_vector_resolution_control_idc);
  EXPECT_EQ(0, sps_scc_extension->intra_boundary_filtering_disabled_flag);
}

}  // namespace h265nal
