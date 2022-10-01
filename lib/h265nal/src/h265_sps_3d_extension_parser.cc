/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_3d_extension_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2018/02 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse sps_3d_extension state from the supplied
// buffer.
std::unique_ptr<H265Sps3dExtensionParser::Sps3dExtensionState>
H265Sps3dExtensionParser::ParseSps3dExtension(const uint8_t* data,
                                              size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSps3dExtension(&bit_buffer);
}

std::unique_ptr<H265Sps3dExtensionParser::Sps3dExtensionState>
H265Sps3dExtensionParser::ParseSps3dExtension(
    rtc::BitBuffer* bit_buffer) noexcept {
  uint32_t bits_tmp;

  // H265 sps_3d_extension() NAL Unit.
  // Section I.7.3.2.2.5 ("Sequence parameter set 3d extension syntax")
  // of the H.265 standard for a complete description.
  auto sps_3d_extension = std::make_unique<Sps3dExtensionState>();

  for (uint32_t d = 0; d <= 1; d++) {
    // iv_di_mc_enabled_flag[d]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    sps_3d_extension->iv_di_mc_enabled_flag.push_back(bits_tmp);

    // iv_mv_scal_enabled_flag[d]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    sps_3d_extension->iv_mv_scal_enabled_flag.push_back(bits_tmp);

    if (d == 0) {
      // log2_ivmc_sub_pb_size_minus3[d]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(sps_3d_extension->log2_ivmc_sub_pb_size_minus3))) {
        return nullptr;
      }

      // iv_res_pred_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->iv_res_pred_enabled_flag),
                                1)) {
        return nullptr;
      }

      // depth_ref_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->depth_ref_enabled_flag),
                                1)) {
        return nullptr;
      }

      // vsp_mc_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->vsp_mc_enabled_flag), 1)) {
        return nullptr;
      }

      // dbbp_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->dbbp_enabled_flag), 1)) {
        return nullptr;
      }

    } else {
      // tex_mc_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->tex_mc_enabled_flag), 1)) {
        return nullptr;
      }

      // log2_texmc_sub_pb_size_minus3[d]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(sps_3d_extension->log2_texmc_sub_pb_size_minus3))) {
        return nullptr;
      }

      // intra_contour_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->intra_contour_enabled_flag),
                                1)) {
        return nullptr;
      }

      // intra_dc_only_wedge_enabled_flag[[d]  u(1)
      if (!bit_buffer->ReadBits(
              &(sps_3d_extension->intra_dc_only_wedge_enabled_flag), 1)) {
        return nullptr;
      }

      // cqt_cu_part_pred_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(
              &(sps_3d_extension->cqt_cu_part_pred_enabled_flag), 1)) {
        return nullptr;
      }

      // inter_dc_only_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->inter_dc_only_enabled_flag),
                                1)) {
        return nullptr;
      }

      // skip_intra_enabled_flag[d]  u(1)
      if (!bit_buffer->ReadBits(&(sps_3d_extension->skip_intra_enabled_flag),
                                1)) {
        return nullptr;
      }
    }
  }

  return sps_3d_extension;
}

#ifdef FDUMP_DEFINE
void H265Sps3dExtensionParser::Sps3dExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps_3d_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "iv_di_mc_enabled_flag {");
  for (const uint32_t& v : iv_di_mc_enabled_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "iv_mv_scal_enabled_flag {");
  for (const uint32_t& v : iv_mv_scal_enabled_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_ivmc_sub_pb_size_minus3: %i",
          log2_ivmc_sub_pb_size_minus3);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "iv_res_pred_enabled_flag: %i", iv_res_pred_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "depth_ref_enabled_flag: %i", depth_ref_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "vsp_mc_enabled_flag: %i", vsp_mc_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "dbbp_enabled_flag: %i", dbbp_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "tex_mc_enabled_flag: %i", tex_mc_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "log2_texmc_sub_pb_size_minus3: %i",
          log2_texmc_sub_pb_size_minus3);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "intra_contour_enabled_flag: %i", intra_contour_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "intra_dc_only_wedge_enabled_flag: %i",
          intra_dc_only_wedge_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cqt_cu_part_pred_enabled_flag: %i",
          cqt_cu_part_pred_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "inter_dc_only_enabled_flag: %i", inter_dc_only_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "skip_intra_enabled_flag: %i", skip_intra_enabled_flag);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
