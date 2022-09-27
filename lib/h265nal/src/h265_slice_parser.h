/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_bitstream_parser_state.h"
#include "h265_pps_parser.h"
#include "h265_pred_weight_table_parser.h"
#include "h265_sps_parser.h"
#include "h265_st_ref_pic_set_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

enum SliceType : uint8_t { SliceType_B = 0, SliceType_P = 1, SliceType_I = 2 };

// A class for parsing out a slice segment header data from
// an H265 NALU.
class H265SliceSegmentHeaderParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceSegmentHeaderState {
    SliceSegmentHeaderState() = default;
    ~SliceSegmentHeaderState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceSegmentHeaderState(const SliceSegmentHeaderState&) = delete;
    SliceSegmentHeaderState(SliceSegmentHeaderState&&) = delete;
    SliceSegmentHeaderState& operator=(const SliceSegmentHeaderState&) = delete;
    SliceSegmentHeaderState& operator=(SliceSegmentHeaderState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_unit_type = 0;
    uint32_t dependent_slice_segments_enabled_flag = 0;
    uint32_t num_extra_slice_header_bits = 0;
    uint32_t output_flag_present_flag = 0;
    uint32_t separate_colour_plane_flag = 0;
    uint32_t log2_max_pic_order_cnt_lsb_minus4 = 0;
    uint32_t num_short_term_ref_pic_sets = 0;
    uint32_t long_term_ref_pics_present_flag = 0;
    uint32_t num_long_term_ref_pics_sps = 0;
    uint32_t sps_temporal_mvp_enabled_flag = 0;
    uint32_t sample_adaptive_offset_enabled_flag = 0;
    uint32_t ChromaArrayType = 0;
    uint32_t chroma_format_idc = 0;
    uint32_t lists_modification_present_flag = 0;
    uint32_t NumPicTotalCurr = 0;
    uint32_t cabac_init_present_flag = 0;
    uint32_t weighted_pred_flag = 0;
    uint32_t weighted_bipred_flag = 0;
    uint32_t motion_vector_resolution_control_idc = 0;
    uint32_t pps_slice_chroma_qp_offsets_present_flag = 0;
    uint32_t pps_slice_act_qp_offsets_present_flag = 0;
    uint32_t chroma_qp_offset_list_enabled_flag = 0;
    uint32_t deblocking_filter_override_enabled_flag = 0;
    uint32_t pps_loop_filter_across_slices_enabled_flag = 0;
    uint32_t tiles_enabled_flag = 0;
    uint32_t entropy_coding_sync_enabled_flag = 0;
    uint32_t slice_segment_header_extension_present_flag = 0;

    // contents
    uint32_t first_slice_segment_in_pic_flag = 0;
    uint32_t no_output_of_prior_pics_flag = 0;
    uint32_t slice_pic_parameter_set_id = 0;
    uint32_t dependent_slice_segment_flag = 0;
    uint32_t slice_segment_address = 0;
    std::vector<uint32_t> slice_reserved_flag;
    uint32_t slice_type = 0;
    uint32_t pic_output_flag = 0;
    uint32_t colour_plane_id = 0;
    uint32_t slice_pic_order_cnt_lsb = 0;
    uint32_t short_term_ref_pic_set_sps_flag = 0;
    std::unique_ptr<struct H265StRefPicSetParser::StRefPicSetState>
        st_ref_pic_set;
    uint32_t short_term_ref_pic_set_idx = 0;
    uint32_t num_long_term_sps = 0;
    uint32_t num_long_term_pics = 0;
    std::vector<uint32_t> lt_idx_sps;
    std::vector<uint32_t> poc_lsb_lt;
    std::vector<uint32_t> used_by_curr_pic_lt_flag;
    std::vector<uint32_t> delta_poc_msb_present_flag;
    std::vector<uint32_t> delta_poc_msb_cycle_lt;
    uint32_t slice_temporal_mvp_enabled_flag = 0;
    uint32_t slice_sao_luma_flag = 0;
    uint32_t slice_sao_chroma_flag = 0;
    uint32_t num_ref_idx_active_override_flag = 0;
    uint32_t num_ref_idx_l0_active_minus1 = 0;
    uint32_t num_ref_idx_l1_active_minus1 = 0;
    // ref_pic_lists_modification()
    uint32_t mvd_l1_zero_flag = 0;
    uint32_t cabac_init_flag = 0;
    // default value is 1 (page 99 of 02/2018 standard)
    uint32_t collocated_from_l0_flag = 1;
    uint32_t collocated_ref_idx = 0;
    std::unique_ptr<struct H265PredWeightTableParser::PredWeightTableState>
        pred_weight_table;
    uint32_t five_minus_max_num_merge_cand = 0;
    uint32_t use_integer_mv_flag = 0;
    int32_t slice_qp_delta = 0;
    int32_t slice_cb_qp_offset = 0;
    int32_t slice_cr_qp_offset = 0;
    int32_t slice_act_y_qp_offset = 0;
    int32_t slice_act_cb_qp_offset = 0;
    int32_t slice_act_cr_qp_offset = 0;
    uint32_t cu_chroma_qp_offset_enabled_flag = 0;
    uint32_t deblocking_filter_override_flag = 0;
    uint32_t slice_deblocking_filter_disabled_flag = 0;
    int32_t slice_beta_offset_div2 = 0;
    int32_t slice_tc_offset_div2 = 0;
    uint32_t slice_loop_filter_across_slices_enabled_flag = 0;
    uint32_t num_entry_point_offsets = 0;
    uint32_t offset_len_minus1 = 0;
    std::vector<uint32_t> entry_point_offset_minus1;
    uint32_t slice_segment_header_extension_length = 0;
    std::vector<uint32_t> slice_segment_header_extension_data_byte;

    // Limits Check
    bool isValidNumEntryPointOffsets(
        uint32_t num_entry_point_offsets_value,
        std::shared_ptr<struct H265SpsParser::SpsState> sps,
        std::shared_ptr<struct H265PpsParser::PpsState> pps) noexcept;
  };

  // Unpack RBSP and parse slice state from the supplied buffer.
  static std::unique_ptr<SliceSegmentHeaderState> ParseSliceSegmentHeader(
      const uint8_t* data, size_t length, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceSegmentHeaderState> ParseSliceSegmentHeader(
      rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

// A class for parsing out a slice segment layer data from
// an H265 NALU.
class H265SliceSegmentLayerParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceSegmentLayerState {
    SliceSegmentLayerState() = default;
    ~SliceSegmentLayerState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceSegmentLayerState(const SliceSegmentLayerState&) = delete;
    SliceSegmentLayerState(SliceSegmentLayerState&&) = delete;
    SliceSegmentLayerState& operator=(const SliceSegmentLayerState&) = delete;
    SliceSegmentLayerState& operator=(SliceSegmentLayerState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_unit_type = 0;

    // contents
    std::unique_ptr<
        struct H265SliceSegmentHeaderParser::SliceSegmentHeaderState>
        slice_segment_header;
    // slice_segment_data()
    // rbsp_slice_segment_trailing_bits()
  };

  // Unpack RBSP and parse slice state from the supplied buffer.
  static std::unique_ptr<SliceSegmentLayerState> ParseSliceSegmentLayer(
      const uint8_t* data, size_t length, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceSegmentLayerState> ParseSliceSegmentLayer(
      rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
