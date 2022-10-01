/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a sequence parameter set range extension syntax
// (`sps_range_extension()`, as defined in Section 7.3.7 of the 2016-12
// standard) from an H265 NALU.
class H265SpsRangeExtensionParser {
 public:
  // The parsed state of the SpsRangeExtension.
  struct SpsRangeExtensionState {
    SpsRangeExtensionState() = default;
    ~SpsRangeExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsRangeExtensionState(const SpsRangeExtensionState&) = delete;
    SpsRangeExtensionState(SpsRangeExtensionState&&) = delete;
    SpsRangeExtensionState& operator=(const SpsRangeExtensionState&) = delete;
    SpsRangeExtensionState& operator=(SpsRangeExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    uint32_t transform_skip_rotation_enabled_flag = 0;
    uint32_t transform_skip_context_enabled_flag = 0;
    uint32_t implicit_rdpcm_enabled_flag = 0;
    uint32_t explicit_rdpcm_enabled_flag = 0;
    uint32_t extended_precision_processing_flag = 0;
    uint32_t intra_smoothing_disabled_flag = 0;
    uint32_t high_precision_offsets_enabled_flag = 0;
    uint32_t persistent_rice_adaptation_enabled_flag = 0;
    uint32_t cabac_bypass_alignment_enabled_flag = 0;
  };

  // Unpack RBSP and parse SpsRangeExtension state from the supplied buffer.
  static std::unique_ptr<SpsRangeExtensionState> ParseSpsRangeExtension(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<SpsRangeExtensionState> ParseSpsRangeExtension(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
