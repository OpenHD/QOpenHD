/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sps_multilayer_extension_parser.h"

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

// Unpack RBSP and parse sps_multilayer_extension state from the supplied
// buffer.
std::unique_ptr<H265SpsMultilayerExtensionParser::SpsMultilayerExtensionState>
H265SpsMultilayerExtensionParser::ParseSpsMultilayerExtension(
    const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSpsMultilayerExtension(&bit_buffer);
}

std::unique_ptr<H265SpsMultilayerExtensionParser::SpsMultilayerExtensionState>
H265SpsMultilayerExtensionParser::ParseSpsMultilayerExtension(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H265 sps_multilayer_extension() NAL Unit.
  // Section F.7.3.2.2.4 ("Sequence parameter set multilayer extension syntax")
  // of the H.265 standard for a complete description.
  auto sps_multilayer_extension =
      std::make_unique<SpsMultilayerExtensionState>();

  // inter_view_mv_vert_constraint_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_multilayer_extension->inter_view_mv_vert_constraint_flag), 1)) {
    return nullptr;
  }

  return sps_multilayer_extension;
}

#ifdef FDUMP_DEFINE
void H265SpsMultilayerExtensionParser::SpsMultilayerExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "sps_multilayer_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "inter_view_mv_vert_constraint_flag: %i",
          inter_view_mv_vert_constraint_flag);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
