/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_profile_tier_level_parser.h"
#include "h265_scaling_list_data_parser.h"
#include "h265_sps_3d_extension_parser.h"
#include "h265_sps_multilayer_extension_parser.h"
#include "h265_sps_range_extension_parser.h"
#include "h265_sps_scc_extension_parser.h"
#include "h265_st_ref_pic_set_parser.h"
#include "h265_vui_parameters_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a video sequence parameter set (SPS) data from
// an H265 NALU.
class H265SpsParser {
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

    uint32_t sps_video_parameter_set_id = 0;
    uint32_t sps_max_sub_layers_minus1 = 0;
    uint32_t sps_temporal_id_nesting_flag = 0;
    std::unique_ptr<struct H265ProfileTierLevelParser::ProfileTierLevelState>
        profile_tier_level;
    uint32_t sps_seq_parameter_set_id = 0;
    uint32_t chroma_format_idc = 0;
    uint32_t separate_colour_plane_flag = 0;
    uint32_t pic_width_in_luma_samples = 0;
    uint32_t pic_height_in_luma_samples = 0;
    uint32_t conformance_window_flag = 0;
    uint32_t conf_win_left_offset = 0;
    uint32_t conf_win_right_offset = 0;
    uint32_t conf_win_top_offset = 0;
    uint32_t conf_win_bottom_offset = 0;
    uint32_t bit_depth_luma_minus8 = 0;
    uint32_t bit_depth_chroma_minus8 = 0;
    uint32_t log2_max_pic_order_cnt_lsb_minus4 = 0;
    uint32_t sps_sub_layer_ordering_info_present_flag = 0;
    std::vector<uint32_t> sps_max_dec_pic_buffering_minus1;
    std::vector<uint32_t> sps_max_num_reorder_pics;
    std::vector<uint32_t> sps_max_latency_increase_plus1;
    uint32_t log2_min_luma_coding_block_size_minus3 = 0;
    uint32_t log2_diff_max_min_luma_coding_block_size = 0;
    uint32_t log2_min_luma_transform_block_size_minus2 = 0;
    uint32_t log2_diff_max_min_luma_transform_block_size = 0;
    uint32_t max_transform_hierarchy_depth_inter = 0;
    uint32_t max_transform_hierarchy_depth_intra = 0;
    uint32_t scaling_list_enabled_flag = 0;
    uint32_t sps_scaling_list_data_present_flag = 0;
    std::unique_ptr<struct H265ScalingListDataParser::ScalingListDataState>
        scaling_list_data;
    uint32_t amp_enabled_flag = 0;
    uint32_t sample_adaptive_offset_enabled_flag = 0;
    uint32_t pcm_enabled_flag = 0;
    uint32_t pcm_sample_bit_depth_luma_minus1 = 0;
    uint32_t pcm_sample_bit_depth_chroma_minus1 = 0;
    uint32_t log2_min_pcm_luma_coding_block_size_minus3 = 0;
    uint32_t log2_diff_max_min_pcm_luma_coding_block_size = 0;
    uint32_t pcm_loop_filter_disabled_flag = 0;
    uint32_t num_short_term_ref_pic_sets = 0;
    std::vector<std::unique_ptr<struct H265StRefPicSetParser::StRefPicSetState>>
        st_ref_pic_set;
    uint32_t long_term_ref_pics_present_flag = 0;
    uint32_t num_long_term_ref_pics_sps = 0;
    std::vector<uint32_t> lt_ref_pic_poc_lsb_sps;
    std::vector<uint32_t> used_by_curr_pic_lt_sps_flag;
    uint32_t sps_temporal_mvp_enabled_flag = 0;
    uint32_t strong_intra_smoothing_enabled_flag = 0;
    uint32_t vui_parameters_present_flag = 0;
    std::unique_ptr<struct H265VuiParametersParser::VuiParametersState>
        vui_parameters;
    uint32_t sps_extension_present_flag = 0;
    uint32_t sps_range_extension_flag = 0;
    uint32_t sps_multilayer_extension_flag = 0;
    uint32_t sps_3d_extension_flag = 0;
    uint32_t sps_scc_extension_flag = 0;
    uint32_t sps_extension_4bits = 0;
    std::unique_ptr<struct H265SpsRangeExtensionParser::SpsRangeExtensionState>
        sps_range_extension;
    std::unique_ptr<
        struct H265SpsMultilayerExtensionParser::SpsMultilayerExtensionState>
        sps_multilayer_extension;
    std::unique_ptr<struct H265Sps3dExtensionParser::Sps3dExtensionState>
        sps_3d_extension;
    std::unique_ptr<struct H265SpsSccExtensionParser::SpsSccExtensionState>
        sps_scc_extension;
    uint32_t sps_extension_data_flag = 0;

    // derived values
    bool getMaxNumPics(uint32_t* max_num_pics) noexcept;
    uint32_t getMinCbLog2SizeY() noexcept;
    uint32_t getCtbLog2SizeY() noexcept;
    uint32_t getMinCbSizeY() noexcept;
    uint32_t getCtbSizeY() noexcept;
    uint32_t getPicWidthInMinCbsY() noexcept;
    uint32_t getPicWidthInCtbsY() noexcept;
    uint32_t getPicHeightInMinCbsY() noexcept;
    uint32_t getPicHeightInCtbsY() noexcept;
    uint32_t getPicSizeInMinCbsY() noexcept;
    uint32_t getPicSizeInCtbsY() noexcept;
    uint32_t getPicSizeInSamplesY() noexcept;
#if 0
    uint32_t getPicWidthInSamplesC() noexcept;
    uint32_t getPicHeightInSamplesC() noexcept;
#endif
  };

  // Unpack RBSP and parse SPS state from the supplied buffer.
  static std::shared_ptr<SpsState> ParseSps(const uint8_t* data,
                                            size_t length) noexcept;
  static std::shared_ptr<SpsState> ParseSps(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
