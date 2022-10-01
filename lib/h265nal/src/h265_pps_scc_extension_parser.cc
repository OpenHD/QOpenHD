/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_pps_scc_extension_parser.h"

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

// Unpack RBSP and parse pps_scc_extension state from the supplied buffer.
std::unique_ptr<H265PpsSccExtensionParser::PpsSccExtensionState>
H265PpsSccExtensionParser::ParsePpsSccExtension(const uint8_t* data,
                                                size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePpsSccExtension(&bit_buffer);
}

std::unique_ptr<H265PpsSccExtensionParser::PpsSccExtensionState>
H265PpsSccExtensionParser::ParsePpsSccExtension(
    rtc::BitBuffer* bit_buffer) noexcept {
  uint32_t bits_tmp;

  // H265 pps_scc_extension() NAL Unit.
  // Section 7.3.2.3.2 ("Picture parameter set screen extension syntax") of
  // the H.265 standard for a complete description.
  auto pps_scc_extension = std::make_unique<PpsSccExtensionState>();

  // pps_curr_pic_ref_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(pps_scc_extension->pps_curr_pic_ref_enabled_flag),
                            1)) {
    return nullptr;
  }

  // residual_adaptive_colour_transform_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(pps_scc_extension->residual_adaptive_colour_transform_enabled_flag),
          1)) {
    return nullptr;
  }

  if (pps_scc_extension->residual_adaptive_colour_transform_enabled_flag) {
    // pps_slice_act_qp_offsets_present_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(pps_scc_extension->pps_slice_act_qp_offsets_present_flag), 1)) {
      return nullptr;
    }

    // pps_act_y_qp_offset_plus5  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(pps_scc_extension->pps_act_y_qp_offset_plus5))) {
      return nullptr;
    }

    // pps_act_cb_qp_offset_plus5  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(pps_scc_extension->pps_act_cb_qp_offset_plus5))) {
      return nullptr;
    }

    // pps_act_cr_qp_offset_plus3  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(pps_scc_extension->pps_act_cr_qp_offset_plus3))) {
      return nullptr;
    }
  }

  // pps_palette_predictor_initializer_present_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(pps_scc_extension->pps_palette_predictor_initializer_present_flag),
          1)) {
    return nullptr;
  }

  if (pps_scc_extension->pps_palette_predictor_initializer_present_flag) {
    // pps_num_palette_predictor_initializer  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(pps_scc_extension->pps_num_palette_predictor_initializer))) {
      return nullptr;
    }

    if (pps_scc_extension->pps_num_palette_predictor_initializer > 0) {
      // monochrome_palette_flag  u(1)
      if (!bit_buffer->ReadBits(&(pps_scc_extension->monochrome_palette_flag),
                                1)) {
        return nullptr;
      }

      // luma_bit_depth_entry_minus8  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(pps_scc_extension->luma_bit_depth_entry_minus8))) {
        return nullptr;
      }

      if (pps_scc_extension->monochrome_palette_flag) {
        // chroma_bit_depth_entry_minus8  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &(pps_scc_extension->chroma_bit_depth_entry_minus8))) {
          return nullptr;
        }
      }

      uint32_t numComps = pps_scc_extension->monochrome_palette_flag ? 1 : 3;
      for (uint32_t comp = 0; comp < numComps; comp++) {
        pps_scc_extension->pps_palette_predictor_initializers.emplace_back();

        for (uint32_t i = 0;
             i < pps_scc_extension->pps_num_palette_predictor_initializer;
             i++) {
          // pps_palette_predictor_initializers[comp][i]  u(v)
          // pps_palette_predictor_initializers[0][*] ->
          // luma_bit_depth_entry_minus8 + 8,
          // pps_palette_predictor_initializers[1,2][*] ->
          // chroma_bit_depth_entry_minus8 + 8

          uint32_t bit_depth =
              (comp == 0)
                  ? (pps_scc_extension->luma_bit_depth_entry_minus8 + 8)
                  : (pps_scc_extension->chroma_bit_depth_entry_minus8 + 8);
          if (!bit_buffer->ReadBits(&bits_tmp, bit_depth)) {
            return nullptr;
          }
          pps_scc_extension->pps_palette_predictor_initializers[comp].push_back(
              bits_tmp);
        }
      }
    }
  }

  return pps_scc_extension;
}

#ifdef FDUMP_DEFINE
void H265PpsSccExtensionParser::PpsSccExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "pps_scc_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pps_curr_pic_ref_enabled_flag: %i",
          pps_curr_pic_ref_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "residual_adaptive_colour_transform_enabled_flag: %i",
          residual_adaptive_colour_transform_enabled_flag);

  if (residual_adaptive_colour_transform_enabled_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pps_slice_act_qp_offsets_present_flag: %i",
            pps_slice_act_qp_offsets_present_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pps_act_y_qp_offset_plus5: %i", pps_act_y_qp_offset_plus5);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pps_act_cb_qp_offset_plus5: %i",
            pps_act_cb_qp_offset_plus5);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pps_act_cr_qp_offset_plus3: %i",
            pps_act_cr_qp_offset_plus3);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pps_palette_predictor_initializer_present_flag: %i",
          pps_palette_predictor_initializer_present_flag);

  if (pps_palette_predictor_initializer_present_flag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "pps_num_palette_predictor_initializer: %i",
            pps_num_palette_predictor_initializer);

    if (pps_num_palette_predictor_initializer > 0) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "monochrome_palette_flag: %i", monochrome_palette_flag);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "luma_bit_depth_entry_minus8: %i",
              luma_bit_depth_entry_minus8);

      if (!monochrome_palette_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "chroma_bit_depth_entry_minus8: %i",
                chroma_bit_depth_entry_minus8);
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "pps_palette_predictor_initializers {");
      for (const std::vector<uint32_t>& vv :
           pps_palette_predictor_initializers) {
        fprintf(outfp, " {");
        for (const uint32_t& v : vv) {
          fprintf(outfp, " %i", v);
        }
        fprintf(outfp, " }");
      }
      fprintf(outfp, " }");
    }
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
