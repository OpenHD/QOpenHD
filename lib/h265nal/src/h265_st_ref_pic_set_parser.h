/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a Short-term reference picture set syntax
// (`st_ref_pic_set()`, as defined in Section 7.3.7 of the 2016-12
// standard) from an H265 NALU.
class H265StRefPicSetParser {
 public:
  // The parsed state of the StRefPicSet.
  struct StRefPicSetState {
    StRefPicSetState() = default;
    ~StRefPicSetState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    StRefPicSetState(const StRefPicSetState&) = delete;
    StRefPicSetState(StRefPicSetState&&) = delete;
    StRefPicSetState& operator=(const StRefPicSetState&) = delete;
    StRefPicSetState& operator=(StRefPicSetState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t stRpsIdx = 0;
    uint32_t num_short_term_ref_pic_sets = 0;

    // contents
    uint32_t inter_ref_pic_set_prediction_flag = 0;
    uint32_t delta_idx_minus1 = 0;
    uint32_t delta_rps_sign = 0;
    uint32_t abs_delta_rps_minus1 = 0;
    std::vector<uint32_t> used_by_curr_pic_flag;
    std::vector<uint32_t> use_delta_flag;
    uint32_t num_negative_pics = 0;
    uint32_t num_positive_pics = 0;
    std::vector<uint32_t> delta_poc_s0_minus1;
    std::vector<uint32_t> used_by_curr_pic_s0_flag;
    std::vector<uint32_t> delta_poc_s1_minus1;
    std::vector<uint32_t> used_by_curr_pic_s1_flag;

    // helper functions
    void DeriveValues(
        const std::vector<std::unique_ptr<struct StRefPicSetState>>*
            st_ref_pic_set_state_vector,
        const uint32_t RefRpsIdx) noexcept;
  };

  // Unpack RBSP and parse StRefPicSet state from the supplied buffer.
  static std::unique_ptr<StRefPicSetState> ParseStRefPicSet(
      const uint8_t* data, size_t length, uint32_t stRpsIdx,
      uint32_t num_short_term_ref_pic_sets,
      const std::vector<std::unique_ptr<struct StRefPicSetState>>*
          st_ref_pic_set_state_vector,
      uint32_t max_num_pics) noexcept;
  static std::unique_ptr<StRefPicSetState> ParseStRefPicSet(
      rtc::BitBuffer* bit_buffer, uint32_t stRpsIdx,
      uint32_t num_short_term_ref_pic_sets,
      const std::vector<std::unique_ptr<struct StRefPicSetState>>*
          st_ref_pic_set_state_vector,
      uint32_t max_num_pics) noexcept;
};

}  // namespace h265nal
