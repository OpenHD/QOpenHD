/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_slice_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"
#include "h265_pred_weight_table_parser.h"
#include "h265_st_ref_pic_set_parser.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse slice segment state from the supplied buffer.
std::unique_ptr<H265SliceSegmentLayerParser::SliceSegmentLayerState>
H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
    const uint8_t* data, size_t length, uint32_t nal_unit_type,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSliceSegmentLayer(&bit_buffer, nal_unit_type,
                                bitstream_parser_state);
}

std::unique_ptr<H265SliceSegmentLayerParser::SliceSegmentLayerState>
H265SliceSegmentLayerParser::ParseSliceSegmentLayer(
    rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  // H265 slice segment layer (slice_segment_layer_rbsp()) NAL Unit.
  // Section 7.3.2.9 ("Slice segment layer RBSP syntax") of the H.265
  // standard for a complete description.
  auto slice_segment_layer = std::make_unique<SliceSegmentLayerState>();

  // input parameters
  slice_segment_layer->nal_unit_type = nal_unit_type;

  // slice_segment_header()
  slice_segment_layer->slice_segment_header =
      H265SliceSegmentHeaderParser::ParseSliceSegmentHeader(
          bit_buffer, nal_unit_type, bitstream_parser_state);
  if (slice_segment_layer->slice_segment_header == nullptr) {
    return nullptr;
  }

  // slice_segment_data()
  // rbsp_slice_segment_trailing_bits()

  return slice_segment_layer;
}

#ifdef FDUMP_DEFINE
void H265SliceSegmentLayerParser::SliceSegmentLayerState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "slice_segment_layer {");
  indent_level = indent_level_incr(indent_level);

  if (slice_segment_header != nullptr) {
    fdump_indent_level(outfp, indent_level);
    slice_segment_header->fdump(outfp, indent_level);
  }

  // slice_segment_data()
  // rbsp_slice_segment_trailing_bits()

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

// Unpack RBSP and parse slice segment header state from the supplied buffer.
std::unique_ptr<H265SliceSegmentHeaderParser::SliceSegmentHeaderState>
H265SliceSegmentHeaderParser::ParseSliceSegmentHeader(
    const uint8_t* data, size_t length, uint32_t nal_unit_type,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSliceSegmentHeader(&bit_buffer, nal_unit_type,
                                 bitstream_parser_state);
}

