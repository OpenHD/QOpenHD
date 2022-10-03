/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_slice_header_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_pps_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "h264_sps_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse slice header state from the supplied buffer.
std::unique_ptr<H264SliceHeaderParser::SliceHeaderState>
H264SliceHeaderParser::ParseSliceHeader(
    const uint8_t* data, size_t length, uint32_t nal_ref_idc,
    uint32_t nal_unit_type,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSliceHeader(&bit_buffer, nal_ref_idc, nal_unit_type,
                          bitstream_parser_state);
}

std::unique_ptr<H264SliceHeaderParser::SliceHeaderState>
H264SliceHeaderParser::ParseSliceHeader(
    rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc, uint32_t nal_unit_type,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  int32_t sgolomb_tmp;

  // H264 slice header (slice_header()) NAL Unit.
  // Section 7.3.3 ("Slice Header syntax") of the H.264
  // standard for a complete description.
  auto slice_header = std::make_unique<SliceHeaderState>();

  // input parameters
  slice_header->nal_ref_idc = nal_ref_idc;
  slice_header->nal_unit_type = nal_unit_type;

  // first_mb_in_slice  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(slice_header->first_mb_in_slice))) {
    return nullptr;
  }

  // slice_type  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(slice_header->slice_type))) {
    return nullptr;
  }

  // pic_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(slice_header->pic_parameter_set_id))) {
    return nullptr;
  }

  // get pps_id and sps_id and check their existence
  uint32_t pps_id = slice_header->pic_parameter_set_id;
  if (bitstream_parser_state->pps.find(pps_id) ==
      bitstream_parser_state->pps.end()) {
    // non-existent PPS id
    return nullptr;
  }
  auto& pps = bitstream_parser_state->pps[pps_id];

  uint32_t sps_id = pps->seq_parameter_set_id;
  if (bitstream_parser_state->sps.find(sps_id) ==
      bitstream_parser_state->sps.end()) {
    // non-existent SPS id
    return nullptr;
  }
  auto& sps = bitstream_parser_state->sps[sps_id];
  auto& sps_data = sps->sps_data;

  slice_header->separate_colour_plane_flag =
      sps_data->separate_colour_plane_flag;
  if (slice_header->separate_colour_plane_flag) {
    // colour_plane_id  u(2)
    if (!bit_buffer->ReadBits(&(slice_header->colour_plane_id), 2)) {
      return nullptr;
    }
  }

  // frame_num  u(v)
  slice_header->log2_max_frame_num_minus4 = sps_data->log2_max_frame_num_minus4;
  uint32_t frame_num_len =
      slice_header->getFrameNumLen(slice_header->log2_max_frame_num_minus4);
  if (!bit_buffer->ReadBits(&(slice_header->frame_num), frame_num_len)) {
    return nullptr;
  }

  slice_header->frame_mbs_only_flag = sps_data->frame_mbs_only_flag;
  if (!slice_header->frame_mbs_only_flag) {
    // field_pic_flag  u(1)
    if (!bit_buffer->ReadBits(&(slice_header->field_pic_flag), 1)) {
      return nullptr;
    }
    if (slice_header->field_pic_flag) {
      // bottom_field_flag  u(1)
      if (!bit_buffer->ReadBits(&(slice_header->bottom_field_flag), 1)) {
        return nullptr;
      }
    }
  }

  uint32_t IdrPicFlag = ((slice_header->nal_unit_type == 5) ? 1 : 0);
  if (IdrPicFlag) {
    // idr_pic_id  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(slice_header->idr_pic_id))) {
      return nullptr;
    }
  }

  slice_header->pic_order_cnt_type = sps_data->pic_order_cnt_type;
  if (slice_header->pic_order_cnt_type == 0) {
    uint32_t log2_max_pic_order_cnt_lsb_minus4 =
        sps_data->log2_max_pic_order_cnt_lsb_minus4;
    // pic_order_cnt_lsb  u(v)
    uint32_t pic_order_cnt_lsb_len =
        slice_header->getPicOrderCntLsbLen(log2_max_pic_order_cnt_lsb_minus4);
    if (!bit_buffer->ReadBits(&(slice_header->pic_order_cnt_lsb),
                              pic_order_cnt_lsb_len)) {
      return nullptr;
    }

    slice_header->bottom_field_pic_order_in_frame_present_flag =
        pps->bottom_field_pic_order_in_frame_present_flag;
    if (slice_header->bottom_field_pic_order_in_frame_present_flag &&
        !slice_header->field_pic_flag) {
      // delta_pic_order_cnt_bottom  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_header->delta_pic_order_cnt_bottom))) {
        return nullptr;
      }
    }
  }

  slice_header->delta_pic_order_always_zero_flag =
      sps_data->delta_pic_order_always_zero_flag;
  if ((slice_header->pic_order_cnt_type == 1) &&
      (!slice_header->delta_pic_order_always_zero_flag)) {
    // delta_pic_order_cnt[0]  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
      return nullptr;
    }
    slice_header->delta_pic_order_cnt.push_back(sgolomb_tmp);

    if (slice_header->bottom_field_pic_order_in_frame_present_flag &&
        !slice_header->field_pic_flag) {
      // delta_pic_order_cnt[1]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      slice_header->delta_pic_order_cnt.push_back(sgolomb_tmp);
    }
  }

  slice_header->redundant_pic_cnt_present_flag =
      pps->redundant_pic_cnt_present_flag;
  if (slice_header->redundant_pic_cnt_present_flag) {
    // redundant_pic_cnt  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(slice_header->redundant_pic_cnt))) {
      return nullptr;
    }
  }

  if ((slice_header->slice_type == SliceType::B) ||
      (slice_header->slice_type == SliceType::B_ALL)) {  // slice_type == B
    // direct_spatial_mv_pred_flag  u(1)
    if (!bit_buffer->ReadBits(&(slice_header->direct_spatial_mv_pred_flag),
                              1)) {
      return nullptr;
    }
  }

  if ((slice_header->slice_type == SliceType::P) ||
      (slice_header->slice_type == SliceType::P_ALL) ||
      (slice_header->slice_type == SliceType::SP) ||
      (slice_header->slice_type == SliceType::SP_ALL) ||
      (slice_header->slice_type == SliceType::B) ||
      (slice_header->slice_type ==
       SliceType::B_ALL)) {  // slice_type == P || slice_type == SP ||
                             // slice_type == B
    // num_ref_idx_active_override_flag  u(1)
    if (!bit_buffer->ReadBits(&(slice_header->num_ref_idx_active_override_flag),
                              1)) {
      return nullptr;
    }

    if (slice_header->num_ref_idx_active_override_flag) {
      // num_ref_idx_l0_active_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(slice_header->num_ref_idx_l0_active_minus1))) {
        return nullptr;
      }

      if ((slice_header->slice_type == SliceType::B) ||
          (slice_header->slice_type == SliceType::B_ALL)) {  // slice_type == B
        // num_ref_idx_l1_active_minus1  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &(slice_header->num_ref_idx_l1_active_minus1))) {
          return nullptr;
        }
      }
    }
  }

  if (slice_header->nal_unit_type == 20) {
    // ref_pic_list_mvc_modification()
#ifdef FPRINT_ERRORS
    // TODO(chemag): add support for ref_pic_list_mvc_modification()
    fprintf(stderr,
            "error: unimplemented ref_pic_list_mvc_modification in pps\n");
#endif  // FPRINT_ERRORS
  } else {
    // ref_pic_list_modification(slice_type)
    slice_header->ref_pic_list_modification =
        H264RefPicListModificationParser::ParseRefPicListModification(
            bit_buffer, slice_header->slice_type);
    if (slice_header->ref_pic_list_modification == nullptr) {
      return nullptr;
    }
  }

  slice_header->weighted_pred_flag = pps->weighted_pred_flag;
  slice_header->weighted_bipred_idc = pps->weighted_bipred_idc;

  if ((slice_header->weighted_pred_flag &&
       ((slice_header->slice_type == SliceType::P) ||
        (slice_header->slice_type == SliceType::P_ALL) ||
        (slice_header->slice_type == SliceType::SP) ||
        (slice_header->slice_type == SliceType::SP_ALL))) ||
      ((slice_header->weighted_bipred_idc == 1) &&
       ((slice_header->slice_type == SliceType::B) ||
        (slice_header->slice_type == SliceType::B_ALL)))) {
    // pred_weight_table(slice_type, num_ref_idx_l0_active_minus1,
    // num_ref_idx_l1_active_minus1)
    uint32_t ChromaArrayType = sps_data->getChromaArrayType();
    slice_header->pred_weight_table =
        H264PredWeightTableParser::ParsePredWeightTable(
            bit_buffer, ChromaArrayType, slice_header->slice_type,
            slice_header->num_ref_idx_l0_active_minus1,
            slice_header->num_ref_idx_l1_active_minus1);
    if (slice_header->pred_weight_table == nullptr) {
      return nullptr;
    }
  }

  if (slice_header->nal_ref_idc != 0) {
    // dec_ref_pic_marking(nal_unit_type)
    slice_header->dec_ref_pic_marking =
        H264DecRefPicMarkingParser::ParseDecRefPicMarking(
            bit_buffer, slice_header->nal_unit_type);
    if (slice_header->dec_ref_pic_marking == nullptr) {
      return nullptr;
    }
  }

  slice_header->entropy_coding_mode_flag = pps->entropy_coding_mode_flag;
  if (slice_header->entropy_coding_mode_flag &&
      (slice_header->slice_type != SliceType::I) &&
      (slice_header->slice_type != SliceType::I_ALL) &&
      (slice_header->slice_type != SliceType::SI) &&
      (slice_header->slice_type != SliceType::SI_ALL)) {
    // cabac_init_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(slice_header->cabac_init_idc))) {
      return nullptr;
    }
  }

  // slice_qp_delta  se(v)
  if (!bit_buffer->ReadSignedExponentialGolomb(
          &(slice_header->slice_qp_delta))) {
    return nullptr;
  }

  if ((slice_header->slice_type == SliceType::SP) ||
      (slice_header->slice_type == SliceType::SP_ALL) ||
      (slice_header->slice_type == SliceType::SI) ||
      (slice_header->slice_type == SliceType::SI_ALL)) {
    if ((slice_header->slice_type == SliceType::SP) ||
        (slice_header->slice_type == SliceType::SP_ALL)) {
      // sp_for_switch_flag  u(1)
      if (!bit_buffer->ReadBits(&(slice_header->sp_for_switch_flag), 1)) {
        return nullptr;
      }
    }

    // slice_qs_delta  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(slice_header->slice_qs_delta))) {
      return nullptr;
    }
  }

  slice_header->deblocking_filter_control_present_flag =
      pps->deblocking_filter_control_present_flag;
  if (slice_header->deblocking_filter_control_present_flag) {
    // disable_deblocking_filter_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(slice_header->disable_deblocking_filter_idc))) {
      return nullptr;
    }

    if (slice_header->disable_deblocking_filter_idc != 1) {
      // slice_alpha_c0_offset_div2  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_header->slice_alpha_c0_offset_div2))) {
        return nullptr;
      }

      // slice_beta_offset_div2  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(slice_header->slice_beta_offset_div2))) {
        return nullptr;
      }
    }
  }

  slice_header->num_slice_groups_minus1 = pps->num_slice_groups_minus1;
  slice_header->slice_group_map_type = pps->slice_group_map_type;
  if ((slice_header->num_slice_groups_minus1 > 0) &&
      (slice_header->slice_group_map_type >= 3) &&
      (slice_header->slice_group_map_type <= 5)) {
    // slice_group_change_cycle  u(v)
    slice_header->pic_width_in_mbs_minus1 = sps_data->pic_width_in_mbs_minus1;
    slice_header->pic_height_in_map_units_minus1 =
        sps_data->pic_height_in_map_units_minus1;
    slice_header->slice_group_change_rate_minus1 =
        pps->slice_group_change_rate_minus1;
    uint32_t slice_group_change_cycle_len =
        slice_header->getSliceGroupChangeCycleLen(
            slice_header->pic_width_in_mbs_minus1,
            slice_header->pic_height_in_map_units_minus1,
            slice_header->slice_group_change_rate_minus1);
    // Rec. ITU-T H.264 (2012) Page 67, Section 7.4.3
    if (!bit_buffer->ReadBits(&(slice_header->slice_group_change_cycle),
                              slice_group_change_cycle_len)) {
      return nullptr;
    }
  }

  return slice_header;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getFrameNumLen(
    uint32_t log2_max_frame_num_minus4) noexcept {
  // Rec. ITU-T H.264 (2012) Page 62, Section 7.4.3
  // frame_num is used as an identifier for pictures and shall be
  // represented by log2_max_frame_num_minus4 + 4 bits in the bitstream.
  return log2_max_frame_num_minus4 + 4;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getPicOrderCntLsbLen(
    uint32_t log2_max_pic_order_cnt_lsb_minus4) noexcept {
  // Rec. ITU-T H.264 (2012) Page 64, Section 7.4.3
  // The size of the pic_order_cnt_lsb syntax element is
  // log2_max_pic_order_cnt_lsb_minus4 + 4 bits.
  return log2_max_pic_order_cnt_lsb_minus4 + 4;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getSliceGroupChangeCycleLen(
    uint32_t pic_width_in_mbs_minus1, uint32_t pic_height_in_map_units_minus1,
    uint32_t slice_group_change_rate_minus1) noexcept {
  // Rec. ITU-T H.264 (2012) Page 67, Section 7.4.3
  // The value of slice_group_change_cycle is represented in the bitstream
  // by the following number of bits
  // Ceil(Log2(PicSizeInMapUnits ÷ SliceGroupChangeRate + 1)) (7-21)
  uint32_t PicSizeInMapUnits = getPicSizeInMapUnits(
      pic_width_in_mbs_minus1, pic_height_in_map_units_minus1);
  uint32_t SliceGroupChangeRate =
      getSliceGroupChangeRate(slice_group_change_rate_minus1);
  return std::ceil(
      std::log2(1.0 * (PicSizeInMapUnits / SliceGroupChangeRate) + 1));
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getPicWidthInMbs(
    uint32_t pic_width_in_mbs_minus1) noexcept {
  return pic_width_in_mbs_minus1 + 1;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getPicHeightInMapUnits(
    uint32_t pic_height_in_map_units_minus1) noexcept {
  return pic_height_in_map_units_minus1 + 1;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getPicSizeInMapUnits(
    uint32_t pic_width_in_mbs_minus1,
    uint32_t pic_height_in_map_units_minus1) noexcept {
  uint32_t PicWidthInMbs = getPicWidthInMbs(pic_width_in_mbs_minus1);
  uint32_t PicHeightInMapUnits =
      getPicHeightInMapUnits(pic_height_in_map_units_minus1);
  return PicWidthInMbs * PicHeightInMapUnits;
}

uint32_t H264SliceHeaderParser::SliceHeaderState::getSliceGroupChangeRate(
    uint32_t slice_group_change_rate_minus1) noexcept {
  return slice_group_change_rate_minus1 + 1;
}

#ifdef FDUMP_DEFINE
void H264SliceHeaderParser::SliceHeaderState::fdump(FILE* outfp,
                                                    int indent_level) const {
  fprintf(outfp, "slice_header {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "first_mb_in_slice: %i", first_mb_in_slice);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_type: %i", slice_type);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_parameter_set_id: %i", pic_parameter_set_id);

  if (separate_colour_plane_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "colour_plane_id: %i", colour_plane_id);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "frame_num: %i", frame_num);

  if (!frame_mbs_only_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "field_pic_flag: %i", field_pic_flag);

    if (field_pic_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "bottom_field_flag: %i", bottom_field_flag);
    }
  }

  if (nal_unit_type == 5) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "idr_pic_id: %i", idr_pic_id);
  }

  if (pic_order_cnt_type == 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pic_order_cnt_lsb: %i", pic_order_cnt_lsb);

    if (bottom_field_pic_order_in_frame_present_flag && !field_pic_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "delta_pic_order_cnt_bottom: %i",
              delta_pic_order_cnt_bottom);
    }
  }

  if (pic_order_cnt_type == 1 && !delta_pic_order_always_zero_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_pic_order_cnt {");
    for (const int32_t& v : delta_pic_order_cnt) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  if (redundant_pic_cnt_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "redundant_pic_cnt: %i", redundant_pic_cnt);
  }

  if ((slice_type == SliceType::B) ||
      (slice_type == SliceType::B_ALL)) {  // slice_type == B
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "direct_spatial_mv_pred_flag: %i",
            direct_spatial_mv_pred_flag);
  }

  if ((slice_type == SliceType::P) || (slice_type == SliceType::P_ALL) ||
      (slice_type == SliceType::SP) || (slice_type == SliceType::SP_ALL) ||
      (slice_type == SliceType::B) ||
      (slice_type == SliceType::B_ALL)) {  // slice_type == P || slice_type ==
                                           // SP || slice_type == B
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_ref_idx_active_override_flag: %i",
            num_ref_idx_active_override_flag);

    if (num_ref_idx_active_override_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "num_ref_idx_l0_active_minus1: %i",
              num_ref_idx_l0_active_minus1);
      if ((slice_type == SliceType::B) ||
          (slice_type == SliceType::B_ALL)) {  // slice_type == B
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "num_ref_idx_l1_active_minus1: %i",
                num_ref_idx_l1_active_minus1);
      }
    }
  }

  fdump_indent_level(outfp, indent_level);
  ref_pic_list_modification->fdump(outfp, indent_level);

  if ((weighted_pred_flag &&
       ((slice_type == SliceType::P) || (slice_type == SliceType::P_ALL) ||
        (slice_type == SliceType::SP) || (slice_type == SliceType::SP_ALL))) ||
      ((weighted_bipred_idc == 1) &&
       ((slice_type == SliceType::B) || (slice_type == SliceType::B_ALL)))) {
    fdump_indent_level(outfp, indent_level);
    pred_weight_table->fdump(outfp, indent_level);
  }

  if (nal_ref_idc != 0) {
    fdump_indent_level(outfp, indent_level);
    dec_ref_pic_marking->fdump(outfp, indent_level);
  }

  if (entropy_coding_mode_flag && (slice_type != SliceType::I) &&
      (slice_type != SliceType::I_ALL) && (slice_type != SliceType::SI) &&
      (slice_type != SliceType::SI_ALL)) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "cabac_init_idc: %i", cabac_init_idc);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_qp_delta: %i", slice_qp_delta);

  if ((slice_type == SliceType::SP) || (slice_type == SliceType::SP_ALL) ||
      (slice_type == SliceType::SI) || (slice_type == SliceType::SI_ALL)) {
    if ((slice_type == SliceType::SP) || (slice_type == SliceType::SP_ALL)) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sp_for_switch_flag: %i", sp_for_switch_flag);
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_qs_delta: %i", slice_qs_delta);
  }

  if (deblocking_filter_control_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "disable_deblocking_filter_idc: %i",
            disable_deblocking_filter_idc);

    if (disable_deblocking_filter_idc != 1) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_alpha_c0_offset_div2: %i",
              slice_alpha_c0_offset_div2);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_beta_offset_div2: %i", slice_beta_offset_div2);
    }
  }

  if ((num_slice_groups_minus1 > 0) && (slice_group_map_type >= 3) &&
      (slice_group_map_type <= 5)) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_group_change_cycle: %i", slice_group_change_cycle);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
