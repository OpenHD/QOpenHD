/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_aud_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse AUD state from the supplied buffer.
std::unique_ptr<H265AudParser::AudState> H265AudParser::ParseAud(
    const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseAud(&bit_buffer);
}

std::unique_ptr<H265AudParser::AudState> H265AudParser::ParseAud(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H265 AUD NAL Unit (access_unit_delimiter_rbsp()) parser.
  // Section 7.3.2.5 ("Access unit delimiter RBSP syntax") of the H.265
  // standard for a complete description.
  auto aud = std::make_unique<AudState>();

  // pic_type  u(3)
  if (!bit_buffer->ReadBits(&(aud->pic_type), 3)) {
    return nullptr;
  }

  rbsp_trailing_bits(bit_buffer);

  return aud;
}

#ifdef FDUMP_DEFINE
void H265AudParser::AudState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "aud {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "pic_type: %i", pic_type);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
