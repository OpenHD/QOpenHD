/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_aud_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h265_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

class H265AudParserTest : public ::testing::Test {
 public:
  H265AudParserTest() {}
  ~H265AudParserTest() override {}
};

TEST_F(H265AudParserTest, TestSampleAUD) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {0xff};
  // fuzzer::conv: begin
  auto aud = H265AudParser::ParseAud(buffer, arraysize(buffer));
  // fuzzer::conv: end

  EXPECT_TRUE(aud != nullptr);

  EXPECT_EQ(7, aud->pic_type);
}

}  // namespace h265nal
