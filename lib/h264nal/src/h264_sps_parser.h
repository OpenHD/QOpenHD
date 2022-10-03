/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_vui_parameters_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// Classes for parsing out a video sequence parameter set (SPS) data from
// an H264 NALU.

// seq_parameter_set_data()
class H264SpsDataParser {
 public:
  // The parsed state of an seq_parameter_set_data() RBSP. Only some select
  // values are stored.
  // Add more as they are actually needed.
  struct SpsDataState {
    SpsDataState() = default;
    ~SpsDataState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsDataState(const SpsDataState&) = delete;
    SpsDataState(SpsDataState&&) = delete;
    SpsDataState& operator=(const SpsDataState&) = delete;
    SpsDataState& operator=(SpsDataState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t profile_idc = 0;
    uint32_t constraint_set0_flag = 0;
    uint32_t constraint_set1_flag = 0;
    uint32_t constraint_set2_flag = 0;
    uint32_t constraint_set3_flag = 0;
    uint32_t constraint_set4_flag = 0;
    uint32_t constraint_set5_flag = 0;
    uint32_t reserved_zero_2bits = 0;
    uint32_t level_idc = 0;
    uint32_t seq_parameter_set_id = 0;
    uint32_t chroma_format_idc = 0;
    uint32_t separate_colour_plane_flag = 0;
    uint32_t bit_depth_luma_minus8 = 0;
    uint32_t bit_depth_chroma_minus8 = 0;
    uint32_t qpprime_y_zero_transform_bypass_flag = 0;
    uint32_t seq_scaling_matrix_present_flag = 0;
    std::vector<uint32_t> seq_scaling_list_present_flag;
    // scaling_list()
    std::vector<uint32_t> ScalingList4x4;
    std::vector<uint32_t> UseDefaultScalingMatrix4x4Flag;
    std::vector<uint32_t> ScalingList8x8;
    std::vector<uint32_t> UseDefaultScalingMatrix8x8Flag;
    int32_t delta_scale = 0;
    uint32_t log2_max_frame_num_minus4 = 0;
    uint32_t pic_order_cnt_type = 0;
    uint32_t log2_max_pic_order_cnt_lsb_minus4 = 0;
    uint32_t delta_pic_order_always_zero_flag = 0;
    int32_t offset_for_non_ref_pic = 0;
    int32_t offset_for_top_to_bottom_field = 0;
    uint32_t num_ref_frames_in_pic_order_cnt_cycle = 0;
    std::vector<int32_t> offset_for_ref_frame;
    uint32_t max_num_ref_frames = 0;
    uint32_t gaps_in_frame_num_value_allowed_flag = 0;
    uint32_t pic_width_in_mbs_minus1 = 0;
    uint32_t pic_height_in_map_units_minus1 = 0;
    uint32_t frame_mbs_only_flag = 0;
    uint32_t mb_adaptive_frame_field_flag = 0;
    uint32_t direct_8x8_inference_flag = 0;
    uint32_t frame_cropping_flag = 0;
    uint32_t frame_crop_left_offset = 0;
    uint32_t frame_crop_right_offset = 0;
    uint32_t frame_crop_top_offset = 0;
    uint32_t frame_crop_bottom_offset = 0;
    uint32_t vui_parameters_present_flag = 0;
    std::unique_ptr<struct H264VuiParametersParser::VuiParametersState>
        vui_parameters;

    // derived values
    uint32_t getChromaArrayType() noexcept;

    // helper functions
    bool scaling_list(
        rtc::BitBuffer* bit_buffer, uint32_t i,
        std::vector<uint32_t>& scalingList, uint32_t sizeOfScalingList,
        std::vector<uint32_t>& useDefaultScalingMatrixFlag) noexcept;
  };

  // Unpack RBSP and parse SPS data state from the supplied buffer.
  static std::unique_ptr<SpsDataState> ParseSpsData(const uint8_t* data,
                                                    size_t length) noexcept;
  static std::unique_ptr<SpsDataState> ParseSpsData(
      rtc::BitBuffer* bit_buffer) noexcept;
};

// seq_parameter_set_rbsp()
class H264SpsParser {
 public:
  // The parsed state of the SPS. Only some select values are stored.
  // Add more as they are actually needed.
  struct SpsState {
    SpsState() = default;
    ~SpsState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsState(const SpsState&) = delete;
    SpsState(SpsState&&) = delete;
    SpsState& operator=(const SpsState&) = delete;
    SpsState& operator=(SpsState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    std::unique_ptr<struct H264SpsDataParser::SpsDataState> sps_data;

    // derived values
    uint32_t getChromaArrayType() noexcept;
  };

  // Unpack RBSP and parse SPS state from the supplied buffer.
  static std::shared_ptr<SpsState> ParseSps(const uint8_t* data,
                                            size_t length) noexcept;
  static std::shared_ptr<SpsState> ParseSps(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h264nal
