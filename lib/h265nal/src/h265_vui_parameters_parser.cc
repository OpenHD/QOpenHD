/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_vui_parameters_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"
#include "h265_hrd_parameters_parser.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse VUI Parameters state from the supplied buffer.
std::unique_ptr<H265VuiParametersParser::VuiParametersState>
H265VuiParametersParser::ParseVuiParameters(
    const uint8_t* data, size_t length,
    uint32_t sps_max_sub_layers_minus1) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseVuiParameters(&bit_buffer, sps_max_sub_layers_minus1);
}

std::unique_ptr<H265VuiParametersParser::VuiParametersState>
H265VuiParametersParser::ParseVuiParameters(
    rtc::BitBuffer* bit_buffer, uint32_t sps_max_sub_layers_minus1) noexcept {
  // H265 vui_parameters() parser.
  // Section E.2.1 ("VUI parameters syntax") of the H.265 standard for
  // a complete description.
  auto vui = std::make_unique<VuiParametersState>();

  // input
  vui->sps_max_sub_layers_minus1 = sps_max_sub_layers_minus1;

  // aspect_ratio_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->aspect_ratio_info_present_flag), 1)) {
    return nullptr;
  }

  if (vui->aspect_ratio_info_present_flag) {
    // aspect_ratio_idc  u(8)
    if (!bit_buffer->ReadBits(&(vui->aspect_ratio_idc), 8)) {
      return nullptr;
    }
    if (vui->aspect_ratio_idc == AR_EXTENDED_SAR) {
      // sar_width  u(16)
      if (!bit_buffer->ReadBits(&(vui->sar_width), 16)) {
        return nullptr;
      }
      // sar_height  u(16)
      if (!bit_buffer->ReadBits(&(vui->sar_height), 16)) {
        return nullptr;
      }
    }
  }

  // overscan_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->overscan_info_present_flag), 1)) {
    return nullptr;
  }

  if (vui->overscan_info_present_flag) {
    // overscan_appropriate_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->overscan_appropriate_flag), 1)) {
      return nullptr;
    }
  }

  // video_signal_type_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->video_signal_type_present_flag), 1)) {
    return nullptr;
  }

  if (vui->video_signal_type_present_flag) {
    // video_format  u(3)
    if (!bit_buffer->ReadBits(&(vui->video_format), 3)) {
      return nullptr;
    }
    // video_full_range_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->video_full_range_flag), 1)) {
      return nullptr;
    }
    // colour_description_present_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->colour_description_present_flag), 1)) {
      return nullptr;
    }
    if (vui->colour_description_present_flag) {
      // colour_primaries  u(8)
      if (!bit_buffer->ReadBits(&(vui->colour_primaries), 8)) {
        return nullptr;
      }
      // transfer_characteristics  u(8)
      if (!bit_buffer->ReadBits(&(vui->transfer_characteristics), 8)) {
        return nullptr;
      }
      // matrix_coeffs  u(8)
      if (!bit_buffer->ReadBits(&(vui->matrix_coeffs), 8)) {
        return nullptr;
      }
    }
  }

  // chroma_loc_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->chroma_loc_info_present_flag), 1)) {
    return nullptr;
  }
  if (vui->chroma_loc_info_present_flag) {
    // chroma_sample_loc_type_top_field  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->chroma_sample_loc_type_top_field))) {
      return nullptr;
    }
    // chroma_sample_loc_type_bottom_field  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->chroma_sample_loc_type_bottom_field))) {
      return nullptr;
    }
  }

  // neutral_chroma_indication_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->neutral_chroma_indication_flag), 1)) {
    return nullptr;
  }

  // field_seq_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->field_seq_flag), 1)) {
    return nullptr;
  }

  // frame_field_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->frame_field_info_present_flag), 1)) {
    return nullptr;
  }

  // default_display_window_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->default_display_window_flag), 1)) {
    return nullptr;
  }
  if (vui->default_display_window_flag) {
    // def_disp_win_left_offset ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(vui->def_disp_win_left_offset))) {
      return nullptr;
    }
    // def_disp_win_right_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(vui->def_disp_win_right_offset))) {
      return nullptr;
    }
    // def_disp_win_top_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(vui->def_disp_win_top_offset))) {
      return nullptr;
    }
    // def_disp_win_bottom_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->def_disp_win_bottom_offset))) {
      return nullptr;
    }
  }

  // vui_timing_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->vui_timing_info_present_flag), 1)) {
    return nullptr;
  }
  if (vui->vui_timing_info_present_flag) {
    // vui_num_units_in_tick  u(32)
    if (!bit_buffer->ReadBits(&(vui->vui_num_units_in_tick), 32)) {
      return nullptr;
    }
    // vui_time_scale  u(32)
    if (!bit_buffer->ReadBits(&(vui->vui_time_scale), 32)) {
      return nullptr;
    }
    // vui_poc_proportional_to_timing_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->vui_poc_proportional_to_timing_flag), 1)) {
      return nullptr;
    }
    if (vui->vui_poc_proportional_to_timing_flag) {
      // vui_num_ticks_poc_diff_one_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(vui->vui_num_ticks_poc_diff_one_minus1))) {
        return nullptr;
      }
    }
    // vui_hrd_parameters_present_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->vui_hrd_parameters_present_flag), 1)) {
      return nullptr;
    }
    if (vui->vui_hrd_parameters_present_flag) {
      // hrd_parameters(1, sps_max_sub_layers_minus1)
      vui->hrd_parameters = H265HrdParametersParser::ParseHrdParameters(
          bit_buffer, 1, vui->sps_max_sub_layers_minus1);
      if (vui->hrd_parameters == nullptr) {
        return nullptr;
      }
    }
  }

  // bitstream_restriction_flag  u(1)
  if (!bit_buffer->ReadBits(&(vui->bitstream_restriction_flag), 1)) {
    return nullptr;
  }
  if (vui->bitstream_restriction_flag) {
    // tiles_fixed_structure_flag u(1)
    if (!bit_buffer->ReadBits(&(vui->tiles_fixed_structure_flag), 1)) {
      return nullptr;
    }
    // motion_vectors_over_pic_boundaries_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->motion_vectors_over_pic_boundaries_flag),
                              1)) {
      return nullptr;
    }
    // restricted_ref_pic_lists_flag  u(1)
    if (!bit_buffer->ReadBits(&(vui->restricted_ref_pic_lists_flag), 1)) {
      return nullptr;
    }
    // min_spatial_segmentation_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->min_spatial_segmentation_idc))) {
      return nullptr;
    }
    // max_bytes_per_pic_denom  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(vui->max_bytes_per_pic_denom))) {
      return nullptr;
    }
    // max_bits_per_min_cu_denom  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(vui->max_bits_per_min_cu_denom))) {
      return nullptr;
    }
    // log2_max_mv_length_horizontal  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->log2_max_mv_length_horizontal))) {
      return nullptr;
    }
    // log2_max_mv_length_vertical  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(vui->log2_max_mv_length_vertical))) {
      return nullptr;
    }
  }

  return vui;
}

