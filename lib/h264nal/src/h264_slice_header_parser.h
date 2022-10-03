/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a slice header data from
// an H264 NALU.
class H264SliceHeaderParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceHeaderState {
    SliceHeaderState() = default;
    ~SliceHeaderState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceHeaderState(const SliceHeaderState&) = delete;
    SliceHeaderState(SliceHeaderState&&) = delete;
    SliceHeaderState& operator=(const SliceHeaderState&) = delete;
    SliceHeaderState& operator=(SliceHeaderState&&) = delete;

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
    uint32_t entropy_coding_mode_flag = 0;
    uint32_t deblocking_filter_control_present_flag = 0;
    uint32_t num_slice_groups_minus1 = 0;
    uint32_t slice_group_map_type = 0;
    uint32_t pic_width_in_mbs_minus1 = 0;
    uint32_t pic_height_in_map_units_minus1 = 0;
    uint32_t slice_group_change_rate_minus1 = 0;

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
    std::unique_ptr<struct H264PredWeightTableParser::PredWeightTableState>
        pred_weight_table;
    std::unique_ptr<struct H264DecRefPicMarkingParser::DecRefPicMarkingState>
        dec_ref_pic_marking;
    uint32_t cabac_init_idc = 0;
    uint32_t sp_for_switch_flag = 0;
    int32_t slice_qp_delta = 0;
    int32_t slice_qs_delta = 0;
    uint32_t disable_deblocking_filter_idc = 0;
    int32_t slice_alpha_c0_offset_div2 = 0;
    int32_t slice_beta_offset_div2 = 0;
    uint32_t slice_group_change_cycle = 0;

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
  static std::unique_ptr<SliceHeaderState> ParseSliceHeader(
      const uint8_t* data, size_t length, uint32_t nal_ref_idc,
      uint32_t nal_unit_type,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceHeaderState> ParseSliceHeader(
      rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc, uint32_t nal_unit_type,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
