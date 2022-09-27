/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_range_extension_parser.h"

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

// Unpack RBSP and parse sps_range_extension state from the supplied buffer.
std::unique_ptr<H265SpsRangeExtensionParser::SpsRangeExtensionState>
H265SpsRangeExtensionParser::ParseSpsRangeExtension(const uint8_t* data,
                                                    size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSpsRangeExtension(&bit_buffer);
}

std::unique_ptr<H265SpsRangeExtensionParser::SpsRangeExtensionState>
H265SpsRangeExtensionParser::ParseSpsRangeExtension(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H265 sps_range_extension() NAL Unit.
  // Section 7.3.2.2.2 ("Sequence parameter set range extension syntax") of
  // the H.265 standard for a complete description.
  auto sps_range_extension = std::make_unique<SpsRangeExtensionState>();

  // transform_skip_rotation_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->transform_skip_rotation_enabled_flag), 1)) {
    return nullptr;
  }

  // transform_skip_context_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->transform_skip_context_enabled_flag), 1)) {
    return nullptr;
  }

  // implicit_rdpcm_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_range_extension->implicit_rdpcm_enabled_flag),
                            1)) {
    return nullptr;
  }

  // explicit_rdpcm_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_range_extension->explicit_rdpcm_enabled_flag),
                            1)) {
    return nullptr;
  }

  // extended_precision_processing_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->extended_precision_processing_flag), 1)) {
    return nullptr;
  }

  // intra_smoothing_disabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->intra_smoothing_disabled_flag), 1)) {
    return nullptr;
  }

  // high_precision_offsets_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->high_precision_offsets_enabled_flag), 1)) {
    return nullptr;
  }

  // persistent_rice_adaptation_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->persistent_rice_adaptation_enabled_flag), 1)) {
    return nullptr;
  }

  // cabac_bypass_alignment_enabled_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_range_extension->cabac_bypass_alignment_enabled_flag), 1)) {
    return nullptr;
  }

  return sps_range_extension;
}

#ifdef FDUMP_DEFINE
void H265SpsRangeExtensionParser::SpsRangeExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps_range_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "transform_skip_rotation_enabled_flag: %i",
          transform_skip_rotation_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "transform_skip_context_enabled_flag: %i",
          transform_skip_context_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "implicit_rdpcm_enabled_flag: %i",
          implicit_rdpcm_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "explicit_rdpcm_enabled_flag: %i",
          explicit_rdpcm_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "extended_precision_processing_flag: %i",
          extended_precision_processing_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "intra_smoothing_disabled_flag: %i",
          intra_smoothing_disabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "high_precision_offsets_enabled_flag: %i",
          high_precision_offsets_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "persistent_rice_adaptation_enabled_flag: %i",
          persistent_rice_adaptation_enabled_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cabac_bypass_alignment_enabled_flag: %i",
          cabac_bypass_alignment_enabled_flag);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