#ifdef FDUMP_DEFINE
void H265VuiParametersParser::VuiParametersState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "vui_parameters {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "aspect_ratio_info_present_flag: %i",
          aspect_ratio_info_present_flag);

  if (aspect_ratio_info_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "aspect_ratio_idc: %i", aspect_ratio_idc);

    if (aspect_ratio_idc == AR_EXTENDED_SAR) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sar_width: %i", sar_width);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sar_height: %i", sar_height);
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "overscan_info_present_flag: %i", overscan_info_present_flag);

  if (overscan_info_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "overscan_appropriate_flag: %i", overscan_appropriate_flag);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "video_signal_type_present_flag: %i",
          video_signal_type_present_flag);

  if (video_signal_type_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "video_format: %i", video_format);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "video_full_range_flag: %i", video_full_range_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "colour_description_present_flag: %i",
            colour_description_present_flag);

    if (colour_description_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "colour_primaries: %i", colour_primaries);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "transfer_characteristics: %i", transfer_characteristics);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "matrix_coeffs: %i", matrix_coeffs);
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "chroma_loc_info_present_flag: %i",
          chroma_loc_info_present_flag);

  if (chroma_loc_info_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_sample_loc_type_top_field: %i",
            chroma_sample_loc_type_top_field);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_sample_loc_type_bottom_field: %i",
            chroma_sample_loc_type_bottom_field);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "neutral_chroma_indication_flag: %i",
          neutral_chroma_indication_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "field_seq_flag: %i", field_seq_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "frame_field_info_present_flag: %i",
          frame_field_info_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "default_display_window_flag: %i",
          default_display_window_flag);

  if (default_display_window_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "def_disp_win_left_offset: %i", def_disp_win_left_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "def_disp_win_right_offset: %i", def_disp_win_right_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "def_disp_win_top_offset: %i", def_disp_win_top_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "def_disp_win_bottom_offset: %i",
            def_disp_win_bottom_offset);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "vui_timing_info_present_flag: %i",
          vui_timing_info_present_flag);

  if (vui_timing_info_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "vui_num_units_in_tick: %i", vui_num_units_in_tick);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "vui_time_scale: %i", vui_time_scale);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "vui_poc_proportional_to_timing_flag: %i",
            vui_poc_proportional_to_timing_flag);

    if (vui_poc_proportional_to_timing_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "vui_num_ticks_poc_diff_one_minus1: %i",
              vui_num_ticks_poc_diff_one_minus1);
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "vui_hrd_parameters_present_flag: %i",
            vui_hrd_parameters_present_flag);

    if (vui_hrd_parameters_present_flag) {
      // hrd_parameters(1, sps_max_sub_layers_minus1)
      fdump_indent_level(outfp, indent_level);
      hrd_parameters->fdump(outfp, indent_level);
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bitstream_restriction_flag: %i", bitstream_restriction_flag);

  if (bitstream_restriction_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "tiles_fixed_structure_flag: %i",
            tiles_fixed_structure_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "motion_vectors_over_pic_boundaries_flag: %i",
            motion_vectors_over_pic_boundaries_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "restricted_ref_pic_lists_flag: %i",
            restricted_ref_pic_lists_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "min_spatial_segmentation_idc: %i",
            min_spatial_segmentation_idc);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "max_bytes_per_pic_denom: %i", max_bytes_per_pic_denom);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "max_bits_per_min_cu_denom: %i", max_bits_per_min_cu_denom);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "log2_max_mv_length_horizontal: %i",
            log2_max_mv_length_horizontal);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "log2_max_mv_length_vertical: %i",
            log2_max_mv_length_vertical);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