std::unique_ptr<H265SliceSegmentHeaderParser::SliceSegmentHeaderState>
H265SliceSegmentHeaderParser::ParseSliceSegmentHeader(
    rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H265 slice segment header (slice_segment_layer_rbsp()) NAL Unit.
  // Section 7.3.6.1 ("General slice segment header syntax") of the H.265
  // standard for a complete description.
  auto slice_segment_header = std::make_unique<SliceSegmentHeaderState>();

  // input parameters
  slice_segment_header->nal_unit_type = nal_unit_type;

  // first_slice_segment_in_pic_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(slice_segment_header->first_slice_segment_in_pic_flag), 1)) {
    return nullptr;
  }

  if (slice_segment_header->nal_unit_type >= BLA_W_LP &&
      slice_segment_header->nal_unit_type <= RSV_IRAP_VCL23) {
    // no_output_of_prior_pics_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(slice_segment_header->no_output_of_prior_pics_flag), 1)) {
      return nullptr;
    }
  }

  // slice_pic_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(slice_segment_header->slice_pic_parameter_set_id))) {
    return nullptr;
  }
  uint32_t pps_id = slice_segment_header->slice_pic_parameter_set_id;
  if (bitstream_parser_state->pps.find(pps_id) ==
      bitstream_parser_state->pps.end()) {
    // non-existent PPS id
    return nullptr;
  }
  auto& pps = bitstream_parser_state->pps[pps_id];

  uint32_t sps_id =
      bitstream_parser_state->pps[pps_id]->pps_seq_parameter_set_id;
  if (bitstream_parser_state->sps.find(sps_id) ==
      bitstream_parser_state->sps.end()) {
    // non-existent SPS id
    return nullptr;
  }
  auto& sps = bitstream_parser_state->sps[sps_id];

  if (!slice_segment_header->first_slice_segment_in_pic_flag) {
    slice_segment_header->dependent_slice_segments_enabled_flag =
        pps->dependent_slice_segments_enabled_flag;
    if (slice_segment_header->dependent_slice_segments_enabled_flag) {
      // dependent_slice_segment_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->dependent_slice_segment_flag), 1)) {
        return nullptr;
      }
    }
    size_t PicSizeInCtbsY = sps->getPicSizeInCtbsY();
    size_t slice_segment_address_len = static_cast<size_t>(
        std::ceil(std::log2(static_cast<float>(PicSizeInCtbsY))));
    // range: 0 to PicSizeInCtbsY - 1
    // slice_segment_address  u(v)
    if (!bit_buffer->ReadBits(&(slice_segment_header->slice_segment_address),
                              slice_segment_address_len)) {
      return nullptr;
    }
  }

  if (!slice_segment_header->dependent_slice_segment_flag) {
    slice_segment_header->num_extra_slice_header_bits =
        pps->num_extra_slice_header_bits;
    for (uint32_t i = 0; i < slice_segment_header->num_extra_slice_header_bits;
         i++) {
      // slice_reserved_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      slice_segment_header->slice_reserved_flag.push_back(bits_tmp);
    }

    // slice_type  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(slice_segment_header->slice_type))) {
      return nullptr;
    }

    slice_segment_header->output_flag_present_flag =
        pps->output_flag_present_flag;
    if (slice_segment_header->output_flag_present_flag) {
      // pic_output_flag  u(1)
      if (!bit_buffer->ReadBits(&(slice_segment_header->pic_output_flag), 1)) {
        return nullptr;
      }
    }

    slice_segment_header->separate_colour_plane_flag =
        sps->separate_colour_plane_flag;
    if (slice_segment_header->separate_colour_plane_flag == 1) {
      // colour_plane_id  u(2)
      if (!bit_buffer->ReadBits(&(slice_segment_header->colour_plane_id), 2)) {
        return nullptr;
      }
    }

    if (slice_segment_header->nal_unit_type != IDR_W_RADL &&
        slice_segment_header->nal_unit_type != IDR_N_LP) {
      // length of the slice_pic_order_cnt_lsb syntax element is
      // log2_max_pic_order_cnt_lsb_minus4 + 4 bits. The value of the
      // slice_pic_order_cnt_lsb shall be in the range of 0 to
      // MaxPicOrderCntLsb - 1, inclusive.
      slice_segment_header->log2_max_pic_order_cnt_lsb_minus4 =
          sps->log2_max_pic_order_cnt_lsb_minus4;
      size_t slice_pic_order_cnt_lsb_len =
          slice_segment_header->log2_max_pic_order_cnt_lsb_minus4 + 4;
      // slice_pic_order_cnt_lsb  u(v)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->slice_pic_order_cnt_lsb),
              slice_pic_order_cnt_lsb_len)) {
        return nullptr;
      }

      // short_term_ref_pic_set_sps_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->short_term_ref_pic_set_sps_flag), 1)) {
        return nullptr;
      }

      slice_segment_header->num_short_term_ref_pic_sets =
          sps->num_short_term_ref_pic_sets;
      if (slice_segment_header->num_short_term_ref_pic_sets >
          h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX) {
#ifdef FPRINT_ERRORS
        fprintf(stderr,
                "error: slice_segment_header->num_short_term_ref_pic_sets == "
                "%" PRIu32 " > h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX\n",
                slice_segment_header->num_short_term_ref_pic_sets);
#endif  // FPRINT_ERRORS
        return nullptr;
      }

      if (!slice_segment_header->short_term_ref_pic_set_sps_flag) {
        // st_ref_pic_set(num_short_term_ref_pic_sets)
        const auto& st_ref_pic_set = sps->st_ref_pic_set;
        uint32_t max_num_pics = 0;
        if (!sps->getMaxNumPics(&max_num_pics)) {
          return nullptr;
        }
        slice_segment_header->st_ref_pic_set =
            H265StRefPicSetParser::ParseStRefPicSet(
                bit_buffer, slice_segment_header->num_short_term_ref_pic_sets,
                slice_segment_header->num_short_term_ref_pic_sets,
                &st_ref_pic_set, max_num_pics);
        if (slice_segment_header->st_ref_pic_set == nullptr) {
          return nullptr;
        }

      } else if (slice_segment_header->num_short_term_ref_pic_sets > 1) {
        // Ceil(Log2(num_short_term_ref_pic_sets));
        size_t short_term_ref_pic_set_idx_len =
            static_cast<size_t>(std::ceil(std::log2(static_cast<float>(
                slice_segment_header->num_short_term_ref_pic_sets))));
        // short_term_ref_pic_set_idx  u(v)
        if (!bit_buffer->ReadBits(
                &(slice_segment_header->short_term_ref_pic_set_idx),
                short_term_ref_pic_set_idx_len)) {
          return nullptr;
        }
      }

      slice_segment_header->long_term_ref_pics_present_flag =
          sps->long_term_ref_pics_present_flag;
      if (slice_segment_header->long_term_ref_pics_present_flag) {
        slice_segment_header->num_long_term_ref_pics_sps =
            sps->num_long_term_ref_pics_sps;
        if (slice_segment_header->num_long_term_ref_pics_sps > 0) {
          // num_long_term_sps  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(
                  &(slice_segment_header->num_long_term_sps))) {
            return nullptr;
          }
        }

        // num_long_term_pics  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &(slice_segment_header->num_long_term_pics))) {
          return nullptr;
        }

        for (uint32_t i = 0; i < slice_segment_header->num_long_term_sps +
                                     slice_segment_header->num_long_term_pics;
             i++) {
          if (i < slice_segment_header->num_long_term_sps) {
            if (slice_segment_header->num_long_term_ref_pics_sps > 1) {
              // lt_idx_sps[i]  u(v)
              // number of bits used to represent lt_idx_sps[i] is equal to
              // Ceil(Log2(num_long_term_ref_pics_sps)).
              size_t lt_idx_sps_len =
                  static_cast<size_t>(std::ceil(std::log2(static_cast<float>(
                      slice_segment_header->num_long_term_ref_pics_sps))));
              if (!bit_buffer->ReadBits(&bits_tmp, lt_idx_sps_len)) {
                return nullptr;
              }
              slice_segment_header->lt_idx_sps.push_back(bits_tmp);
            }

          } else {
            // poc_lsb_lt[i]  u(v)
            // length of the poc_lsb_lt[i] syntax element is
            // log2_max_pic_order_cnt_lsb_minus4 + 4 bits. [...]
            // value of lt_idx_sps[i] shall be in the range of 0 to
            // num_long_term_ref_pics_sps - 1, inclusive.
            size_t poc_lsb_lt_len =
                slice_segment_header->log2_max_pic_order_cnt_lsb_minus4 + 4;
            // slice_pic_order_cnt_lsb  u(v)
            if (!bit_buffer->ReadBits(&bits_tmp, poc_lsb_lt_len)) {
              return nullptr;
            }
            slice_segment_header->poc_lsb_lt.push_back(bits_tmp);

            // used_by_curr_pic_lt_flag[i]  u(1)
            if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
              return nullptr;
            }
            slice_segment_header->used_by_curr_pic_lt_flag.push_back(bits_tmp);
          }

          // delta_poc_msb_present_flag[i]  u(1)
          if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
            return nullptr;
          }
          slice_segment_header->delta_poc_msb_present_flag.push_back(bits_tmp);

          if (slice_segment_header->delta_poc_msb_present_flag[i]) {
            // delta_poc_msb_cycle_lt[i]  ue(v)
            if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
              return nullptr;
            }
            slice_segment_header->delta_poc_msb_cycle_lt.push_back(golomb_tmp);
          }
        }
      }

      slice_segment_header->sps_temporal_mvp_enabled_flag =
          sps->sps_temporal_mvp_enabled_flag;
      if (slice_segment_header->sps_temporal_mvp_enabled_flag) {
        // slice_temporal_mvp_enabled_flag  u(1)
        if (!bit_buffer->ReadBits(
                &(slice_segment_header->slice_temporal_mvp_enabled_flag), 1)) {
          return nullptr;
        }
      }
    }

    slice_segment_header->sample_adaptive_offset_enabled_flag =
        sps->sample_adaptive_offset_enabled_flag;
    if (slice_segment_header->sample_adaptive_offset_enabled_flag) {
      // slice_sao_luma_flag  u(1)
      if (!bit_buffer->ReadBits(&(slice_segment_header->slice_sao_luma_flag),
                                1)) {
        return nullptr;
      }

      // Depending on the value of separate_colour_plane_flag, the value of
      // the variable ChromaArrayType is assigned as follows:
      // - If separate_colour_plane_flag is equal to 0, ChromaArrayType is
      //   set equal to chroma_format_idc.
      // - Otherwise (separate_colour_plane_flag is equal to 1),
      //   ChromaArrayType is set equal to 0.
      uint32_t chroma_format_idc = sps->chroma_format_idc;
      if (slice_segment_header->separate_colour_plane_flag == 0) {
        slice_segment_header->ChromaArrayType = chroma_format_idc;
      } else {
        slice_segment_header->ChromaArrayType = 0;
      }

      if (slice_segment_header->ChromaArrayType != 0) {
        // slice_sao_chroma_flag  u(1)
        if (!bit_buffer->ReadBits(
                &(slice_segment_header->slice_sao_chroma_flag), 1)) {
          return nullptr;
        }
      }
    }

    if (slice_segment_header->slice_type == SliceType_P ||
        slice_segment_header->slice_type == SliceType_B) {
      // num_ref_idx_active_override_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->num_ref_idx_active_override_flag), 1)) {
        return nullptr;
      }

      if (slice_segment_header->num_ref_idx_active_override_flag) {
        // num_ref_idx_l0_active_minus1  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &(slice_segment_header->num_ref_idx_l0_active_minus1))) {
          return nullptr;
        }

        if (slice_segment_header->slice_type == SliceType_B) {
          // num_ref_idx_l1_active_minus1  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(
                  &(slice_segment_header->num_ref_idx_l1_active_minus1))) {
            return nullptr;
          }
        }
      }

      slice_segment_header->lists_modification_present_flag =
          pps->lists_modification_present_flag;
      // TODO(chemag): calculate NumPicTotalCurr support (page 99)
      slice_segment_header->NumPicTotalCurr = 0;
      if (slice_segment_header->lists_modification_present_flag &&
          slice_segment_header->NumPicTotalCurr > 1) {
        // ref_pic_lists_modification()
        // TODO(chemag): add support for ref_pic_lists_modification()
#ifdef FPRINT_ERRORS
        fprintf(stderr,
                "error: unimplemented ref_pic_lists_modification in "
                "slice_header\n");
#endif  // FPRINT_ERRORS
      }

      if (slice_segment_header->slice_type == SliceType_B) {
        // mvd_l1_zero_flag  u(1)
        if (!bit_buffer->ReadBits(&(slice_segment_header->mvd_l1_zero_flag),
                                  1)) {
          return nullptr;
        }
      }

      slice_segment_header->cabac_init_present_flag =
          pps->cabac_init_present_flag;
      if (slice_segment_header->cabac_init_present_flag) {
        // cabac_init_flag  u(1)
        if (!bit_buffer->ReadBits(&(slice_segment_header->cabac_init_flag),
                                  1)) {
          return nullptr;
        }
      }

      if (slice_segment_header->slice_temporal_mvp_enabled_flag) {
        if (slice_segment_header->slice_type == SliceType_B) {
          // collocated_from_l0_flag  u(1)
          if (!bit_buffer->ReadBits(
                  &(slice_segment_header->collocated_from_l0_flag), 1)) {
            return nullptr;
          }
        }
        if ((slice_segment_header->collocated_from_l0_flag &&
             slice_segment_header->num_ref_idx_l0_active_minus1 > 0) ||
            (!slice_segment_header->collocated_from_l0_flag &&
             slice_segment_header->num_ref_idx_l1_active_minus1 > 0)) {
          // collocated_ref_idx  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(
                  &(slice_segment_header->collocated_ref_idx))) {
            return nullptr;
          }
        }
      }

      slice_segment_header->weighted_pred_flag = pps->weighted_pred_flag;
      slice_segment_header->weighted_bipred_flag = pps->weighted_bipred_flag;
      if ((slice_segment_header->weighted_pred_flag &&
           slice_segment_header->slice_type == SliceType_P) ||
          (slice_segment_header->weighted_bipred_flag &&
           slice_segment_header->slice_type == SliceType_B)) {
        // pred_weight_table()
        slice_segment_header->pred_weight_table =
            H265PredWeightTableParser::ParsePredWeightTable(
                bit_buffer, slice_segment_header->ChromaArrayType,
                slice_segment_header->num_ref_idx_l0_active_minus1);
        if (slice_segment_header->pred_weight_table == nullptr) {
          return nullptr;
        }
      }

      // five_minus_max_num_merge_cand  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(slice_segment_header->five_minus_max_num_merge_cand))) {
        return nullptr;
      }

      slice_segment_header->motion_vector_resolution_control_idc = 0;
      if (sps->sps_scc_extension_flag) {
        if (sps->sps_scc_extension != nullptr) {
          slice_segment_header->motion_vector_resolution_control_idc =
              sps->sps_scc_extension->motion_vector_resolution_control_idc;
        }
      }
      if (slice_segment_header->motion_vector_resolution_control_idc == 2) {
        // use_integer_mv_flag  u(1)
        if (!bit_buffer->ReadBits(&(slice_segment_header->use_integer_mv_flag),
                                  1)) {
          return nullptr;
        }
      }
    }
    // slice_qp_delta  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(slice_segment_header->slice_qp_delta))) {
      return nullptr;
    }

    slice_segment_header->pps_slice_chroma_qp_offsets_present_flag =
        pps->pps_slice_chroma_qp_offsets_present_flag;
    if (slice_segment_header->pps_slice_chroma_qp_offsets_present_flag) {
      // slice_cb_qp_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_segment_header->slice_cb_qp_offset))) {
        return nullptr;
      }

      // slice_cr_qp_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_segment_header->slice_cr_qp_offset))) {
        return nullptr;
      }
    }

    slice_segment_header->pps_slice_act_qp_offsets_present_flag = 0;
    if (pps->pps_scc_extension_flag) {
      slice_segment_header->pps_slice_act_qp_offsets_present_flag =
          pps->pps_scc_extension->pps_slice_act_qp_offsets_present_flag;
    }
    if (slice_segment_header->pps_slice_act_qp_offsets_present_flag) {
      // slice_act_y_qp_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_segment_header->slice_act_y_qp_offset))) {
        return nullptr;
      }

      // slice_act_cb_qp_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_segment_header->slice_act_cb_qp_offset))) {
        return nullptr;
      }

      // slice_act_cr_qp_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_segment_header->slice_act_cr_qp_offset))) {
        return nullptr;
      }
    }

    // TODO(chemag): add support for pps_range_extension()
    // slice_segment_header->chroma_qp_offset_list_enabled_flag =
    //    pps->pps_range_extension->chroma_qp_offset_list_enabled_flag;
    slice_segment_header->chroma_qp_offset_list_enabled_flag = 0;
    if (slice_segment_header->chroma_qp_offset_list_enabled_flag) {
      // cu_chroma_qp_offset_enabled_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->cu_chroma_qp_offset_enabled_flag), 1)) {
        return nullptr;
      }
    }

    slice_segment_header->deblocking_filter_override_enabled_flag =
        pps->deblocking_filter_override_enabled_flag;
    if (slice_segment_header->deblocking_filter_override_enabled_flag) {
      // deblocking_filter_override_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->deblocking_filter_override_flag), 1)) {
        return nullptr;
      }
    }

    if (slice_segment_header->deblocking_filter_override_flag) {
      // slice_deblocking_filter_disabled_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header->slice_deblocking_filter_disabled_flag),
              1)) {
        return nullptr;
      }

      if (!slice_segment_header->slice_deblocking_filter_disabled_flag) {
        // slice_beta_offset_div2 se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(
                &(slice_segment_header->slice_beta_offset_div2))) {
          return nullptr;
        }

        // slice_tc_offset_div2 se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(
                &(slice_segment_header->slice_tc_offset_div2))) {
          return nullptr;
        }
      }
    }

    slice_segment_header->pps_loop_filter_across_slices_enabled_flag =
        pps->pps_loop_filter_across_slices_enabled_flag;
    if (slice_segment_header->pps_loop_filter_across_slices_enabled_flag &&
        (slice_segment_header->slice_sao_luma_flag ||
         slice_segment_header->slice_sao_chroma_flag ||
         !slice_segment_header->slice_deblocking_filter_disabled_flag)) {
      // slice_loop_filter_across_slices_enabled_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(slice_segment_header
                    ->slice_loop_filter_across_slices_enabled_flag),
              1)) {
        return nullptr;
      }
    }
  }

  slice_segment_header->tiles_enabled_flag = pps->tiles_enabled_flag;
  slice_segment_header->entropy_coding_sync_enabled_flag =
      pps->entropy_coding_sync_enabled_flag;
  if (slice_segment_header->tiles_enabled_flag ||
      slice_segment_header->entropy_coding_sync_enabled_flag) {
    // num_entry_point_offsets  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(slice_segment_header->num_entry_point_offsets))) {
      return nullptr;
    }
    if (!slice_segment_header->isValidNumEntryPointOffsets(
            slice_segment_header->num_entry_point_offsets, sps, pps)) {
#ifdef FPRINT_ERRORS
      fprintf(stderr,
              "error: invalid slice_segment_header->num_entry_point_offsets: "
              "%" PRIu32 "\n",
              slice_segment_header->num_entry_point_offsets);
      return nullptr;
#endif  // FPRINT_ERRORS
    }

    if (slice_segment_header->num_entry_point_offsets > 0) {
      // offset_len_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(slice_segment_header->offset_len_minus1))) {
        return nullptr;
      }

      for (uint32_t i = 0; i < slice_segment_header->num_entry_point_offsets;
           i++) {
        // entry_point_offset_minus1[i]  u(v)
        if (!bit_buffer->ReadBits(
                &bits_tmp, slice_segment_header->offset_len_minus1 + 1)) {
          return nullptr;
        }
        slice_segment_header->entry_point_offset_minus1.push_back(bits_tmp);
      }
    }
  }

  slice_segment_header->slice_segment_header_extension_present_flag =
      pps->slice_segment_header_extension_present_flag;
  if (slice_segment_header->slice_segment_header_extension_present_flag) {
    // slice_segment_header_extension_length  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(slice_segment_header->slice_segment_header_extension_length))) {
      return nullptr;
    }
    for (uint32_t i = 0;
         i < slice_segment_header->slice_segment_header_extension_length; i++) {
      // slice_segment_header_extension_data_byte[i]  u(8)
      if (!bit_buffer->ReadBits(&bits_tmp, 8)) {
        return nullptr;
      }
      slice_segment_header->slice_segment_header_extension_data_byte.push_back(
          bits_tmp);
    }
  }

  // TODO(chemag): implement byte_alignment()
  // byte_alignment()

  return slice_segment_header;
}

