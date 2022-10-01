/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_scc_extension_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse sps_scc_extension state from the supplied buffer.
std::unique_ptr<H265SpsSccExtensionParser::SpsSccExtensionState>
H265SpsSccExtensionParser::ParseSpsSccExtension(
    const uint8_t* data, size_t length, uint32_t chroma_format_idc,
    uint32_t bit_depth_luma_minus8, uint32_t bit_depth_chroma_minus8) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSpsSccExtension(&bit_buffer, chroma_format_idc,
                              bit_depth_luma_minus8, bit_depth_chroma_minus8);
}

std::unique_ptr<H265SpsSccExtensionParser::SpsSccExtensionState>
H265SpsSccExtensionParser::ParseSpsSccExtension(
    rtc::BitBuffer* bit_buffer, uint32_t chroma_format_idc,
    uint32_t bit_depth_luma_minus8, uint32_t bit_depth_chroma_minus8) noexcept {
  uint32_t bits_tmp;

  // H265 sps_scc_extension() NAL Unit.
  // Section 7.3.2.2.3 ("Sequence parameter set screen content coding extension
  // syntax") of the H.265 standard for a complete description.
  auto sps_scc_extension = std::make_unique<SpsSccExtensionState>();

  // sps_curr_pic_ref_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_scc_extension->sps_curr_pic_ref_enabled_flag),
                            1)) {
    return nullptr;
  }

  // palette_mode_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_scc_extension->palette_mode_enabled_flag),
                            1)) {
    return nullptr;
  }

  if (sps_scc_extension->palette_mode_enabled_flag) {
    // palette_max_size  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_scc_extension->palette_max_size))) {
      return nullptr;
    }

    // delta_palette_max_predictor_size  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(sps_scc_extension->delta_palette_max_predictor_size))) {
      return nullptr;
    }

    // sps_palette_predictor_initializers_present_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(sps_scc_extension
                  ->sps_palette_predictor_initializers_present_flag),
            1)) {
      return nullptr;
    }

    if (sps_scc_extension->sps_palette_predictor_initializers_present_flag) {
      // sps_num_palette_predictor_initializers_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(sps_scc_extension
                    ->sps_num_palette_predictor_initializers_minus1))) {
        return nullptr;
      }

      uint32_t numComps = (chroma_format_idc == 0) ? 1 : 3;
      uint32_t BitDepth_Y = 8 + bit_depth_luma_minus8;    // Eq 7-4
      uint32_t BitDepth_C = 8 + bit_depth_chroma_minus8;  // Eq 7-6

      for (uint32_t comp = 0; comp < numComps; comp++) {
        sps_scc_extension->sps_palette_predictor_initializers.emplace_back();
        for (uint32_t i = 0;
             i <=
             sps_scc_extension->sps_num_palette_predictor_initializers_minus1;
             i++) {
          // sps_palette_predictor_initializers[i][j]  u(v)
          // sps_palette_predictor_initializers[0][*] -> BitDepth_Y
          // sps_palette_predictor_initializers[1,2][*] -> BitDepth_C
          uint32_t bit_depth = (comp == 0) ? BitDepth_Y : BitDepth_C;
          if (!bit_buffer->ReadBits(&bits_tmp, bit_depth)) {
            return nullptr;
          }
          sps_scc_extension->sps_palette_predictor_initializers[comp].push_back(
              bits_tmp);
        }
      }
    }
  }

  // motion_vector_resolution_control_idc  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_scc_extension->motion_vector_resolution_control_idc), 2)) {
    return nullptr;
  }

  // intra_boundary_filtering_disabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_scc_extension->intra_boundary_filtering_disabled_flag), 1)) {
    return nullptr;
  }

  return sps_scc_extension;
}

#ifdef FDUMP_DEFINE
void H265SpsSccExtensionParser::SpsSccExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps_scc_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sps_curr_pic_ref_enabled_flag: %i",
          sps_curr_pic_ref_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "palette_mode_enabled_flag: %i", palette_mode_enabled_flag);

  if (palette_mode_enabled_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "palette_max_size: %i", palette_max_size);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_palette_max_predictor_size: %i",
            delta_palette_max_predictor_size);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sps_palette_predictor_initializers_present_flag: %i",
            sps_palette_predictor_initializers_present_flag);

    if (sps_palette_predictor_initializers_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sps_num_palette_predictor_initializers_minus1: %i",
              sps_num_palette_predictor_initializers_minus1);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sps_palette_predictor_initializers {");
      for (const std::vector<uint32_t>& vv :
           sps_palette_predictor_initializers) {
        fprintf(outfp, " {");
        for (const uint32_t& v : vv) {
          fprintf(outfp, " %i", v);
        }
        fprintf(outfp, " }");
      }
      fprintf(outfp, " }");
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "motion_vector_resolution_control_idc: %i",
          motion_vector_resolution_control_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "intra_boundary_filtering_disabled_flag: %i",
          intra_boundary_filtering_disabled_flag);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
