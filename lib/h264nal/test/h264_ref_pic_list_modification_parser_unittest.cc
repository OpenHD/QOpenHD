/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_ref_pic_list_modification_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_common.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264RefPicListModificationParserTest : public ::testing::Test {
 public:
  H264RefPicListModificationParserTest() {}
  ~H264RefPicListModificationParserTest() override {}
};

TEST_F(H264RefPicListModificationParserTest,
       TestSampleRefPicListModification601NonIDR) {
  // ref_pic_list_modification
  // fuzzer::conv: data
  const uint8_t buffer[] = {0x00};
  // fuzzer::conv: begin
  uint32_t slice_type = SliceType::P_ALL;
  auto ref_pic_list_modification =
      H264RefPicListModificationParser::ParseRefPicListModification(
          buffer, arraysize(buffer), slice_type);
  // fuzzer::conv: end

  EXPECT_TRUE(ref_pic_list_modification != nullptr);

  EXPECT_EQ(0, ref_pic_list_modification->ref_pic_list_modification_flag_l0);
}

}  // namespace h264nal