bool H265SliceSegmentHeaderParser::SliceSegmentHeaderState::
    isValidNumEntryPointOffsets(
        uint32_t num_entry_point_offsets_value,
        std::shared_ptr<struct H265SpsParser::SpsState> sps,
        std::shared_ptr<struct H265PpsParser::PpsState> pps) noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 100
  // The value of num_entry_point_offsets is constrained as follows:
  // - If tiles_enabled_flag is equal to 0 and entropy_coding_sync_enabled_flag
  //   is equal to 1, the value of num_entry_point_offsets shall be in the
  //   range of 0 to PicHeightInCtbsY - 1, inclusive.
  if (tiles_enabled_flag == 0 && entropy_coding_sync_enabled_flag == 1) {
    return (num_entry_point_offsets_value <= (sps->getPicHeightInCtbsY() - 1));
  }

  // - Otherwise, if tiles_enabled_flag is equal to 1 and
  //   entropy_coding_sync_enabled_flag is equal to 0, the value of
  //   num_entry_point_offsets shall be in the range of 0 to
  //   ( num_tile_columns_minus1 + 1 ) * ( num_tile_rows_minus1 + 1 ) - 1,
  //   inclusive.
  if (tiles_enabled_flag == 1 && entropy_coding_sync_enabled_flag == 0) {
    uint32_t max_num_entry_point_offsets =
        ((pps->num_tile_columns_minus1 + 1) * (pps->num_tile_rows_minus1 + 1) -
         1);
    return (num_entry_point_offsets_value <= max_num_entry_point_offsets);
  }

  // - Otherwise, when tiles_enabled_flag is equal to 1 and
  //   entropy_coding_sync_enabled_flag is equal to 1, the value of
  //   num_entry_point_offsets shall be in the range of 0 to
  // ( num_tile_columns_minus1 + 1 ) * PicHeightInCtbsY - 1, inclusive.
  if (tiles_enabled_flag == 1 && entropy_coding_sync_enabled_flag == 1) {
    uint32_t max_num_entry_point_offsets =
        ((pps->num_tile_columns_minus1 + 1) * (sps->getPicHeightInCtbsY() - 1));
    return (num_entry_point_offsets_value <= max_num_entry_point_offsets);
  }

  // TODO(chemag): not clear what to do in other cases. As the same paragraph
  // contains "When not present, the value of num_entry_point_offsets is
  // inferred to be equal to 0.", we will check for zero here.
  return (num_entry_point_offsets_value == 0);
}

