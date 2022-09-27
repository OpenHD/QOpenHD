/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"
#include "h265_profile_tier_level_parser.h"
#include "h265_scaling_list_data_parser.h"
#include "h265_vui_parameters_parser.h"

namespace {
typedef std::shared_ptr<h265nal::H265SpsParser::SpsState> SharedPtrSps;
}  // namespace

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse SPS state from the supplied buffer.
std::shared_ptr<H265SpsParser::SpsState> H265SpsParser::ParseSps(
    const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSps(&bit_buffer);
}

std::shared_ptr<H265SpsParser::SpsState> H265SpsParser::ParseSps(
    rtc::BitBuffer* bit_buffer) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H265 SPS Nal Unit (seq_parameter_set_rbsp()) parser.
  // Section 7.3.2.2 ("Sequence parameter set data syntax") of the H.265
  // standard for a complete description.
  auto sps = std::make_shared<SpsState>();

  // sps_video_parameter_set_id  u(4)
  if (!bit_buffer->ReadBits(&(sps->sps_video_parameter_set_id), 4)) {
    return nullptr;
  }

  // sps_max_sub_layers_minus1  u(3)
  if (!bit_buffer->ReadBits(&(sps->sps_max_sub_layers_minus1), 3)) {
    return nullptr;
  }

  // sps_temporal_id_nesting_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->sps_temporal_id_nesting_flag), 1)) {
    return nullptr;
  }

  // profile_tier_level(1, sps_max_sub_layers_minus1)
  sps->profile_tier_level = H265ProfileTierLevelParser::ParseProfileTierLevel(
      bit_buffer, true, sps->sps_max_sub_layers_minus1);
  if (sps->profile_tier_level == nullptr) {
    return nullptr;
  }

  // sps_seq_parameter_set_id  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->sps_seq_parameter_set_id))) {
    return nullptr;
  }

  // chroma_format_idc  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->chroma_format_idc))) {
    return nullptr;
  }
  if (sps->chroma_format_idc == 3) {
    // separate_colour_plane_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->separate_colour_plane_flag), 1)) {
      return nullptr;
    }
  }

  // pic_width_in_luma_samples  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->pic_width_in_luma_samples))) {
    return nullptr;
  }
  // Rec. ITU-T H.265 v5 (02/2018) Page 78
  // "pic_width_in_luma_samples shall not be equal to 0 and shall be an
  // integer multiple of MinCbSizeY."
  uint32_t MinCbSizeY = sps->getMinCbSizeY();
  if ((sps->pic_width_in_luma_samples == 0) ||
      ((MinCbSizeY * (sps->pic_width_in_luma_samples / MinCbSizeY)) !=
       sps->pic_width_in_luma_samples)) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: invalid sps->pic_width_in_luma_samples: %i\n",
            sps->pic_width_in_luma_samples);
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  // pic_height_in_luma_samples  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->pic_height_in_luma_samples))) {
    return nullptr;
  }
  // Rec. ITU-T H.265 v5 (02/2018) Page 78
  // "pic_height_in_luma_samples shall not be equal to 0 and shall be an
  // integer multiple of MinCbSizeY."
  if ((sps->pic_height_in_luma_samples == 0) ||
      ((MinCbSizeY * (sps->pic_height_in_luma_samples / MinCbSizeY)) !=
       sps->pic_height_in_luma_samples)) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: invalid sps->pic_height_in_luma_samples: %i\n",
            sps->pic_height_in_luma_samples);
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  // conformance_window_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->conformance_window_flag), 1)) {
    return nullptr;
  }

  if (sps->conformance_window_flag) {
    // conf_win_left_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(sps->conf_win_left_offset))) {
      return nullptr;
    }
    // conf_win_right_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(sps->conf_win_right_offset))) {
      return nullptr;
    }
    // conf_win_top_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(sps->conf_win_top_offset))) {
      return nullptr;
    }
    // conf_win_bottom_offset  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&(sps->conf_win_bottom_offset))) {
      return nullptr;
    }
  }

  // bit_depth_luma_minus8  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->bit_depth_luma_minus8))) {
    return nullptr;
  }
  // bit_depth_chroma_minus8  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(sps->bit_depth_chroma_minus8))) {
    return nullptr;
  }
  // log2_max_pic_order_cnt_lsb_minus4  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->log2_max_pic_order_cnt_lsb_minus4))) {
    return nullptr;
  }
  // sps_sub_layer_ordering_info_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->sps_sub_layer_ordering_info_present_flag),
                            1)) {
    return nullptr;
  }

  for (uint32_t i = (sps->sps_sub_layer_ordering_info_present_flag
                         ? 0
                         : sps->sps_max_sub_layers_minus1);
       i <= sps->sps_max_sub_layers_minus1; i++) {
    // sps_max_dec_pic_buffering_minus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    // Section 7.4.3.2.1
    // "The value of sps_max_dec_pic_buffering_minus1[i] shall be in the
    // range of 0 to MaxDpbSize - 1, inclusive"
    if (golomb_tmp >= h265limits::HEVC_MAX_DPB_SIZE) {
      return nullptr;
    }
    sps->sps_max_dec_pic_buffering_minus1.push_back(golomb_tmp);
    // sps_max_num_reorder_pics[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    sps->sps_max_num_reorder_pics.push_back(golomb_tmp);
    // sps_max_latency_increase_plus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    sps->sps_max_latency_increase_plus1.push_back(golomb_tmp);
  }

  // log2_min_luma_coding_block_size_minus3  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->log2_min_luma_coding_block_size_minus3))) {
    return nullptr;
  }
  if (sps->log2_min_luma_coding_block_size_minus3 > 3) {
    return nullptr;
  }

  // log2_diff_max_min_luma_coding_block_size  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->log2_diff_max_min_luma_coding_block_size))) {
    return nullptr;
  }
  if (sps->log2_diff_max_min_luma_coding_block_size > 3) {
    return nullptr;
  }

  // log2_min_luma_transform_block_size_minus2  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->log2_min_luma_transform_block_size_minus2))) {
    return nullptr;
  }

  // log2_diff_max_min_luma_transform_block_size  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->log2_diff_max_min_luma_transform_block_size))) {
    return nullptr;
  }

  // max_transform_hierarchy_depth_inter  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->max_transform_hierarchy_depth_inter))) {
    return nullptr;
  }

  // max_transform_hierarchy_depth_intra  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(sps->max_transform_hierarchy_depth_intra))) {
    return nullptr;
  }

  // scaling_list_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->scaling_list_enabled_flag), 1)) {
    return nullptr;
  }

  if (sps->scaling_list_enabled_flag) {
    // sps_scaling_list_data_present_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->sps_scaling_list_data_present_flag), 1)) {
      return nullptr;
    }
    if (sps->sps_scaling_list_data_present_flag) {
      // scaling_list_data()
      sps->scaling_list_data =
          H265ScalingListDataParser::ParseScalingListData(bit_buffer);
      if (sps->scaling_list_data == nullptr) {
        return nullptr;
      }
    }
  }

  // amp_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->amp_enabled_flag), 1)) {
    return nullptr;
  }

  // sample_adaptive_offset_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->sample_adaptive_offset_enabled_flag), 1)) {
    return nullptr;
  }

  // pcm_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->pcm_enabled_flag), 1)) {
    return nullptr;
  }

  if (sps->pcm_enabled_flag) {
    // pcm_sample_bit_depth_luma_minus1  u(4)
    if (!bit_buffer->ReadBits(&(sps->pcm_sample_bit_depth_luma_minus1), 4)) {
      return nullptr;
    }

    // pcm_sample_bit_depth_chroma_minus1  u(4)
    if (!bit_buffer->ReadBits(&(sps->pcm_sample_bit_depth_chroma_minus1), 4)) {
      return nullptr;
    }

    // log2_min_pcm_luma_coding_block_size_minus3  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps->log2_min_pcm_luma_coding_block_size_minus3))) {
      return nullptr;
    }

    // log2_diff_max_min_pcm_luma_coding_block_size  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps->log2_diff_max_min_pcm_luma_coding_block_size))) {
      return nullptr;
    }

    // pcm_loop_filter_disabled_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->pcm_loop_filter_disabled_flag), 1)) {
      return nullptr;
    }
  }

  // num_short_term_ref_pic_sets
  if (!bit_buffer->ReadExponentialGolomb(&(sps->num_short_term_ref_pic_sets))) {
    return nullptr;
  }
  if (sps->num_short_term_ref_pic_sets >
      h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX) {
#ifdef FPRINT_ERRORS
    fprintf(stderr,
            "error: sps->num_short_term_ref_pic_sets == %" PRIu32
            " > h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX\n",
            sps->num_short_term_ref_pic_sets);
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  for (uint32_t i = 0; i < sps->num_short_term_ref_pic_sets; i++) {
    uint32_t max_num_pics = 0;
    if (!sps->getMaxNumPics(&max_num_pics)) {
      return nullptr;
    }
    // st_ref_pic_set(i)
    auto st_ref_pic_set_item = H265StRefPicSetParser::ParseStRefPicSet(
        bit_buffer, i, sps->num_short_term_ref_pic_sets, &(sps->st_ref_pic_set),
        max_num_pics);
    if (st_ref_pic_set_item == nullptr) {
      // not enough bits for the st_ref_pic_set
      return nullptr;
    }
    sps->st_ref_pic_set.push_back(std::move(st_ref_pic_set_item));
  }

  // long_term_ref_pics_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->long_term_ref_pics_present_flag), 1)) {
    return nullptr;
  }

  if (sps->long_term_ref_pics_present_flag) {
    // num_long_term_ref_pics_sps  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps->num_long_term_ref_pics_sps))) {
      return nullptr;
    }

    for (uint32_t i = 0; i < sps->num_long_term_ref_pics_sps; i++) {
      // lt_ref_pic_poc_lsb_sps[i] u(v)  log2_max_pic_order_cnt_lsb_minus4 + 4
      if (!bit_buffer->ReadBits(&bits_tmp,
                                sps->log2_max_pic_order_cnt_lsb_minus4 + 4)) {
        return nullptr;
      }
      sps->lt_ref_pic_poc_lsb_sps.push_back(bits_tmp);

      // used_by_curr_pic_lt_sps_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      sps->used_by_curr_pic_lt_sps_flag.push_back(bits_tmp);
    }
  }

  // sps_temporal_mvp_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->sps_temporal_mvp_enabled_flag), 1)) {
    return nullptr;
  }

  // strong_intra_smoothing_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->strong_intra_smoothing_enabled_flag), 1)) {
    return nullptr;
  }

  // vui_parameters_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->vui_parameters_present_flag), 1)) {
    return nullptr;
  }

  if (sps->vui_parameters_present_flag) {
    // vui_parameters()
    sps->vui_parameters = H265VuiParametersParser::ParseVuiParameters(
        bit_buffer, sps->sps_max_sub_layers_minus1);
    if (sps->vui_parameters == nullptr) {
      return nullptr;
    }
  }

  // sps_extension_present_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps->sps_extension_present_flag), 1)) {
    return nullptr;
  }

  if (sps->sps_extension_present_flag) {
    // sps_range_extension_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->sps_range_extension_flag), 1)) {
      return nullptr;
    }

    // sps_multilayer_extension_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->sps_multilayer_extension_flag), 1)) {
      return nullptr;
    }

    // sps_3d_extension_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->sps_3d_extension_flag), 1)) {
      return nullptr;
    }

    // sps_scc_extension_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps->sps_scc_extension_flag), 1)) {
      return nullptr;
    }

    // sps_extension_4bits  u(4)
    if (!bit_buffer->ReadBits(&(sps->sps_extension_4bits), 4)) {
      return nullptr;
    }
  }

  if (sps->sps_range_extension_flag) {
    // sps_range_extension()
    sps->sps_range_extension =
        H265SpsRangeExtensionParser::ParseSpsRangeExtension(bit_buffer);
    if (sps->sps_range_extension == nullptr) {
      return nullptr;
    }
  }
  if (sps->sps_multilayer_extension_flag) {
    // sps_multilayer_extension() // specified in Annex F
    sps->sps_multilayer_extension =
        H265SpsMultilayerExtensionParser::ParseSpsMultilayerExtension(
            bit_buffer);
    if (sps->sps_multilayer_extension == nullptr) {
      return nullptr;
    }
  }

  if (sps->sps_3d_extension_flag) {
    // sps_3d_extension() // specified in Annex I
    sps->sps_3d_extension =
        H265Sps3dExtensionParser::ParseSps3dExtension(bit_buffer);
    if (sps->sps_3d_extension == nullptr) {
      return nullptr;
    }
  }

  if (sps->sps_scc_extension_flag) {
    // sps_scc_extension()
    sps->sps_scc_extension = H265SpsSccExtensionParser::ParseSpsSccExtension(
        bit_buffer, sps->chroma_format_idc, sps->bit_depth_luma_minus8,
        sps->bit_depth_chroma_minus8);
    if (sps->sps_scc_extension == nullptr) {
      return nullptr;
    }
  }

  if (sps->sps_extension_4bits) {
    while (more_rbsp_data(bit_buffer)) {
      // sps_extension_data_flag  u(1)
      if (!bit_buffer->ReadBits(&(sps->sps_extension_data_flag), 1)) {
        return nullptr;
      }
    }
  }

  rbsp_trailing_bits(bit_buffer);

  return sps;
}

