/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a picture parameter set screen content coding
// extension syntax (`pps_scc_extension()`, as defined in Section 7.3.2.3.3
// of the 2016-12 standard) from an H265 NALU.
class H265PpsSccExtensionParser {
 public:
  // The parsed state of the PpsSccExtension.
  struct PpsSccExtensionState {
    PpsSccExtensionState() = default;
    ~PpsSccExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    PpsSccExtensionState(const PpsSccExtensionState&) = delete;
    PpsSccExtensionState(PpsSccExtensionState&&) = delete;
    PpsSccExtensionState& operator=(const PpsSccExtensionState&) = delete;
    PpsSccExtensionState& operator=(PpsSccExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    uint32_t pps_curr_pic_ref_enabled_flag = 0;
    uint32_t residual_adaptive_colour_transform_enabled_flag = 0;
    uint32_t pps_slice_act_qp_offsets_present_flag = 0;
    int32_t pps_act_y_qp_offset_plus5 = 0;
    int32_t pps_act_cb_qp_offset_plus5 = 0;
    int32_t pps_act_cr_qp_offset_plus3 = 0;
    uint32_t pps_palette_predictor_initializer_present_flag = 0;
    uint32_t pps_num_palette_predictor_initializer = 0;
    uint32_t monochrome_palette_flag = 0;
    uint32_t luma_bit_depth_entry_minus8 = 0;
    uint32_t chroma_bit_depth_entry_minus8 = 0;
    std::vector<std::vector<uint32_t>> pps_palette_predictor_initializers;
  };

  // Unpack RBSP and parse PpsSccExtension state from the supplied buffer.
  static std::unique_ptr<PpsSccExtensionState> ParsePpsSccExtension(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<PpsSccExtensionState> ParsePpsSccExtension(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
