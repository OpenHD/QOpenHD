/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_sps_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"
#include "h264_vui_parameters_parser.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse SPS data state from the supplied buffer.
std::unique_ptr<H264SpsDataParser::SpsDataState>
H264SpsDataParser::ParseSpsData(const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSpsData(&bit_buffer);
}

std::unique_ptr<H264SpsDataParser::SpsDataState>
H264SpsDataParser::ParseSpsData(rtc::BitBuffer* bit_buffer) noexcept {
  uint32_t bits_tmp;
  int32_t golomb_tmp;

  // H264 SPS Nal Unit (seq_parameter_set_data(()) parser.
  // Section 7.3.2.1.1 ("Sequence parameter set data syntax") of the H.264
  // standard for a complete description.
  auto sps_data = std::make_unique<SpsDataState>();

  // profile_idc  u(8)
  if (!bit_buffer->ReadBits(&sps_data->profile_idc, 8)) {
    return nullptr;
  }

  // constraint_set0_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set0_flag, 1)) {
    return nullptr;
  }

  // constraint_set1_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set1_flag, 1)) {
    return nullptr;
  }

  // constraint_set2_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set2_flag, 1)) {
    return nullptr;
  }

  // constraint_set3_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set3_flag, 1)) {
    return nullptr;
  }

  // constraint_set4_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set4_flag, 1)) {
    return nullptr;
  }

  // constraint_set5_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->constraint_set5_flag, 1)) {
    return nullptr;
  }

  // reserved_zero_2bits  u(2)
  if (!bit_buffer->ReadBits(&sps_data->reserved_zero_2bits, 2)) {
    return nullptr;
  }

  // level_idc  u(8)
  if (!bit_buffer->ReadBits(&sps_data->level_idc, 8)) {
    return nullptr;
  }

  // seq_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps_data->seq_parameter_set_id))) {
    return nullptr;
  }

  if (sps_data->profile_idc == 100 || sps_data->profile_idc == 110 ||
      sps_data->profile_idc == 122 || sps_data->profile_idc == 244 ||
      sps_data->profile_idc == 44 || sps_data->profile_idc == 83 ||
      sps_data->profile_idc == 86 || sps_data->profile_idc == 118 ||
      sps_data->profile_idc == 128 || sps_data->profile_idc == 138 ||
      sps_data->profile_idc == 139 || sps_data->profile_idc == 134 ||
      sps_data->profile_idc == 135) {
    // chroma_format_idc  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(sps_data->chroma_format_idc))) {
      return nullptr;
    }

    if (sps_data->chroma_format_idc == 3) {
      // separate_colour_plane_flag  u(1)
      if (!bit_buffer->ReadBits(&sps_data->separate_colour_plane_flag, 1)) {
        return nullptr;
      }
    }

    // bit_depth_luma_minus8  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->bit_depth_luma_minus8))) {
      return nullptr;
    }

    // bit_depth_chroma_minus8  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->bit_depth_chroma_minus8))) {
      return nullptr;
    }

    // qpprime_y_zero_transform_bypass_flag  u(1)
    if (!bit_buffer->ReadBits(&sps_data->qpprime_y_zero_transform_bypass_flag,
                              1)) {
      return nullptr;
    }

    // seq_scaling_matrix_present_flag  u(1)
    if (!bit_buffer->ReadBits(&sps_data->seq_scaling_matrix_present_flag, 1)) {
      return nullptr;
    }

    if (sps_data->seq_scaling_matrix_present_flag) {
      for (uint32_t i = 0; i < ((sps_data->chroma_format_idc != 3) ? 8 : 12);
           i++) {
        // seq_scaling_list_present_flag[i]  u(1)
        if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
          return nullptr;
        }
        sps_data->seq_scaling_list_present_flag.push_back(bits_tmp);

        if (sps_data->seq_scaling_list_present_flag[i]) {
          // scaling_list()
          if (i < 6) {
            (void)sps_data->scaling_list(
                bit_buffer, i, sps_data->ScalingList4x4, 16,
                sps_data->UseDefaultScalingMatrix4x4Flag);
          } else {
            (void)sps_data->scaling_list(
                bit_buffer, i - 6, sps_data->ScalingList8x8, 64,
                sps_data->UseDefaultScalingMatrix4x4Flag);
          }
        }
      }
    }
  }

  // log2_max_frame_num_minus4  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps_data->log2_max_frame_num_minus4))) {
    return nullptr;
  }

  // pic_order_cnt_type  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps_data->pic_order_cnt_type))) {
    return nullptr;
  }

  if (sps_data->pic_order_cnt_type == 0) {
    // log2_max_pic_order_cnt_lsb_minus4  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->log2_max_pic_order_cnt_lsb_minus4))) {
      return nullptr;
    }

  } else if (sps_data->pic_order_cnt_type == 1) {
    // delta_pic_order_always_zero_flag  u(1)
    if (!bit_buffer->ReadBits(&sps_data->delta_pic_order_always_zero_flag, 1)) {
      return nullptr;
    }

    // offset_for_non_ref_pic  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_data->offset_for_non_ref_pic))) {
      return nullptr;
    }

    // offset_for_top_to_bottom_field  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_data->offset_for_top_to_bottom_field))) {
      return nullptr;
    }

    // num_ref_frames_in_pic_order_cnt_cycle  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->num_ref_frames_in_pic_order_cnt_cycle))) {
      return nullptr;
    }

    for (uint32_t i = 0; i < sps_data->num_ref_frames_in_pic_order_cnt_cycle;
         i++) {
      // offset_for_ref_frame[i]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      sps_data->offset_for_ref_frame.push_back(golomb_tmp);
    }
  }

  // max_num_ref_frames  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps_data->max_num_ref_frames))) {
    return nullptr;
  }

  // gaps_in_frame_num_value_allowed_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->gaps_in_frame_num_value_allowed_flag,
                            1)) {
    return nullptr;
  }

  // pic_width_in_mbs_minus1  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps_data->pic_width_in_mbs_minus1))) {
    return nullptr;
  }

  // pic_height_in_map_units_minus1  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps_data->pic_height_in_map_units_minus1))) {
    return nullptr;
  }

  // frame_mbs_only_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->frame_mbs_only_flag, 1)) {
    return nullptr;
  }

  if (!sps_data->frame_mbs_only_flag) {
    // mb_adaptive_frame_field_flag  u(1)
    if (!bit_buffer->ReadBits(&sps_data->mb_adaptive_frame_field_flag, 1)) {
      return nullptr;
    }
  }

  // direct_8x8_inference_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->direct_8x8_inference_flag, 1)) {
    return nullptr;
  }

  // frame_cropping_flag  u(1)
  if (!bit_buffer->ReadBits(&sps_data->frame_cropping_flag, 1)) {
    return nullptr;
  }

  if (sps_data->frame_cropping_flag) {
    // frame_crop_left_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->frame_crop_left_offset))) {
      return nullptr;
    }

    // frame_crop_right_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->frame_crop_right_offset))) {
      return nullptr;
    }

    // frame_crop_top_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->frame_crop_top_offset))) {
      return nullptr;
    }

    // frame_crop_bottom_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_data->frame_crop_bottom_offset))) {
      return nullptr;
    }
  }

  // vui_parameters_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_data->vui_parameters_present_flag), 1)) {
    return nullptr;
  }

  if (sps_data->vui_parameters_present_flag) {
    // vui_parameters()
    sps_data->vui_parameters =
        H264VuiParametersParser::ParseVuiParameters(bit_buffer);
    if (sps_data->vui_parameters == nullptr) {
      return nullptr;
    }
  }

  return sps_data;
}