#ifdef FDUMP_DEFINE
void H265SpsParser::SpsState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_video_parameter_set_id: %i", sps_video_parameter_set_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_max_sub_layers_minus1: %i", sps_max_sub_layers_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_temporal_id_nesting_flag: %i",
          sps_temporal_id_nesting_flag);

  fdump_indent_level(outfp, indent_level);
  profile_tier_level->fdump(outfp, indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_seq_parameter_set_id: %i", sps_seq_parameter_set_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "chroma_format_idc: %i", chroma_format_idc);

  if (chroma_format_idc == 3) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "separate_colour_plane_flag: %i",
            separate_colour_plane_flag);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_width_in_luma_samples: %i", pic_width_in_luma_samples);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_height_in_luma_samples: %i", pic_height_in_luma_samples);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "conformance_window_flag: %i", conformance_window_flag);

  if (conformance_window_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "conf_win_left_offset: %i", conf_win_left_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "conf_win_right_offset: %i", conf_win_right_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "conf_win_top_offset: %i", conf_win_top_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "conf_win_bottom_offset: %i", conf_win_bottom_offset);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bit_depth_luma_minus8: %i", bit_depth_luma_minus8);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bit_depth_chroma_minus8: %i", bit_depth_chroma_minus8);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_max_pic_order_cnt_lsb_minus4: %i",
          log2_max_pic_order_cnt_lsb_minus4);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_sub_layer_ordering_info_present_flag: %i",
          sps_sub_layer_ordering_info_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_max_dec_pic_buffering_minus1 {");
  for (const uint32_t& v : sps_max_dec_pic_buffering_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_max_num_reorder_pics {");
  for (const uint32_t& v : sps_max_num_reorder_pics) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_max_latency_increase_plus1 {");
  for (const uint32_t& v : sps_max_latency_increase_plus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_min_luma_coding_block_size_minus3: %i",
          log2_min_luma_coding_block_size_minus3);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_diff_max_min_luma_coding_block_size: %i",
          log2_diff_max_min_luma_coding_block_size);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_min_luma_transform_block_size_minus2: %i",
          log2_min_luma_transform_block_size_minus2);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_diff_max_min_luma_transform_block_size: %i",
          log2_diff_max_min_luma_transform_block_size);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_transform_hierarchy_depth_inter: %i",
          max_transform_hierarchy_depth_inter);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_transform_hierarchy_depth_intra: %i",
          max_transform_hierarchy_depth_intra);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "scaling_list_enabled_flag: %i", scaling_list_enabled_flag);

  if (scaling_list_enabled_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_scaling_list_data_present_flag: %i",
            sps_scaling_list_data_present_flag);

    if (sps_scaling_list_data_present_flag) {
      fdump_indent_level(outfp, indent_level);
      scaling_list_data->fdump(outfp, indent_level);
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "amp_enabled_flag: %i", amp_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sample_adaptive_offset_enabled_flag: %i",
          sample_adaptive_offset_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pcm_enabled_flag: %i", pcm_enabled_flag);

  if (pcm_enabled_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pcm_sample_bit_depth_luma_minus1: %i",
            pcm_sample_bit_depth_luma_minus1);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pcm_sample_bit_depth_chroma_minus1: %i",
            pcm_sample_bit_depth_chroma_minus1);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "log2_min_pcm_luma_coding_block_size_minus3: %i",
            log2_min_pcm_luma_coding_block_size_minus3);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "log2_diff_max_min_pcm_luma_coding_block_size: %i",
            log2_diff_max_min_pcm_luma_coding_block_size);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pcm_loop_filter_disabled_flag: %i",
            pcm_loop_filter_disabled_flag);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "num_short_term_ref_pic_sets: %i",
          num_short_term_ref_pic_sets);

  for (uint32_t i = 0; i < num_short_term_ref_pic_sets; i++) {
    fdump_indent_level(outfp, indent_level);
    st_ref_pic_set[i]->fdump(outfp, indent_level);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "long_term_ref_pics_present_flag: %i",
          long_term_ref_pics_present_flag);

  if (long_term_ref_pics_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_long_term_ref_pics_sps: %i",
            num_long_term_ref_pics_sps);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "lt_ref_pic_poc_lsb_sps {");
    for (const uint32_t& v : lt_ref_pic_poc_lsb_sps) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "used_by_curr_pic_lt_sps_flag {");
    for (const uint32_t& v : used_by_curr_pic_lt_sps_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_temporal_mvp_enabled_flag: %i",
          sps_temporal_mvp_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "strong_intra_smoothing_enabled_flag: %i",
          strong_intra_smoothing_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "vui_parameters_present_flag: %i",
          vui_parameters_present_flag);

  if (vui_parameters_present_flag) {
    fdump_indent_level(outfp, indent_level);
    vui_parameters->fdump(outfp, indent_level);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_extension_present_flag: %i", sps_extension_present_flag);

  if (sps_extension_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_range_extension_flag: %i", sps_range_extension_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_multilayer_extension_flag: %i",
            sps_multilayer_extension_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_3d_extension_flag: %i", sps_3d_extension_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_scc_extension_flag: %i", sps_scc_extension_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_extension_4bits: %i", sps_extension_4bits);
  }

  if (sps_range_extension_flag) {
    // sps_range_extension()
    fdump_indent_level(outfp, indent_level);
    sps_range_extension->fdump(outfp, indent_level);
  }

  if (sps_multilayer_extension_flag) {
    // sps_multilayer_extension() // specified in Annex F
    fdump_indent_level(outfp, indent_level);
    sps_multilayer_extension->fdump(outfp, indent_level);
  }

  if (sps_3d_extension_flag) {
    // sps_3d_extension() // specified in Annex I
    fdump_indent_level(outfp, indent_level);
    sps_3d_extension->fdump(outfp, indent_level);
  }

  if (sps_scc_extension_flag) {
    // sps_scc_extension()
    fdump_indent_level(outfp, indent_level);
    sps_scc_extension->fdump(outfp, indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

bool H265SpsParser::SpsState::getMaxNumPics(uint32_t* max_num_pics) noexcept {
  if (sps_max_sub_layers_minus1 >= sps_max_dec_pic_buffering_minus1.size()) {
    // Section 7.4.8: "num_negative_pics specifies the number of entries
    // in the stRpsIdx-th candidate short-term RPS that have picture order
    // count values less than the picture order count value of the current
    // picture. When nuh_layer_id of the current picture is equal to 0, the
    // value of num_negative_pics shall be in the range of 0 to
    // sps_max_dec_pic_buffering_minus1[sps_max_sub_layers_minus1],
    // inclusive."""
    return false;
  }
  *max_num_pics = sps_max_dec_pic_buffering_minus1[sps_max_sub_layers_minus1];
  return true;
}

uint32_t H265SpsParser::SpsState::getMinCbLog2SizeY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-10)
  return log2_min_luma_coding_block_size_minus3 + 3;
}

uint32_t H265SpsParser::SpsState::getCtbLog2SizeY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-11)
  return getMinCbLog2SizeY() + log2_diff_max_min_luma_coding_block_size;
}

