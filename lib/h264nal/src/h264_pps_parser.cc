/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_pps_parser.h"

#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse PPS state from the supplied buffer.
std::shared_ptr<H264PpsParser::PpsState> H264PpsParser::ParsePps(
    const uint8_t* data, size_t length, uint32_t chroma_format_idc) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePps(&bit_buffer, chroma_format_idc);
}

std::shared_ptr<H264PpsParser::PpsState> H264PpsParser::ParsePps(
    rtc::BitBuffer* bit_buffer, uint32_t chroma_format_idc) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H264 PPS NAL Unit (pic_parameter_set_rbsp()) parser.
  // Section 7.3.2.2 ("Picture parameter set RBSP syntax") of the H.264
  // standard for a complete description.
  auto pps = std::make_shared<PpsState>();

  // input parameters
  pps->chroma_format_idc = chroma_format_idc;

  // pic_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(pps->pic_parameter_set_id))) {
    return nullptr;
  }

  // seq_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(pps->seq_parameter_set_id))) {
    return nullptr;
  }

  // entropy_coding_mode_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps->entropy_coding_mode_flag), 1)) {
    return nullptr;
  }

  // bottom_field_pic_order_in_frame_present_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(pps->bottom_field_pic_order_in_frame_present_flag), 1)) {
    return nullptr;
  }

  // num_slice_groups_minus1  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(pps->num_slice_groups_minus1))) {
    return nullptr;
  }

  if (pps->num_slice_groups_minus1 > 0) {
    // slice_group_map_type  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(pps->slice_group_map_type))) {
      return nullptr;
    }

    if (pps->slice_group_map_type == 0) {
      for (uint32_t iGroup = 0; iGroup < pps->num_slice_groups_minus1;
           iGroup++) {
        // run_length_minus1[iGroup]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        pps->run_length_minus1.push_back(golomb_tmp);
      }

    } else if (pps->slice_group_map_type == 2) {
      for (uint32_t iGroup = 0; iGroup < pps->num_slice_groups_minus1;
           iGroup++) {
        // top_left[iGroup]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        pps->top_left.push_back(golomb_tmp);

        // bottom_right[iGroup]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        pps->bottom_right.push_back(golomb_tmp);
      }

    } else if ((pps->slice_group_map_type == 3) ||
               (pps->slice_group_map_type == 4) ||
               (pps->slice_group_map_type == 5)) {
      // slice_group_change_direction_flag  u(1)
      if (!bit_buffer->ReadBits(&(pps->slice_group_change_direction_flag), 1)) {
        return nullptr;
      }

      // slice_group_change_rate_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(pps->slice_group_change_rate_minus1))) {
        return nullptr;
      }

    } else if (pps->slice_group_map_type == 6) {
      // pic_size_in_map_units_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(pps->pic_size_in_map_units_minus1))) {
        return nullptr;
      }

      // slice_group_id  u(v)
      uint32_t slice_group_id_len = pps->getSliceGroupIdLen();
      if (!bit_buffer->ReadBits(&bits_tmp, slice_group_id_len)) {
        return nullptr;
      }
      pps->slice_group_id.push_back(bits_tmp);
    }
  }

  // num_ref_idx_l0_active_minus1  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(pps->num_ref_idx_l0_active_minus1))) {
    return nullptr;
  }

  // num_ref_idx_l1_active_minus1  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(pps->num_ref_idx_l1_active_minus1))) {
    return nullptr;
  }

  // weighted_pred_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps->weighted_pred_flag), 1)) {
    return nullptr;
  }

  // weighted_bipred_idc  u(2)
  if (!bit_buffer->ReadBits(&(pps->weighted_bipred_idc), 2)) {
    return nullptr;
  }

  // pic_init_qp_minus26  se(v)
  if (!bit_buffer->ReadSignedExponentialGolomb(&(pps->pic_init_qp_minus26))) {
    return nullptr;
  }

  // pic_init_qs_minus26  se(v)
  if (!bit_buffer->ReadSignedExponentialGolomb(&(pps->pic_init_qs_minus26))) {
    return nullptr;
  }

  // chroma_qp_index_offset  se(v)
  if (!bit_buffer->ReadSignedExponentialGolomb(
          &(pps->chroma_qp_index_offset))) {
    return nullptr;
  }

  // deblocking_filter_control_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps->deblocking_filter_control_present_flag),
                            1)) {
    return nullptr;
  }

  // constrained_intra_pred_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps->constrained_intra_pred_flag), 1)) {
    return nullptr;
  }

  // redundant_pic_cnt_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps->redundant_pic_cnt_present_flag), 1)) {
    return nullptr;
  }

  if (more_rbsp_data(bit_buffer)) {
    // transform_8x8_mode_flag  u(1)
    if (!bit_buffer->ReadBits(&(pps->transform_8x8_mode_flag), 1)) {
      return nullptr;
    }

    // pic_scaling_matrix_present_flag  u(1)
    if (!bit_buffer->ReadBits(&(pps->pic_scaling_matrix_present_flag), 1)) {
      return nullptr;
    }

    if (pps->pic_scaling_matrix_present_flag) {
      uint32_t max_pic_scaling_list_present_flag =
          6 + ((chroma_format_idc != 3) ? 2 : 6) * pps->transform_8x8_mode_flag;
      for (uint32_t i = 0; i < max_pic_scaling_list_present_flag; ++i) {
        // pic_scaling_list_present_flag  u(1)
        if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
          return nullptr;
        }
        pps->pic_scaling_list_present_flag.push_back(bits_tmp);
        if (pps->pic_scaling_list_present_flag[i]) {
          // scaling_list()
          if (i < 6) {
            (void)pps->scaling_list(bit_buffer, i, pps->ScalingList4x4, 16,
                                    pps->UseDefaultScalingMatrix4x4Flag);
          } else {
            (void)pps->scaling_list(bit_buffer, i - 6, pps->ScalingList8x8, 64,
                                    pps->UseDefaultScalingMatrix4x4Flag);
          }
        }
      }
    }

    // second_chroma_qp_index_offset  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(pps->second_chroma_qp_index_offset))) {
      return nullptr;
    }
  }

  rbsp_trailing_bits(bit_buffer);

  return pps;
}

