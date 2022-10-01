/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a sequence parameter set screen content coding
// extension syntax (`sps_scc_extension()`, as defined in Section 7.3.2.2.3
// of the 2016-12 standard) from an H265 NALU.
class H265SpsSccExtensionParser {
 public:
  // The parsed state of the SpsSccExtension.
  struct SpsSccExtensionState {
    SpsSccExtensionState() = default;
    ~SpsSccExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsSccExtensionState(const SpsSccExtensionState&) = delete;
    SpsSccExtensionState(SpsSccExtensionState&&) = delete;
    SpsSccExtensionState& operator=(const SpsSccExtensionState&) = delete;
    SpsSccExtensionState& operator=(SpsSccExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    uint32_t sps_curr_pic_ref_enabled_flag = 0;
    uint32_t palette_mode_enabled_flag = 0;
    uint32_t palette_max_size = 0;
    uint32_t delta_palette_max_predictor_size = 0;
    uint32_t sps_palette_predictor_initializers_present_flag = 0;
    uint32_t sps_num_palette_predictor_initializers_minus1 = 0;
    std::vector<std::vector<uint32_t>> sps_palette_predictor_initializers;
    uint32_t motion_vector_resolution_control_idc = 0;
    uint32_t intra_boundary_filtering_disabled_flag = 0;
  };

  // Unpack RBSP and parse SpsSccExtension state from the supplied buffer.
  static std::unique_ptr<SpsSccExtensionState> ParseSpsSccExtension(
      const uint8_t* data, size_t length, uint32_t chroma_format_idc,
      uint32_t bit_depth_luma_minus8,
      uint32_t bit_depth_chroma_minus8) noexcept;
  static std::unique_ptr<SpsSccExtensionState> ParseSpsSccExtension(
      rtc::BitBuffer* bit_buffer, uint32_t chroma_format_idc,
      uint32_t bit_depth_luma_minus8,
      uint32_t bit_depth_chroma_minus8) noexcept;
};

}  // namespace h265nal
