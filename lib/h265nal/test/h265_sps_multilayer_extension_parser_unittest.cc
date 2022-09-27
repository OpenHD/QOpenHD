/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_multilayer_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265SpsMultilayerExtensionParserTest : public ::testing::Test {
 public:
  H265SpsMultilayerExtensionParserTest() {}
  ~H265SpsMultilayerExtensionParserTest() override {}
};

TEST_F(H265SpsMultilayerExtensionParserTest, TestSampleSpsMultilayerExtension) {
  // sps_multilayer_extension
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xff};
  // fuzzer::conv: begin
  auto sps_multilayer_extension =
      H265SpsMultilayerExtensionParser::ParseSpsMultilayerExtension(
          buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(sps_multilayer_extension != nullptr);

  EXPECT_EQ(1, sps_multilayer_extension->inter_view_mv_vert_constraint_flag);
}

}  // namespace h265nal