uint32_t H264PpsParser::PpsState::getSliceGroupIdLen() noexcept {
  // Rec. ITU-T H.264 (2012) Page 70, Section 7.4.2.2
  // slice_group_id[i] identifies a slice group of the i-th slice group
  // map unit in raster scan order. The size of the slice_group_id[i]
  // syntax element is `Ceil(Log2(num_slice_groups_minus1 + 1))` bits.
  // The value of slice_group_id[i] shall be in the range of 0 to
  // num_slice_groups_minus1, inclusive.
  return static_cast<uint32_t>(
      std::ceil(std::log2(1.0 * num_slice_groups_minus1 + 1)));
}

// Section 7.3.2.1.1.1
bool H264PpsParser::PpsState::scaling_list(
    rtc::BitBuffer* bit_buffer, uint32_t i, std::vector<uint32_t>& scalingList,
    uint32_t sizeOfScalingList,
    std::vector<uint32_t>& useDefaultScalingMatrixFlag) noexcept {
  uint32_t lastScale = 8;
  uint32_t nextScale = 8;
  for (uint32_t j = 0; j < sizeOfScalingList; j++) {
    if (nextScale != 0) {
      // delta_scale  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&delta_scale)) {
        return false;
      }
      nextScale = (lastScale + (delta_scale) + 256) % 256;
      // make sure vector has ith element
      while (useDefaultScalingMatrixFlag.size() <= i) {
        useDefaultScalingMatrixFlag.push_back(0);
      }
      useDefaultScalingMatrixFlag[i] = (j == 0 && nextScale == 0);
    }
    // make sure vector has jth element
    while (scalingList.size() <= j) {
      scalingList.push_back(0);
    }
    scalingList[j] = (nextScale == 0) ? lastScale : nextScale;
    lastScale = scalingList[j];
  }
  return true;
}

#ifdef FDUMP_DEFINE
void H264PpsParser::PpsState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "pps {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_parameter_set_id: %i", pic_parameter_set_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "seq_parameter_set_id: %i", seq_parameter_set_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "entropy_coding_mode_flag: %i", entropy_coding_mode_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bottom_field_pic_order_in_frame_present_flag: %i",
          bottom_field_pic_order_in_frame_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "num_slice_groups_minus1: %i", num_slice_groups_minus1);

  if (num_slice_groups_minus1 > 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "slice_group_map_type: %i", slice_group_map_type);

    if (slice_group_map_type == 0) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "run_length_minus1 {");
      for (const uint32_t& v : run_length_minus1) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

    } else if (slice_group_map_type == 2) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "top_left {");
      for (const uint32_t& v : top_left) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "bottom_right {");
      for (const uint32_t& v : bottom_right) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

    } else if ((slice_group_map_type == 3) || (slice_group_map_type == 4) ||
               (slice_group_map_type == 5)) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_group_change_direction_flag: %i",
              slice_group_change_direction_flag);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_group_change_rate_minus1: %i",
              slice_group_change_rate_minus1);

    } else if (slice_group_map_type == 6) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "pic_size_in_map_units_minus1: %i",
              pic_size_in_map_units_minus1);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "slice_group_id {");
      for (const uint32_t& v : slice_group_id) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "num_ref_idx_l0_active_minus1: %i",
          num_ref_idx_l0_active_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "num_ref_idx_l1_active_minus1: %i",
          num_ref_idx_l1_active_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "weighted_pred_flag: %i", weighted_pred_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "weighted_bipred_idc: %i", weighted_bipred_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_init_qp_minus26: %i", pic_init_qp_minus26);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_init_qs_minus26: %i", pic_init_qs_minus26);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "chroma_qp_index_offset: %i", chroma_qp_index_offset);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "deblocking_filter_control_present_flag: %i",
          deblocking_filter_control_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constrained_intra_pred_flag: %i",
          constrained_intra_pred_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "redundant_pic_cnt_present_flag: %i",
          redundant_pic_cnt_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "transform_8x8_mode_flag: %i", transform_8x8_mode_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_scaling_matrix_present_flag: %i",
          pic_scaling_matrix_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_scaling_list_present_flag {");
  for (const uint32_t& v : pic_scaling_list_present_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "ScalingList4x4 {");
  for (const uint32_t& v : ScalingList4x4) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "UseDefaultScalingMatrix4x4Flag {");
  for (const uint32_t& v : UseDefaultScalingMatrix4x4Flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "ScalingList8x8 {");
  for (const uint32_t& v : ScalingList8x8) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "UseDefaultScalingMatrix8x8Flag {");
  for (const uint32_t& v : UseDefaultScalingMatrix8x8Flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "delta_scale: %i", delta_scale);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "second_chroma_qp_index_offset: %i",
          second_chroma_qp_index_offset);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
