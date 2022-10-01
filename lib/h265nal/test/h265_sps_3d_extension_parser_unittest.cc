/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_3d_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265Sps3dExtensionParserTest : public ::testing::Test {
 public:
  H265Sps3dExtensionParserTest() {}
  ~H265Sps3dExtensionParserTest() override {}
};

TEST_F(H265Sps3dExtensionParserTest, TestSampleSps3dExtension) {
  // sps_3d_extension
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xff, 0xff};
  // fuzzer::conv: begin
  auto sps_3d_extension =
      H265Sps3dExtensionParser::ParseSps3dExtension(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(sps_3d_extension != nullptr);

  EXPECT_THAT(sps_3d_extension->iv_di_mc_enabled_flag,
              ::testing::ElementsAreArray({1, 1}));
  EXPECT_THAT(sps_3d_extension->iv_mv_scal_enabled_flag,
              ::testing::ElementsAreArray({1, 1}));
  EXPECT_EQ(0, sps_3d_extension->log2_ivmc_sub_pb_size_minus3);
  EXPECT_EQ(1, sps_3d_extension->iv_res_pred_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->depth_ref_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->vsp_mc_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->dbbp_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->tex_mc_enabled_flag);
  EXPECT_EQ(0, sps_3d_extension->log2_texmc_sub_pb_size_minus3);
  EXPECT_EQ(1, sps_3d_extension->intra_contour_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->intra_dc_only_wedge_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->cqt_cu_part_pred_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->inter_dc_only_enabled_flag);
  EXPECT_EQ(1, sps_3d_extension->skip_intra_enabled_flag);
}

}  // namespace h265nal
