/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_pps_scc_extension_parser.h"
#include "h265_profile_tier_level_parser.h"
#include "h265_scaling_list_data_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a video sequence parameter set (PPS) data from
// an H265 NALU.
class H265PpsParser {
 public:
  // The parsed state of the PPS. Only some select values are stored.
  // Add more as they are actually needed.
  struct PpsState {
    PpsState() = default;
    ~PpsState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    PpsState(const PpsState&) = delete;
    PpsState(PpsState&&) = delete;
    PpsState& operator=(const PpsState&) = delete;
    PpsState& operator=(PpsState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t pps_pic_parameter_set_id = 0;
    uint32_t pps_seq_parameter_set_id = 0;
    uint32_t dependent_slice_segments_enabled_flag = 0;
    uint32_t output_flag_present_flag = 0;
    uint32_t num_extra_slice_header_bits = 0;
    uint32_t sign_data_hiding_enabled_flag = 0;
    uint32_t cabac_init_present_flag = 0;
    uint32_t num_ref_idx_l0_default_active_minus1 = 0;
    uint32_t num_ref_idx_l1_default_active_minus1 = 0;
    int32_t init_qp_minus26 = 0;
    uint32_t constrained_intra_pred_flag = 0;
    uint32_t transform_skip_enabled_flag = 0;
    uint32_t cu_qp_delta_enabled_flag = 0;
    uint32_t diff_cu_qp_delta_depth = 0;
    int32_t pps_cb_qp_offset = 0;
    int32_t pps_cr_qp_offset = 0;
    uint32_t pps_slice_chroma_qp_offsets_present_flag = 0;
    uint32_t weighted_pred_flag = 0;
    uint32_t weighted_bipred_flag = 0;
    uint32_t transquant_bypass_enabled_flag = 0;
    uint32_t tiles_enabled_flag = 0;
    uint32_t entropy_coding_sync_enabled_flag = 0;
    uint32_t num_tile_columns_minus1 = 0;
    uint32_t num_tile_rows_minus1 = 0;
    uint32_t uniform_spacing_flag = 0;
    std::vector<uint32_t> column_width_minus1;
    std::vector<uint32_t> row_height_minus1;
    uint32_t loop_filter_across_tiles_enabled_flag = 0;
    uint32_t pps_loop_filter_across_slices_enabled_flag = 0;
    uint32_t deblocking_filter_control_present_flag = 0;
    uint32_t deblocking_filter_override_enabled_flag = 0;
    uint32_t pps_deblocking_filter_disabled_flag = 0;
    int32_t pps_beta_offset_div2 = 0;
    int32_t pps_tc_offset_div2 = 0;
    uint32_t pps_scaling_list_data_present_flag = 0;
    std::unique_ptr<struct H265ScalingListDataParser::ScalingListDataState>
        scaling_list_data;
    uint32_t lists_modification_present_flag = 0;
    uint32_t log2_parallel_merge_level_minus2 = 0;
    uint32_t slice_segment_header_extension_present_flag = 0;
    uint32_t pps_extension_present_flag = 0;
    uint32_t pps_range_extension_flag = 0;
    uint32_t pps_multilayer_extension_flag = 0;
    uint32_t pps_3d_extension_flag = 0;
    uint32_t pps_scc_extension_flag = 0;
    uint32_t pps_extension_4bits = 0;
    std::unique_ptr<struct H265PpsSccExtensionParser::PpsSccExtensionState>
        pps_scc_extension;
    // pps_multilayer_extension( )
    // pps_3d_extension( )
    // pps_scc_extension( )
    uint32_t pps_extension_data_flag = 0;
  };

  // Unpack RBSP and parse PPS state from the supplied buffer.
  static std::shared_ptr<PpsState> ParsePps(const uint8_t* data,
                                            size_t length) noexcept;
  static std::shared_ptr<PpsState> ParsePps(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
