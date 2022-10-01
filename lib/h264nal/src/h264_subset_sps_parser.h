/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_sps_parser.h"
#include "h264_sps_svc_extension_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a subset sequence parameter set (SPS) data
// from an H264 NALU.
class H264SubsetSpsParser {
 public:
  // The parsed state of the SPS. Only some select values are stored.
  // Add more as they are actually needed.
  struct SubsetSpsState {
    SubsetSpsState() = default;
    ~SubsetSpsState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SubsetSpsState(const SubsetSpsState&) = delete;
    SubsetSpsState(SubsetSpsState&&) = delete;
    SubsetSpsState& operator=(const SubsetSpsState&) = delete;
    SubsetSpsState& operator=(SubsetSpsState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    std::unique_ptr<struct H264SpsDataParser::SpsDataState>
        seq_parameter_set_data;

    std::unique_ptr<struct H264SpsSvcExtensionParser::SpsSvcExtensionState>
        seq_parameter_set_svc_extension;
    uint32_t svc_vui_parameters_present_flag = 0;
    // TODO(chema): svc_vui_parameters_extension()
    uint32_t bit_equal_to_one = 0;
    // TODO(chema): seq_parameter_set_mvc_extension()
    uint32_t mvc_vui_parameters_present_flag = 0;
    // TODO(chema): mvc_vui_parameters_extension()
    // TODO(chema): seq_parameter_set_mvcd_extension()
    // TODO(chema): seq_parameter_set_3davc_extension()
    uint32_t additional_extension2_flag = 0;
    uint32_t additional_extension2_data_flag = 0;
  };

  // Unpack RBSP and parse SPS state from the supplied buffer.
  static std::shared_ptr<SubsetSpsState> ParseSubsetSps(const uint8_t* data,
                                                        size_t length) noexcept;
  static std::shared_ptr<SubsetSpsState> ParseSubsetSps(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h264nal
