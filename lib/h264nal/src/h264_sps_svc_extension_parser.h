/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_hrd_parameters_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a SPS SVC extension from an H264 NALU.
class H264SpsSvcExtensionParser {
 public:
  // The parsed state of the SPS SVC extension. Only some select values are
  // stored.
  // Add more as they are actually needed.
  struct SpsSvcExtensionState {
    SpsSvcExtensionState() = default;
    ~SpsSvcExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsSvcExtensionState(const SpsSvcExtensionState&) = delete;
    SpsSvcExtensionState(SpsSvcExtensionState&&) = delete;
    SpsSvcExtensionState& operator=(const SpsSvcExtensionState&) = delete;
    SpsSvcExtensionState& operator=(SpsSvcExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t ChromaArrayType = 0;

    // contents
    uint32_t inter_layer_deblocking_filter_control_present_flag = 0;
    uint32_t extended_spatial_scalability_idc = 0;
    uint32_t chroma_phase_x_plus1_flag = 0;
    uint32_t chroma_phase_y_plus1 = 0;
    uint32_t seq_ref_layer_chroma_phase_x_plus1_flag = 0;
    uint32_t seq_ref_layer_chroma_phase_y_plus1 = 0;
    int32_t seq_scaled_ref_layer_left_offset = 0;
    int32_t seq_scaled_ref_layer_top_offset = 0;
    int32_t seq_scaled_ref_layer_right_offset = 0;
    int32_t seq_scaled_ref_layer_bottom_offset = 0;
    uint32_t seq_tcoeff_level_prediction_flag = 0;
    uint32_t adaptive_tcoeff_level_prediction_flag = 0;
    uint32_t slice_header_restriction_flag = 0;
  };

  // Unpack RBSP and parse SPS SVC state from the supplied buffer.
  static std::unique_ptr<SpsSvcExtensionState> ParseSpsSvcExtension(
      const uint8_t* data, size_t length, uint32_t ChromaArrayType) noexcept;
  static std::unique_ptr<SpsSvcExtensionState> ParseSpsSvcExtension(
      rtc::BitBuffer* bit_buffer, uint32_t ChromaArrayType) noexcept;
};

}  // namespace h264nal
