/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a prediction weight table
// (`pred_weight_table()`, as defined in Section 7.3.3.2 of the 2012
// standard) from an H264 NALU.
class H264PredWeightTableParser {
 public:
  // The parsed state of the PredWeightTable.
  struct PredWeightTableState {
    PredWeightTableState() = default;
    ~PredWeightTableState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    PredWeightTableState(const PredWeightTableState&) = delete;
    PredWeightTableState(PredWeightTableState&&) = delete;
    PredWeightTableState& operator=(const PredWeightTableState&) = delete;
    PredWeightTableState& operator=(PredWeightTableState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t chroma_array_type = 0;
    uint32_t slice_type = 0;
    uint32_t num_ref_idx_l0_active_minus1 = 0;
    uint32_t num_ref_idx_l1_active_minus1 = 0;

    // contents
    uint32_t luma_log2_weight_denom = 0;
    uint32_t chroma_log2_weight_denom = 0;
    std::vector<uint32_t> luma_weight_l0_flag;
    std::vector<uint32_t> luma_weight_l0;
    std::vector<uint32_t> luma_offset_l0;
    std::vector<uint32_t> chroma_weight_l0_flag;
    std::vector<std::vector<uint32_t>> chroma_weight_l0;
    std::vector<std::vector<uint32_t>> chroma_offset_l0;
    std::vector<uint32_t> luma_weight_l1_flag;
    std::vector<uint32_t> luma_weight_l1;
    std::vector<uint32_t> luma_offset_l1;
    std::vector<uint32_t> chroma_weight_l1_flag;
    std::vector<std::vector<uint32_t>> chroma_weight_l1;
    std::vector<std::vector<uint32_t>> chroma_offset_l1;
  };

  // Unpack RBSP and parse PredWeightTable state from the supplied buffer.
  static std::unique_ptr<PredWeightTableState> ParsePredWeightTable(
      const uint8_t* data, size_t length, uint32_t chroma_array_type,
      uint32_t slice_type, uint32_t num_ref_idx_l0_active_minus1,
      uint32_t num_ref_idx_l1_active_minus1) noexcept;
  static std::unique_ptr<PredWeightTableState> ParsePredWeightTable(
      rtc::BitBuffer* bit_buffer, uint32_t chroma_array_type,
      uint32_t slice_type, uint32_t num_ref_idx_l0_active_minus1,
      uint32_t num_ref_idx_l1_active_minus1) noexcept;
};

}  // namespace h264nal
