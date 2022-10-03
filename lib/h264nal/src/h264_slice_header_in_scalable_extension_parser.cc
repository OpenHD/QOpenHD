/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_slice_header_in_scalable_extension_parser.h"

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
#include "h264_nal_unit_header_parser.h"
#include "h264_pps_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "h264_sps_parser.h"
#include "h264_sps_svc_extension_parser.h"
#include "h264_subset_sps_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse slice header state from the supplied buffer.
std::unique_ptr<H264SliceHeaderInScalableExtensionParser::
                    SliceHeaderInScalableExtensionState>
H264SliceHeaderInScalableExtensionParser::ParseSliceHeaderInScalableExtension(
    const uint8_t* data, size_t length,
    H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSliceHeaderInScalableExtension(&bit_buffer, nal_unit_header,
                                             bitstream_parser_state);
}

std::unique_ptr<H264SliceHeaderInScalableExtensionParser::
                    SliceHeaderInScalableExtensionState>
H264SliceHeaderInScalableExtensionParser::ParseSliceHeaderInScalableExtension(
    rtc::BitBuffer* bit_buffer,
    H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  int32_t sgolomb_tmp;

  // H264 slice header (slice_header_in_scalable_extension()) NAL Unit.
  // Section G.7.3.3.4 ("Slice header in scalable extension syntax") of
  // the H.264 standard for a complete description.
  auto shise = std::make_unique<SliceHeaderInScalableExtensionState>();

  // input parameters
  shise->nal_ref_idc = nal_unit_header.nal_ref_idc;
  shise->nal_unit_type = nal_unit_header.nal_unit_type;

  // first_mb_in_slice  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(shise->first_mb_in_slice))) {
    return nullptr;
  }

  // slice_type  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(shise->slice_type))) {
    return nullptr;
  }

  // pic_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(shise->pic_parameter_set_id))) {
    return nullptr;
  }

  // get pps_id, sps_id, and subset_sps_id and check their existence
  uint32_t pps_id = shise->pic_parameter_set_id;
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

  uint32_t subset_sps_id = pps->seq_parameter_set_id;
  if (bitstream_parser_state->subset_sps.find(subset_sps_id) ==
      bitstream_parser_state->subset_sps.end()) {
    // non-existent SPS id
    return nullptr;
  }
  auto& subset_sps = bitstream_parser_state->subset_sps[subset_sps_id];
  auto& subset_sps_svc_extension = subset_sps->seq_parameter_set_svc_extension;
  if (subset_sps_svc_extension == nullptr) {
    // slice_header_in_scalable_extension() (defined inside
    // slice_layer_extension_rbsp()) requires accessing
    // seq_parameter_set_svc_extension(() inside the subset SPS
    return nullptr;
  }

  shise->separate_colour_plane_flag = sps_data->separate_colour_plane_flag;
  if (shise->separate_colour_plane_flag == 1) {
    // colour_plane_id  u(2)
    if (!bit_buffer->ReadBits(&(shise->colour_plane_id), 2)) {
      return nullptr;
    }
  }

  // frame_num  u(v)
  shise->log2_max_frame_num_minus4 = sps_data->log2_max_frame_num_minus4;
  uint32_t frame_num_len =
      shise->getFrameNumLen(shise->log2_max_frame_num_minus4);
  if (!bit_buffer->ReadBits(&(shise->frame_num), frame_num_len)) {
    return nullptr;
  }

  shise->frame_mbs_only_flag = sps_data->frame_mbs_only_flag;
  if (!shise->frame_mbs_only_flag) {
    // field_pic_flag  u(1)
    if (!bit_buffer->ReadBits(&(shise->field_pic_flag), 1)) {
      return nullptr;
    }
    if (shise->field_pic_flag) {
      // bottom_field_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->bottom_field_flag), 1)) {
        return nullptr;
      }
    }
  }

  uint32_t IdrPicFlag = ((shise->nal_unit_type == 5) ? 1 : 0);
  if (IdrPicFlag) {
    // idr_pic_id  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(shise->idr_pic_id))) {
      return nullptr;
    }
  }

  shise->pic_order_cnt_type = sps_data->pic_order_cnt_type;
  if (shise->pic_order_cnt_type == 0) {
    uint32_t log2_max_pic_order_cnt_lsb_minus4 =
        sps_data->log2_max_pic_order_cnt_lsb_minus4;
    // pic_order_cnt_lsb  u(v)
    uint32_t pic_order_cnt_lsb_len =
        shise->getPicOrderCntLsbLen(log2_max_pic_order_cnt_lsb_minus4);
    if (!bit_buffer->ReadBits(&(shise->pic_order_cnt_lsb),
                              pic_order_cnt_lsb_len)) {
      return nullptr;
    }

    shise->bottom_field_pic_order_in_frame_present_flag =
        pps->bottom_field_pic_order_in_frame_present_flag;
    if (shise->bottom_field_pic_order_in_frame_present_flag &&
        !shise->field_pic_flag) {
      // delta_pic_order_cnt_bottom  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->delta_pic_order_cnt_bottom))) {
        return nullptr;
      }
    }
  }

  shise->delta_pic_order_always_zero_flag =
      sps_data->delta_pic_order_always_zero_flag;
  if ((shise->pic_order_cnt_type == 1) &&
      (!shise->delta_pic_order_always_zero_flag)) {
    // delta_pic_order_cnt[0]  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
      return nullptr;
    }
    shise->delta_pic_order_cnt.push_back(sgolomb_tmp);

    if (shise->bottom_field_pic_order_in_frame_present_flag &&
        !shise->field_pic_flag) {
      // delta_pic_order_cnt[1]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      shise->delta_pic_order_cnt.push_back(sgolomb_tmp);
    }
  }

  shise->redundant_pic_cnt_present_flag = pps->redundant_pic_cnt_present_flag;
  if (shise->redundant_pic_cnt_present_flag) {
    // redundant_pic_cnt  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(shise->redundant_pic_cnt))) {
      return nullptr;
    }
  }

  auto& nal_unit_header_svc_extension =
      nal_unit_header.nal_unit_header_svc_extension;
  if (nal_unit_header_svc_extension == nullptr) {
    // non-existent nal_unit_header_svc_extension
    return nullptr;
  }

  shise->quality_id = nal_unit_header_svc_extension->quality_id;
  if (shise->quality_id == 0) {
    if ((shise->slice_type == SvcSliceType::EBa) ||
        (shise->slice_type == SvcSliceType::EBb)) {  // slice_type == EB
      // direct_spatial_mv_pred_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->direct_spatial_mv_pred_flag), 1)) {
        return nullptr;
      }
    }

    if ((shise->slice_type == SvcSliceType::EPa) ||
        (shise->slice_type == SvcSliceType::EPb) ||
        (shise->slice_type == SvcSliceType::EBa) ||
        (shise->slice_type ==
         SvcSliceType::EBb)) {  // slice_type == EP || slice_type == EB
      // num_ref_idx_active_override_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->num_ref_idx_active_override_flag),
                                1)) {
        return nullptr;
      }

      if (shise->num_ref_idx_active_override_flag) {
        // num_ref_idx_l0_active_minus1  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &(shise->num_ref_idx_l0_active_minus1))) {
          return nullptr;
        }

        if ((shise->slice_type == SvcSliceType::EBa) ||
            (shise->slice_type == SvcSliceType::EBb)) {  // slice_type == EB
          // num_ref_idx_l1_active_minus1  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(
                  &(shise->num_ref_idx_l1_active_minus1))) {
            return nullptr;
          }
        }
      }
    }

    // ref_pic_list_modification(slice_type)
    shise->ref_pic_list_modification =
        H264RefPicListModificationParser::ParseRefPicListModification(
            bit_buffer, shise->slice_type);
    if (shise->ref_pic_list_modification == nullptr) {
      return nullptr;
    }

    shise->weighted_pred_flag = pps->weighted_pred_flag;
    shise->weighted_bipred_idc = pps->weighted_bipred_idc;

    if ((shise->weighted_pred_flag &&
         ((shise->slice_type == SvcSliceType::EPa) ||
          (shise->slice_type == SvcSliceType::EPb))) ||
        ((shise->weighted_bipred_idc == 1) &&
         ((shise->slice_type == SvcSliceType::EBa) ||
          (shise->slice_type == SvcSliceType::EBb)))) {
      shise->no_inter_layer_pred_flag =
          nal_unit_header_svc_extension->no_inter_layer_pred_flag;
      if (!shise->no_inter_layer_pred_flag) {
        // base_pred_weight_table_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->base_pred_weight_table_flag), 1)) {
          return nullptr;
        }
      }
      if (shise->no_inter_layer_pred_flag ||
          !shise->base_pred_weight_table_flag) {
        // pred_weight_table(slice_type, num_ref_idx_l0_active_minus1,
        // num_ref_idx_l1_active_minus1)
        shise->ChromaArrayType = sps_data->getChromaArrayType();
        shise->pred_weight_table =
            H264PredWeightTableParser::ParsePredWeightTable(
                bit_buffer, shise->ChromaArrayType, shise->slice_type,
                shise->num_ref_idx_l0_active_minus1,
                shise->num_ref_idx_l1_active_minus1);
        if (shise->pred_weight_table == nullptr) {
          return nullptr;
        }
      }
    }

    if (shise->nal_ref_idc != 0) {
      // dec_ref_pic_marking(nal_unit_type)
      shise->dec_ref_pic_marking =
          H264DecRefPicMarkingParser::ParseDecRefPicMarking(
              bit_buffer, shise->nal_unit_type);
      if (shise->dec_ref_pic_marking == nullptr) {
        return nullptr;
      }

      shise->slice_header_restriction_flag =
          subset_sps_svc_extension->slice_header_restriction_flag;
      if (!shise->slice_header_restriction_flag) {
        // store_ref_base_pic_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->store_ref_base_pic_flag), 1)) {
          return nullptr;
        }

        shise->use_ref_base_pic_flag =
            nal_unit_header_svc_extension->use_ref_base_pic_flag;
        shise->idr_flag = nal_unit_header_svc_extension->idr_flag;
        if ((shise->use_ref_base_pic_flag || shise->store_ref_base_pic_flag) &&
            !shise->idr_flag) {
          // dec_ref_base_pic_marking()
#ifdef FPRINT_ERRORS
          fprintf(stderr, "error: dec_ref_base_pic_marking undefined\n");
#endif  // FPRINT_ERRORS
          return nullptr;
        }
      }
    }
  }

  shise->entropy_coding_mode_flag = pps->entropy_coding_mode_flag;
  if (shise->entropy_coding_mode_flag &&
      (shise->slice_type != SvcSliceType::EIa) &&
      (shise->slice_type != SvcSliceType::EIb)) {
    // cabac_init_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(shise->cabac_init_idc))) {
      return nullptr;
    }
  }

  // slice_qp_delta  se(v)
  if (!bit_buffer->ReadSignedExponentialGolomb(&(shise->slice_qp_delta))) {
    return nullptr;
  }

  shise->deblocking_filter_control_present_flag =
      pps->deblocking_filter_control_present_flag;
  if (shise->deblocking_filter_control_present_flag) {
    // disable_deblocking_filter_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(shise->disable_deblocking_filter_idc))) {
      return nullptr;
    }

    if (shise->disable_deblocking_filter_idc != 1) {
      // slice_alpha_c0_offset_div2  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->slice_alpha_c0_offset_div2))) {
        return nullptr;
      }

      // slice_beta_offset_div2  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->slice_beta_offset_div2))) {
        return nullptr;
      }
    }
  }

  shise->num_slice_groups_minus1 = pps->num_slice_groups_minus1;
  shise->slice_group_map_type = pps->slice_group_map_type;
  if ((shise->num_slice_groups_minus1 > 0) &&
      (shise->slice_group_map_type >= 3) &&
      (shise->slice_group_map_type <= 5)) {
    // slice_group_change_cycle  u(v)
    shise->pic_width_in_mbs_minus1 = sps_data->pic_width_in_mbs_minus1;
    shise->pic_height_in_map_units_minus1 =
        sps_data->pic_height_in_map_units_minus1;
    shise->slice_group_change_rate_minus1 = pps->slice_group_change_rate_minus1;
    uint32_t slice_group_change_cycle_len = shise->getSliceGroupChangeCycleLen(
        shise->pic_width_in_mbs_minus1, shise->pic_height_in_map_units_minus1,
        shise->slice_group_change_rate_minus1);
    // Rec. ITU-T H.264 (2012) Page 67, Section 7.4.3
    if (!bit_buffer->ReadBits(&(shise->slice_group_change_cycle),
                              slice_group_change_cycle_len)) {
      return nullptr;
    }
  }

  if (!shise->no_inter_layer_pred_flag && shise->quality_id == 0) {
    // ref_layer_dq_id  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(shise->ref_layer_dq_id))) {
      return nullptr;
    }

    shise->inter_layer_deblocking_filter_control_present_flag =
        subset_sps_svc_extension
            ->inter_layer_deblocking_filter_control_present_flag;
    if (shise->inter_layer_deblocking_filter_control_present_flag) {
      // disable_inter_layer_deblocking_filter_idc  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(shise->disable_inter_layer_deblocking_filter_idc))) {
        return nullptr;
      }

      if (shise->disable_inter_layer_deblocking_filter_idc != 1) {
        // inter_layer_slice_alpha_c0_offset_div2  se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(
                &(shise->inter_layer_slice_alpha_c0_offset_div2))) {
          return nullptr;
        }

        // inter_layer_slice_beta_offset_div2  se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(
                &(shise->inter_layer_slice_beta_offset_div2))) {
          return nullptr;
        }
      }
    }

    // constrained_intra_resampling_flag  u(1)
    if (!bit_buffer->ReadBits(&(shise->constrained_intra_resampling_flag), 1)) {
      return nullptr;
    }

    shise->extended_spatial_scalability_idc =
        subset_sps_svc_extension->extended_spatial_scalability_idc;
    if (shise->extended_spatial_scalability_idc == 2) {
      shise->ChromaArrayType = sps_data->getChromaArrayType();
      if (shise->ChromaArrayType > 0) {
        // ref_layer_chroma_phase_x_plus1_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->ref_layer_chroma_phase_x_plus1_flag),
                                  1)) {
          return nullptr;
        }

        // ref_layer_chroma_phase_y_plus1  u(2)
        if (!bit_buffer->ReadBits(&(shise->ref_layer_chroma_phase_y_plus1),
                                  2)) {
          return nullptr;
        }
      }
      // scaled_ref_layer_left_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->scaled_ref_layer_left_offset))) {
        return nullptr;
      }

      // scaled_ref_layer_top_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->scaled_ref_layer_top_offset))) {
        return nullptr;
      }

      // scaled_ref_layer_right_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->scaled_ref_layer_right_offset))) {
        return nullptr;
      }

      // scaled_ref_layer_bottom_offset  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(
              &(shise->scaled_ref_layer_bottom_offset))) {
        return nullptr;
      }
    }
  }

  if (!shise->no_inter_layer_pred_flag) {
    // slice_skip_flag  u(1)
    if (!bit_buffer->ReadBits(&(shise->slice_skip_flag), 1)) {
      return nullptr;
    }

    if (shise->slice_skip_flag) {
      // num_mbs_in_slice_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(shise->num_mbs_in_slice_minus1))) {
        return nullptr;
      }

    } else {
      // adaptive_base_mode_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->adaptive_base_mode_flag), 1)) {
        return nullptr;
      }

      if (!shise->adaptive_base_mode_flag) {
        // default_base_mode_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->default_base_mode_flag), 1)) {
          return nullptr;
        }
      }
      if (!shise->default_base_mode_flag) {
        // adaptive_motion_prediction_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->adaptive_motion_prediction_flag),
                                  1)) {
          return nullptr;
        }

        if (!shise->adaptive_motion_prediction_flag) {
          // default_motion_prediction_flag  u(1)
          if (!bit_buffer->ReadBits(&(shise->default_motion_prediction_flag),
                                    1)) {
            return nullptr;
          }
        }
      }
      // adaptive_residual_prediction_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->adaptive_residual_prediction_flag),
                                1)) {
        return nullptr;
      }

      if (!shise->adaptive_residual_prediction_flag) {
        // default_residual_prediction_flag  u(1)
        if (!bit_buffer->ReadBits(&(shise->default_residual_prediction_flag),
                                  1)) {
          return nullptr;
        }
      }
    }
    shise->adaptive_tcoeff_level_prediction_flag =
        subset_sps_svc_extension->adaptive_tcoeff_level_prediction_flag;
    if (shise->adaptive_tcoeff_level_prediction_flag) {
      // tcoeff_level_prediction_flag  u(1)
      if (!bit_buffer->ReadBits(&(shise->tcoeff_level_prediction_flag), 1)) {
        return nullptr;
      }
    }
  }

  if (!shise->slice_header_restriction_flag && !shise->slice_skip_flag) {
    // scan_idx_start  u(4)
    if (!bit_buffer->ReadBits(&(shise->scan_idx_start), 4)) {
      return nullptr;
    }

    // scan_idx_end  u(4)
    if (!bit_buffer->ReadBits(&(shise->scan_idx_end), 4)) {
      return nullptr;
    }
  }

  return shise;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getFrameNumLen(
        uint32_t log2_max_frame_num_minus4) noexcept {
  // Rec. ITU-T H.264 (2012) Page 62, Section 7.4.3
  // frame_num is used as an identifier for pictures and shall be
  // represented by log2_max_frame_num_minus4 + 4 bits in the bitstream.
  return log2_max_frame_num_minus4 + 4;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getPicOrderCntLsbLen(
        uint32_t log2_max_pic_order_cnt_lsb_minus4) noexcept {
  // Rec. ITU-T H.264 (2012) Page 64, Section 7.4.3
  // The size of the pic_order_cnt_lsb syntax element is
  // log2_max_pic_order_cnt_lsb_minus4 + 4 bits.
  return log2_max_pic_order_cnt_lsb_minus4 + 4;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getSliceGroupChangeCycleLen(
        uint32_t pic_width_in_mbs_minus1,
        uint32_t pic_height_in_map_units_minus1,
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

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getPicWidthInMbs(
        uint32_t pic_width_in_mbs_minus1) noexcept {
  return pic_width_in_mbs_minus1 + 1;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getPicHeightInMapUnits(
        uint32_t pic_height_in_map_units_minus1) noexcept {
  return pic_height_in_map_units_minus1 + 1;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getPicSizeInMapUnits(
        uint32_t pic_width_in_mbs_minus1,
        uint32_t pic_height_in_map_units_minus1) noexcept {
  uint32_t PicWidthInMbs = getPicWidthInMbs(pic_width_in_mbs_minus1);
  uint32_t PicHeightInMapUnits =
      getPicHeightInMapUnits(pic_height_in_map_units_minus1);
  return PicWidthInMbs * PicHeightInMapUnits;
}

uint32_t H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::getSliceGroupChangeRate(
        uint32_t slice_group_change_rate_minus1) noexcept {
  return slice_group_change_rate_minus1 + 1;
}

#ifdef FDUMP_DEFINE
void H264SliceHeaderInScalableExtensionParser::
    SliceHeaderInScalableExtensionState::fdump(FILE* outfp,
                                               int indent_level) const {
  fprintf(outfp, "slice_header_in_scalable_extension {");
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

  if (idr_flag == 1) {
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

  if (quality_id == 0) {
    if ((slice_type == SvcSliceType::EBa) ||
        (slice_type == SvcSliceType::EBb)) {  // slice_type == EB
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "direct_spatial_mv_pred_flag: %i",
              direct_spatial_mv_pred_flag);
    }

    if ((slice_type == SvcSliceType::EPa) ||
        (slice_type == SvcSliceType::EPb) ||
        (slice_type == SvcSliceType::EBa) ||
        (slice_type == SvcSliceType::EBb)) {
      // slice_type == EP || slice_type == EB
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "num_ref_idx_active_override_flag: %i",
              num_ref_idx_active_override_flag);

      if (num_ref_idx_active_override_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "num_ref_idx_l0_active_minus1: %i",
                num_ref_idx_l0_active_minus1);
        if ((slice_type == SvcSliceType::EBa) ||
            (slice_type == SvcSliceType::EBb)) {  // slice_type == EB
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "num_ref_idx_l1_active_minus1: %i",
                  num_ref_idx_l1_active_minus1);
        }
      }
    }

    fdump_indent_level(outfp, indent_level);
    ref_pic_list_modification->fdump(outfp, indent_level);

    if ((weighted_pred_flag && ((slice_type == SvcSliceType::EPa) ||
                                (slice_type == SvcSliceType::EPb))) ||
        ((weighted_bipred_idc == 1) && ((slice_type == SvcSliceType::EBa) ||
                                        (slice_type == SvcSliceType::EBb)))) {
      if (!no_inter_layer_pred_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "base_pred_weight_table_flag: %i",
                base_pred_weight_table_flag);
      }
      if (no_inter_layer_pred_flag || !base_pred_weight_table_flag) {
        fdump_indent_level(outfp, indent_level);
        pred_weight_table->fdump(outfp, indent_level);
      }
    }

    if (nal_ref_idc != 0) {
      fdump_indent_level(outfp, indent_level);
      dec_ref_pic_marking->fdump(outfp, indent_level);

      if (!slice_header_restriction_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "store_ref_base_pic_flag: %i", store_ref_base_pic_flag);
        if ((use_ref_base_pic_flag || store_ref_base_pic_flag) && !idr_flag) {
#ifdef FPRINT_ERRORS
          fprintf(stderr, "error: dec_ref_base_pic_marking undefined\n");
#endif  // FPRINT_ERRORS
        }
      }
    }
  }

  if (entropy_coding_mode_flag && (slice_type != SvcSliceType::EIa) &&
      (slice_type != SvcSliceType::EIb)) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "cabac_init_idc: %i", cabac_init_idc);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_qp_delta: %i", slice_qp_delta);

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

  if (!no_inter_layer_pred_flag && quality_id == 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "ref_layer_dq_id: %i", ref_layer_dq_id);

    if (inter_layer_deblocking_filter_control_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "disable_inter_layer_deblocking_filter_idc: %i",
              disable_inter_layer_deblocking_filter_idc);

      if (disable_inter_layer_deblocking_filter_idc != 1) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "inter_layer_slice_alpha_c0_offset_div2: %i",
                inter_layer_slice_alpha_c0_offset_div2);
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "inter_layer_slice_beta_offset_div2: %i",
                inter_layer_slice_beta_offset_div2);
      }
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "constrained_intra_resampling_flag: %i",
            constrained_intra_resampling_flag);

    if (extended_spatial_scalability_idc == 2) {
      if (ChromaArrayType > 0) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "ref_layer_chroma_phase_x_plus1_flag: %i",
                ref_layer_chroma_phase_x_plus1_flag);
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "ref_layer_chroma_phase_y_plus1: %i",
                ref_layer_chroma_phase_y_plus1);
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "scaled_ref_layer_left_offset: %i",
              scaled_ref_layer_left_offset);
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "scaled_ref_layer_top_offset: %i",
              scaled_ref_layer_top_offset);
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "scaled_ref_layer_right_offset: %i",
              scaled_ref_layer_right_offset);
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "scaled_ref_layer_bottom_offset: %i",
              scaled_ref_layer_bottom_offset);
    }
  }

  if (!no_inter_layer_pred_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_skip_flag: %i", slice_skip_flag);

    if (slice_skip_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "num_mbs_in_slice_minus1: %i", num_mbs_in_slice_minus1);
    } else {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "adaptive_base_mode_flag: %i", adaptive_base_mode_flag);
      if (!adaptive_base_mode_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "default_base_mode_flag: %i", default_base_mode_flag);
      }
      if (!default_base_mode_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "adaptive_motion_prediction_flag: %i",
                adaptive_motion_prediction_flag);

        if (!adaptive_motion_prediction_flag) {
          fdump_indent_level(outfp, indent_level);
          fprintf(outfp, "default_motion_prediction_flag: %i",
                  default_motion_prediction_flag);
        }
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "adaptive_residual_prediction_flag: %i",
              adaptive_residual_prediction_flag);

      if (!adaptive_residual_prediction_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "default_residual_prediction_flag: %i",
                default_residual_prediction_flag);
      }
    }

    if (adaptive_tcoeff_level_prediction_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "tcoeff_level_prediction_flag: %i",
              tcoeff_level_prediction_flag);
    }
  }

  if (!slice_header_restriction_flag && !slice_skip_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "scan_idx_start: %i", scan_idx_start);
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "scan_idx_end: %i", scan_idx_end);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
