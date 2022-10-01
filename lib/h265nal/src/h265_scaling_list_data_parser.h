/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a scaling list data syntax
// (`scaling_list_data()`, as defined in Section 7.3.4
// of the 2018-02 standard) from an H265 NALU.
class H265ScalingListDataParser {
 public:
  // The parsed state of the ScalingListData.
  struct ScalingListDataState {
    ScalingListDataState() = default;
    ~ScalingListDataState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    ScalingListDataState(const ScalingListDataState&) = delete;
    ScalingListDataState(ScalingListDataState&&) = delete;
    ScalingListDataState& operator=(const ScalingListDataState&) = delete;
    ScalingListDataState& operator=(ScalingListDataState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    std::vector<std::vector<uint32_t>> scaling_list_pred_mode_flag;
    std::vector<std::vector<uint32_t>> scaling_list_pred_matrix_id_delta;
    std::vector<std::vector<int32_t>> scaling_list_dc_coef_minus8;
    std::vector<std::vector<std::vector<uint32_t>>> ScalingList;
  };

  // Unpack RBSP and parse ScalingListData state from the supplied buffer.
  static std::unique_ptr<ScalingListDataState> ParseScalingListData(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<ScalingListDataState> ParseScalingListData(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