uint32_t H265SpsParser::SpsState::getMinCbSizeY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-12)
  return 1 << getMinCbLog2SizeY();
}

uint32_t H265SpsParser::SpsState::getCtbSizeY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-13)
  return 1 << getCtbLog2SizeY();
}

uint32_t H265SpsParser::SpsState::getPicWidthInMinCbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-14)
  return pic_width_in_luma_samples / getMinCbSizeY();
}

uint32_t H265SpsParser::SpsState::getPicWidthInCtbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 79, Equation (7-15)
  return static_cast<uint32_t>(
      std::ceil(1.0 * pic_width_in_luma_samples / getCtbSizeY()));
}

uint32_t H265SpsParser::SpsState::getPicHeightInMinCbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-16)
  return pic_height_in_luma_samples / getMinCbSizeY();
}

uint32_t H265SpsParser::SpsState::getPicHeightInCtbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-17)
  return static_cast<uint32_t>(
      std::ceil(1.0 * pic_height_in_luma_samples / getCtbSizeY()));
}

uint32_t H265SpsParser::SpsState::getPicSizeInMinCbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-18)
  return getPicWidthInMinCbsY() * getPicHeightInMinCbsY();
}

uint32_t H265SpsParser::SpsState::getPicSizeInCtbsY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-19)
  return getPicWidthInCtbsY() * getPicHeightInCtbsY();
}

uint32_t H265SpsParser::SpsState::getPicSizeInSamplesY() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-20)
  return pic_width_in_luma_samples * pic_height_in_luma_samples;
}

#if 0
uint32_t H265SpsParser::SpsState::getPicWidthInSamplesC() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-21)
  return pic_width_in_luma_samples / getSubWidthC();
}

uint32_t H265SpsParser::SpsState::getPicHeightInSamplesC() noexcept {
  // Rec. ITU-T H.265 v5 (02/2018) Page 80, Equation (7-22)
  return pic_height_in_luma_samples / getSubHeightC();
}
#endif

}  // namespace h265nal