#ifdef FDUMP_DEFINE
void H265SliceSegmentHeaderParser::SliceSegmentHeaderState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "slice_segment_header {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "first_slice_segment_in_pic_flag: %i",
          first_slice_segment_in_pic_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "no_output_of_prior_pics_flag: %i",
          no_output_of_prior_pics_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_pic_parameter_set_id: %i", slice_pic_parameter_set_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "dependent_slice_segment_flag: %i",
          dependent_slice_segment_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_segment_address: %i", slice_segment_address);

  if (!dependent_slice_segment_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_reserved_flag {");
    for (const uint32_t& v : slice_reserved_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_type: %i", slice_type);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pic_output_flag: %i", pic_output_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "colour_plane_id: %i", colour_plane_id);

    if (nal_unit_type != IDR_W_RADL && nal_unit_type != IDR_N_LP) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_pic_order_cnt_lsb: %i", slice_pic_order_cnt_lsb);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "short_term_ref_pic_set_sps_flag: %i",
              short_term_ref_pic_set_sps_flag);

      if (!short_term_ref_pic_set_sps_flag) {
        fdump_indent_level(outfp, indent_level);

        if (st_ref_pic_set) {
          st_ref_pic_set->fdump(outfp, indent_level);
        }
      } else if (num_short_term_ref_pic_sets > 1) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "short_term_ref_pic_set_idx: %i",
                short_term_ref_pic_set_idx);
      }

      if (long_term_ref_pics_present_flag) {
        if (num_long_term_ref_pics_sps > 0) {
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "num_long_term_sps: %i", num_long_term_sps);
        }

        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "num_long_term_pics: %i", num_long_term_pics);

        for (uint32_t i = 0; i < num_long_term_sps + num_long_term_pics; i++) {
          if (i < num_long_term_sps) {
            if (num_long_term_ref_pics_sps > 1) {
              fdump_indent_level(outfp, indent_level);
              fprintf(outfp, "lt_idx_sps {");
              for (const uint32_t& v : lt_idx_sps) {
                fprintf(outfp, " %i", v);
              }
              fprintf(outfp, " }");
            }

          } else {
            fdump_indent_level(outfp, indent_level);
            fprintf(outfp, "poc_lsb_lt {");
            for (const uint32_t& v : poc_lsb_lt) {
              fprintf(outfp, " %i", v);
            }
            fprintf(outfp, " }");

            fdump_indent_level(outfp, indent_level);
            fprintf(outfp, "used_by_curr_pic_lt_flag {");
            for (const uint32_t& v : used_by_curr_pic_lt_flag) {
              fprintf(outfp, " %i", v);
            }
            fprintf(outfp, " }");
          }

          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "delta_poc_msb_present_flag {");
          for (const uint32_t& v : delta_poc_msb_present_flag) {
            fprintf(outfp, " %i", v);
          }
          fprintf(outfp, " }");

          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "delta_poc_msb_cycle_lt {");
          for (const uint32_t& v : delta_poc_msb_cycle_lt) {
            fprintf(outfp, " %i", v);
          }
          fprintf(outfp, " }");
        }
      }

      if (sps_temporal_mvp_enabled_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "slice_temporal_mvp_enabled_flag: %i",
                slice_temporal_mvp_enabled_flag);
      }
    }

    if (sample_adaptive_offset_enabled_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_sao_luma_flag: %i", slice_sao_luma_flag);

      if (ChromaArrayType != 0) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "slice_sao_chroma_flag: %i", slice_sao_chroma_flag);
      }
    }

    if (slice_type == SliceType_P || slice_type == SliceType_B) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "num_ref_idx_active_override_flag: %i",
              num_ref_idx_active_override_flag);

      if (num_ref_idx_active_override_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "num_ref_idx_l0_active_minus1: %i",
                num_ref_idx_l0_active_minus1);

        if (slice_type == SliceType_B) {
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "num_ref_idx_l1_active_minus1: %i",
                  num_ref_idx_l1_active_minus1);
        }
      }

      if (lists_modification_present_flag && NumPicTotalCurr > 1) {
        // TODO(chemag): add support for ref_pic_lists_modification()
      }

      if (slice_type == SliceType_B) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "mvd_l1_zero_flag: %i", mvd_l1_zero_flag);
      }

      if (cabac_init_present_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "cabac_init_flag: %i", cabac_init_flag);
      }

      if (slice_temporal_mvp_enabled_flag) {
        if (slice_type == SliceType_B) {
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "collocated_from_l0_flag: %i",
                  collocated_from_l0_flag);
        }

        if ((collocated_from_l0_flag && num_ref_idx_l0_active_minus1 > 0) ||
            (!collocated_from_l0_flag && num_ref_idx_l1_active_minus1 > 0)) {
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "collocated_ref_idx: %i", collocated_ref_idx);
        }
      }

      if ((weighted_pred_flag && slice_type == SliceType_P) ||
          (weighted_bipred_flag && slice_type == SliceType_B)) {
        fdump_indent_level(outfp, indent_level);
        pred_weight_table->fdump(outfp, indent_level);
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "five_minus_max_num_merge_cand: %i",
              five_minus_max_num_merge_cand);

      if (motion_vector_resolution_control_idc == 2) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "use_integer_mv_flag: %i", use_integer_mv_flag);
      }
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_qp_delta: %i", slice_qp_delta);

    if (pps_slice_chroma_qp_offsets_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_cb_qp_offset: %i", slice_cb_qp_offset);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_cr_qp_offset: %i", slice_cr_qp_offset);
    }

    if (pps_slice_act_qp_offsets_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_act_y_qp_offset: %i", slice_act_y_qp_offset);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_act_cb_qp_offset: %i", slice_act_cb_qp_offset);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_act_cr_qp_offset: %i", slice_act_cr_qp_offset);
    }

    if (chroma_qp_offset_list_enabled_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "cu_chroma_qp_offset_enabled_flag: %i",
              cu_chroma_qp_offset_enabled_flag);
    }

    if (deblocking_filter_override_enabled_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "deblocking_filter_override_flag: %i",
              deblocking_filter_override_flag);
    }

    if (deblocking_filter_override_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_deblocking_filter_disabled_flag: %i",
              slice_deblocking_filter_disabled_flag);

      if (!slice_deblocking_filter_disabled_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "slice_beta_offset_div2: %i", slice_beta_offset_div2);

        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "slice_tc_offset_div2: %i", slice_tc_offset_div2);
      }
    }

    if (pps_loop_filter_across_slices_enabled_flag &&
        (slice_sao_luma_flag || slice_sao_chroma_flag ||
         !slice_deblocking_filter_disabled_flag)) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_loop_filter_across_slices_enabled_flag: %i",
              slice_loop_filter_across_slices_enabled_flag);
    }
  }

  if (tiles_enabled_flag || entropy_coding_sync_enabled_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_entry_point_offsets: %i", num_entry_point_offsets);

    if (num_entry_point_offsets > 0) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "offset_len_minus1: %i", offset_len_minus1);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "entry_point_offset_minus1 {");
      for (const uint32_t& v : entry_point_offset_minus1) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
  }

  if (slice_segment_header_extension_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_segment_header_extension_length: %i",
            slice_segment_header_extension_length);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_segment_header_extension_data_byte {");
    for (const uint32_t& v : slice_segment_header_extension_data_byte) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  // byte_alignment()

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
