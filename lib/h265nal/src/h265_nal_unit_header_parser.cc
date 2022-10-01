/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_nal_unit_header_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse NAL Unit header state from the supplied buffer.
std::unique_ptr<H265NalUnitHeaderParser::NalUnitHeaderState>
H265NalUnitHeaderParser::ParseNalUnitHeader(const uint8_t* data,
                                            size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseNalUnitHeader(&bit_buffer);
}

bool H265NalUnitHeaderParser::GetNalUnitType(const uint8_t* data,
                                             const size_t length,
                                             NalUnitType& naluType) noexcept {
  rtc::BitBuffer bitBuffer(data, length);
  auto naluHeader = ParseNalUnitHeader(&bitBuffer);
  if (!naluHeader) {
    return false;
  }
  naluType = static_cast<NalUnitType>(naluHeader->nal_unit_type);
  return true;
}

std::unique_ptr<H265NalUnitHeaderParser::NalUnitHeaderState>
H265NalUnitHeaderParser::ParseNalUnitHeader(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H265 NAL Unit Header (nal_unit_header()) parser.
  // Section 7.3.1.2 ("NAL unit header syntax") of the H.265
  // standard for a complete description.
  auto nal_unit_header = std::make_unique<NalUnitHeaderState>();

  // forbidden_zero_bit  f(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->forbidden_zero_bit, 1)) {
    return nullptr;
  }

  // nal_unit_type  u(6)
  if (!bit_buffer->ReadBits(&nal_unit_header->nal_unit_type, 6)) {
    return nullptr;
  }

  // nuh_layer_id  u(6)
  if (!bit_buffer->ReadBits(&nal_unit_header->nuh_layer_id, 6)) {
    return nullptr;
  }

  // nuh_temporal_id_plus1  u(3)
  if (!bit_buffer->ReadBits(&nal_unit_header->nuh_temporal_id_plus1, 3)) {
    return nullptr;
  }

  return nal_unit_header;
}

#ifdef FDUMP_DEFINE
void H265NalUnitHeaderParser::NalUnitHeaderState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "nal_unit_header {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "forbidden_zero_bit: %i", forbidden_zero_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "nal_unit_type: %i", nal_unit_type);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "nuh_layer_id: %i", nuh_layer_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "nuh_temporal_id_plus1: %i", nuh_temporal_id_plus1);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
