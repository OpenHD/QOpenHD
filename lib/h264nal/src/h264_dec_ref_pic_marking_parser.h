/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a decoded reference picture list marking
// (`dec_ref_pic_marking()`, as defined in Section 7.3.3.3 of the 2012
// standard) from an H264 NALU.
class H264DecRefPicMarkingParser {
 public:
  // The parsed state of the DecRefPicMarking.
  struct DecRefPicMarkingState {
    DecRefPicMarkingState() = default;
    ~DecRefPicMarkingState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    DecRefPicMarkingState(const DecRefPicMarkingState&) = delete;
    DecRefPicMarkingState(DecRefPicMarkingState&&) = delete;
    DecRefPicMarkingState& operator=(const DecRefPicMarkingState&) = delete;
    DecRefPicMarkingState& operator=(DecRefPicMarkingState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_unit_type = 0;

    // contents
    uint32_t no_output_of_prior_pics_flag = 0;
    uint32_t long_term_reference_flag = 0;
    uint32_t adaptive_ref_pic_marking_mode_flag = 0;
    std::vector<uint32_t> memory_management_control_operation;
    std::vector<uint32_t> difference_of_pic_nums_minus1;
    std::vector<uint32_t> long_term_pic_num;
    std::vector<uint32_t> long_term_frame_idx;
    std::vector<uint32_t> max_long_term_frame_idx_plus1;
  };

  // Unpack RBSP and parse DecRefPicMarking state from the supplied buffer.
  static std::unique_ptr<DecRefPicMarkingState> ParseDecRefPicMarking(
      const uint8_t* data, size_t length, uint32_t nal_unit_type) noexcept;
  static std::unique_ptr<DecRefPicMarkingState> ParseDecRefPicMarking(
      rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type) noexcept;
};

}  // namespace h264nal
