/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_nal_unit_header_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a slice header data from
// an H264 NALU.
class H264SliceHeaderInScalableExtensionParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceHeaderInScalableExtensionState {
    SliceHeaderInScalableExtensionState() = default;
    ~SliceHeaderInScalableExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceHeaderInScalableExtensionState(
        const SliceHeaderInScalableExtensionState&) = delete;
    SliceHeaderInScalableExtensionState(SliceHeaderInScalableExtensionState&&) =
        delete;
    SliceHeaderInScalableExtensionState& operator=(
        const SliceHeaderInScalableExtensionState&) = delete;
    SliceHeaderInScalableExtensionState& operator=(
        SliceHeaderInScalableExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_ref_idc = 0;
    uint32_t nal_unit_type = 0;
    uint32_t separate_colour_plane_flag = 0;
    uint32_t log2_max_frame_num_minus4 = 0;
    uint32_t frame_mbs_only_flag = 0;
    uint32_t pic_order_cnt_type = 0;
    uint32_t bottom_field_pic_order_in_frame_present_flag = 0;
    uint32_t delta_pic_order_always_zero_flag = 0;
    uint32_t redundant_pic_cnt_present_flag = 0;
    uint32_t weighted_pred_flag = 0;
    uint32_t weighted_bipred_idc = 0;
    uint32_t no_inter_layer_pred_flag = 0;
    uint32_t quality_id = 0;
    uint32_t ChromaArrayType = 0;
    uint32_t slice_header_restriction_flag = 0;
    uint32_t use_ref_base_pic_flag = 0;
    uint32_t idr_flag = 0;
    uint32_t entropy_coding_mode_flag = 0;
    uint32_t deblocking_filter_control_present_flag = 0;
    uint32_t num_slice_groups_minus1 = 0;
    uint32_t slice_group_map_type = 0;
    uint32_t pic_width_in_mbs_minus1 = 0;
    uint32_t pic_height_in_map_units_minus1 = 0;
    uint32_t slice_group_change_rate_minus1 = 0;
    uint32_t inter_layer_deblocking_filter_control_present_flag = 0;
    uint32_t extended_spatial_scalability_idc = 0;
    uint32_t adaptive_tcoeff_level_prediction_flag = 0;

    // contents
    uint32_t first_mb_in_slice = 0;
    uint32_t slice_type = 0;
    uint32_t pic_parameter_set_id = 0;
    uint32_t colour_plane_id = 0;
    uint32_t frame_num = 0;
    uint32_t field_pic_flag = 0;
    uint32_t bottom_field_flag = 0;
    uint32_t idr_pic_id = 0;
    uint32_t pic_order_cnt_lsb = 0;
    int32_t delta_pic_order_cnt_bottom = 0;
    std::vector<int32_t> delta_pic_order_cnt;
    uint32_t redundant_pic_cnt = 0;
    uint32_t direct_spatial_mv_pred_flag = 0;
    uint32_t num_ref_idx_active_override_flag = 0;
    uint32_t num_ref_idx_l0_active_minus1 = 0;
    uint32_t num_ref_idx_l1_active_minus1 = 0;
    std::unique_ptr<
        struct H264RefPicListModificationParser::RefPicListModificationState>
        ref_pic_list_modification;
    uint32_t base_pred_weight_table_flag = 0;
    std::unique_ptr<struct H264PredWeightTableParser::PredWeightTableState>
        pred_weight_table;
    std::unique_ptr<struct H264DecRefPicMarkingParser::DecRefPicMarkingState>
        dec_ref_pic_marking;
    uint32_t store_ref_base_pic_flag = 0;
    // TODO(chemag): dec_ref_base_pic_marking()
    uint32_t cabac_init_idc = 0;
    int32_t slice_qp_delta = 0;
    uint32_t disable_deblocking_filter_idc = 0;
    int32_t slice_alpha_c0_offset_div2 = 0;
    int32_t slice_beta_offset_div2 = 0;
    uint32_t slice_group_change_cycle = 0;
    uint32_t ref_layer_dq_id = 0;
    uint32_t disable_inter_layer_deblocking_filter_idc = 0;
    int32_t inter_layer_slice_alpha_c0_offset_div2 = 0;
    int32_t inter_layer_slice_beta_offset_div2 = 0;
    uint32_t constrained_intra_resampling_flag = 0;
    uint32_t ref_layer_chroma_phase_x_plus1_flag = 0;
    uint32_t ref_layer_chroma_phase_y_plus1 = 0;
    int32_t scaled_ref_layer_left_offset = 0;
    int32_t scaled_ref_layer_top_offset = 0;
    int32_t scaled_ref_layer_right_offset = 0;
    int32_t scaled_ref_layer_bottom_offset = 0;
    uint32_t slice_skip_flag = 0;
    uint32_t num_mbs_in_slice_minus1 = 0;
    uint32_t adaptive_base_mode_flag = 0;
    uint32_t default_base_mode_flag = 0;
    uint32_t adaptive_motion_prediction_flag = 0;
    uint32_t default_motion_prediction_flag = 0;
    uint32_t adaptive_residual_prediction_flag = 0;
    uint32_t default_residual_prediction_flag = 0;
    uint32_t tcoeff_level_prediction_flag = 0;
    uint32_t scan_idx_start = 0;
    uint32_t scan_idx_end = 0;

    // derived values
    static uint32_t getFrameNumLen(uint32_t log2_max_frame_num_minus4) noexcept;
    static uint32_t getPicOrderCntLsbLen(
        uint32_t log2_max_pic_order_cnt_lsb_minus4) noexcept;
    static uint32_t getSliceGroupChangeCycleLen(
        uint32_t pic_width_in_mbs_minus1,
        uint32_t pic_height_in_map_units_minus1,
        uint32_t slice_group_change_rate_minus1) noexcept;
    static uint32_t getPicWidthInMbs(uint32_t pic_width_in_mbs_minus1) noexcept;
    static uint32_t getPicHeightInMapUnits(
        uint32_t pic_height_in_map_units_minus1) noexcept;
    static uint32_t getPicSizeInMapUnits(
        uint32_t pic_width_in_mbs_minus1,
        uint32_t pic_height_in_map_units_minus1) noexcept;
    static uint32_t getSliceGroupChangeRate(
        uint32_t slice_group_change_rate_minus1) noexcept;
  };

  // Unpack RBSP and parse slice state from the supplied buffer.
  static std::unique_ptr<SliceHeaderInScalableExtensionState>
  ParseSliceHeaderInScalableExtension(
      const uint8_t* data, size_t length,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceHeaderInScalableExtensionState>
  ParseSliceHeaderInScalableExtension(
      rtc::BitBuffer* bit_buffer,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
