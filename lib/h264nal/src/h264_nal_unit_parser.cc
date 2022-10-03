/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_nal_unit_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_nal_unit_header_parser.h"
#include "h264_nal_unit_payload_parser.h"
#include "h264_pps_parser.h"
#include "h264_prefix_nal_unit_parser.h"
#include "h264_slice_layer_without_partitioning_rbsp_parser.h"
#include "h264_sps_parser.h"
#include "h264_subset_sps_parser.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse NAL Unit state from the supplied buffer.
std::unique_ptr<H264NalUnitParser::NalUnitState>
H264NalUnitParser::ParseNalUnit(
    const uint8_t* data, size_t length,
    struct H264BitstreamParserState* bitstream_parser_state,
    bool add_checksum) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseNalUnit(&bit_buffer, bitstream_parser_state, add_checksum);
}

std::unique_ptr<H264NalUnitParser::NalUnitState>
H264NalUnitParser::ParseNalUnit(
    rtc::BitBuffer* bit_buffer,
    struct H264BitstreamParserState* bitstream_parser_state,
    bool add_checksum) noexcept {
  // H264 NAL Unit (nal_unit()) parser.
  // Section 7.3.1 ("NAL unit syntax") of the H.264
  // standard for a complete description.
  auto nal_unit = std::make_unique<NalUnitState>();

  // need to calculate the checksum before parsing the bit buffer
  if (add_checksum) {
    // set the checksum
    nal_unit->checksum = NaluChecksum::GetNaluChecksum(bit_buffer);
  }

  // nal_unit_header()
  nal_unit->nal_unit_header =
      H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (nal_unit->nal_unit_header == nullptr) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: cannot ParseNalUnitHeader in nal unit\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  // nal_unit_payload()
  nal_unit->nal_unit_payload = H264NalUnitPayloadParser::ParseNalUnitPayload(
      bit_buffer, *(nal_unit->nal_unit_header), bitstream_parser_state);
  if (nal_unit->nal_unit_payload == nullptr) {
    return nullptr;
  }

  // update the parsed length
  nal_unit->parsed_length = get_current_offset(bit_buffer);

  return nal_unit;
}

#ifdef FDUMP_DEFINE
void H264NalUnitParser::NalUnitState::fdump(FILE* outfp, int indent_level,
                                            bool add_offset, bool add_length,
                                            bool add_parsed_length,
                                            bool add_checksum) const {
  fprintf(outfp, "nal_unit {");
  indent_level = indent_level_incr(indent_level);

  // nal unit offset (starting at NAL unit header)
  if (add_offset) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "offset: 0x%08zx", offset);
  }

  // nal unit length (starting at NAL unit header)
  if (add_length) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "length: %zu", length);
  }

  // nal unit parsed length (starting at NAL unit header)
  if (add_parsed_length) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "parsed_length: 0x%08zx", parsed_length);
  }

  // nal unit checksum
  if (add_checksum) {
    fdump_indent_level(outfp, indent_level);
    char checksum_printable[64] = {};
    checksum->fdump(checksum_printable, 64);
    fprintf(outfp, "checksum: 0x%s", checksum_printable);
  }

  // header
  fdump_indent_level(outfp, indent_level);
  nal_unit_header->fdump(outfp, indent_level);

  // payload
  fdump_indent_level(outfp, indent_level);
  nal_unit_payload->fdump(outfp, indent_level, nal_unit_header->nal_unit_type);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