uint32_t H264SpsDataParser::SpsDataState::getChromaArrayType() noexcept {
  // Rec. ITU-T H.264 (2012) Page 74, Section 7.4.2.1.1
  // the value of the variable ChromaArrayType is assigned as follows:
  // - If separate_colour_plane_flag is equal to 0, ChromaArrayType is set
  //   equal to chroma_format_idc.
  // - Otherwise (separate_colour_plane_flag is equal to 1), ChromaArrayType
  // is set equal to 0.
  uint32_t ChromaArrayType = 0;
  if (separate_colour_plane_flag == 0) {
    ChromaArrayType = chroma_format_idc;
  } else {
    ChromaArrayType = 0;
  }
  return ChromaArrayType;
}

// Section 7.3.2.1.1.1
bool H264SpsDataParser::SpsDataState::scaling_list(
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

// Unpack RBSP and parse SPS state from the supplied buffer.
std::shared_ptr<H264SpsParser::SpsState> H264SpsParser::ParseSps(
    const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSps(&bit_buffer);
}

std::shared_ptr<H264SpsParser::SpsState> H264SpsParser::ParseSps(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H264 SPS Nal Unit (seq_parameter_set_rbsp(()) parser.
  // Section 7.3.2.1 ("Sequence parameter set RBSP syntax") of the H.264
  // standard for a complete description.
  auto sps = std::make_shared<SpsState>();

  // seq_parameter_set_data()
  sps->sps_data = H264SpsDataParser::ParseSpsData(bit_buffer);
  if (sps->sps_data == nullptr) {
    return nullptr;
  }

  rbsp_trailing_bits(bit_buffer);

  return sps;
}

uint32_t H264SpsParser::SpsState::getChromaArrayType() noexcept {
  return sps_data->getChromaArrayType();
}

#ifdef FDUMP_DEFINE
void H264SpsDataParser::SpsDataState::fdump(FILE* outfp,
                                            int indent_level) const {
  fprintf(outfp, "sps_data {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "profile_idc: %i", profile_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set0_flag: %i", constraint_set0_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set1_flag: %i", constraint_set1_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set2_flag: %i", constraint_set2_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set3_flag: %i", constraint_set3_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set4_flag: %i", constraint_set4_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "constraint_set5_flag: %i", constraint_set5_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_2bits: %i", reserved_zero_2bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "level_idc: %i", level_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "seq_parameter_set_id: %i", seq_parameter_set_id);

  if (profile_idc == 100 || profile_idc == 110 || profile_idc == 122 ||
      profile_idc == 244 || profile_idc == 44 || profile_idc == 83 ||
      profile_idc == 86 || profile_idc == 118 || profile_idc == 128 ||
      profile_idc == 138 || profile_idc == 139 || profile_idc == 134 ||
      profile_idc == 135) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_format_idc: %i", chroma_format_idc);

    if (chroma_format_idc == 3) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "separate_colour_plane_flag: %i",
              separate_colour_plane_flag);
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "bit_depth_luma_minus8: %i", bit_depth_luma_minus8);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "bit_depth_chroma_minus8: %i", bit_depth_chroma_minus8);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "qpprime_y_zero_transform_bypass_flag: %i",
            qpprime_y_zero_transform_bypass_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaling_matrix_present_flag: %i",
            seq_scaling_matrix_present_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaling_list_present_flag {");
    for (const uint32_t& v : seq_scaling_list_present_flag) {
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
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_max_frame_num_minus4: %i", log2_max_frame_num_minus4);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_order_cnt_type: %i", pic_order_cnt_type);

  if (pic_order_cnt_type == 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "log2_max_pic_order_cnt_lsb_minus4: %i",
            log2_max_pic_order_cnt_lsb_minus4);

  } else if (pic_order_cnt_type == 1) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_pic_order_always_zero_flag: %i",
            delta_pic_order_always_zero_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "offset_for_non_ref_pic: %i", offset_for_non_ref_pic);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "offset_for_top_to_bottom_field: %i",
            offset_for_top_to_bottom_field);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_ref_frames_in_pic_order_cnt_cycle: %i",
            num_ref_frames_in_pic_order_cnt_cycle);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "offset_for_ref_frame {");
    for (const int32_t& v : offset_for_ref_frame) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_num_ref_frames: %i", max_num_ref_frames);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "gaps_in_frame_num_value_allowed_flag: %i",
          gaps_in_frame_num_value_allowed_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_width_in_mbs_minus1: %i", pic_width_in_mbs_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_height_in_map_units_minus1: %i",
          pic_height_in_map_units_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "frame_mbs_only_flag: %i", frame_mbs_only_flag);

  if (!frame_mbs_only_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "mb_adaptive_frame_field_flag: %i",
            mb_adaptive_frame_field_flag);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "direct_8x8_inference_flag: %i", direct_8x8_inference_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "frame_cropping_flag: %i", frame_cropping_flag);

  if (frame_cropping_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "frame_crop_left_offset: %i", frame_crop_left_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "frame_crop_right_offset: %i", frame_crop_right_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "frame_crop_top_offset: %i", frame_crop_top_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "frame_crop_bottom_offset: %i", frame_crop_bottom_offset);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "vui_parameters_present_flag: %i",
          vui_parameters_present_flag);

  if (vui_parameters_present_flag) {
    fdump_indent_level(outfp, indent_level);
    vui_parameters->fdump(outfp, indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}

void H264SpsParser::SpsState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  sps_data->fdump(outfp, indent_level);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}

#endif  // FDUMP_DEFINE

}  // namespace h264nal
