/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_hrd_parameters_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

enum AspectRatioType : uint8_t {
  AR_UNSPECIFIED = 0,
  AR_1_1 = 1,      // 1:1 ("square")
  AR_12_11 = 2,    // 12:11
  AR_10_11 = 3,    // 10:11
  AR_16_11 = 4,    // 16:11
  AR_40_33 = 5,    // 40:33
  AR_24_11 = 6,    // 24:11
  AR_20_11 = 7,    // 20:11
  AR_32_11 = 8,    // 32:11
  AR_80_33 = 9,    // 80:33
  AR_18_11 = 10,   // 18:11
  AR_15_11 = 11,   // 15:11
  AR_64_33 = 12,   // 64:33
  AR_160_99 = 13,  // 160:99
  AR_4_3 = 14,     // 4:3
  AR_3_2 = 15,     // 3:2
  AR_2_1 = 16,     // 2:1
  // 17..254: Reserved
  AR_EXTENDED_SAR = 255  // Extended_SAR
};

// A class for parsing out a SPS VUI data from an H264 NALU.
class H264VuiParametersParser {
 public:
  // The parsed state of the SPS VUI. Only some select values are stored.
  // Add more as they are actually needed.
  struct VuiParametersState {
    VuiParametersState() = default;
    ~VuiParametersState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    VuiParametersState(const VuiParametersState&) = delete;
    VuiParametersState(VuiParametersState&&) = delete;
    VuiParametersState& operator=(const VuiParametersState&) = delete;
    VuiParametersState& operator=(VuiParametersState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t aspect_ratio_info_present_flag = 0;
    uint32_t aspect_ratio_idc = 0;
    uint32_t sar_width = 0;
    uint32_t sar_height = 0;
    uint32_t overscan_info_present_flag = 0;
    uint32_t overscan_appropriate_flag = 0;
    uint32_t video_signal_type_present_flag = 0;
    uint32_t video_format = 0;
    uint32_t video_full_range_flag = 0;
    uint32_t colour_description_present_flag = 0;
    uint32_t colour_primaries = 0;
    uint32_t transfer_characteristics = 0;
    uint32_t matrix_coefficients = 0;
    uint32_t chroma_loc_info_present_flag = 0;
    uint32_t chroma_sample_loc_type_top_field = 0;
    uint32_t chroma_sample_loc_type_bottom_field = 0;
    uint32_t timing_info_present_flag = 0;
    uint32_t num_units_in_tick = 0;
    uint32_t time_scale = 0;
    uint32_t fixed_frame_rate_flag = 0;
    uint32_t nal_hrd_parameters_present_flag = 0;
    std::unique_ptr<struct H264HrdParametersParser::HrdParametersState>
        nal_hrd_parameters;
    uint32_t vcl_hrd_parameters_present_flag = 0;
    std::unique_ptr<struct H264HrdParametersParser::HrdParametersState>
        vcl_hrd_parameters;
    uint32_t low_delay_hrd_flag = 0;
    uint32_t pic_struct_present_flag = 0;
    uint32_t bitstream_restriction_flag = 0;
    uint32_t motion_vectors_over_pic_boundaries_flag = 0;
    uint32_t max_bytes_per_pic_denom = 0;
    uint32_t max_bits_per_mb_denom = 0;
    uint32_t log2_max_mv_length_horizontal = 0;
    uint32_t log2_max_mv_length_vertical = 0;
    uint32_t max_num_reorder_frames = 0;
    uint32_t max_dec_frame_buffering = 0;
  };

  // Unpack RBSP and parse VUI Parameters state from the supplied buffer.
  static std::unique_ptr<VuiParametersState> ParseVuiParameters(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<VuiParametersState> ParseVuiParameters(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h264nal
