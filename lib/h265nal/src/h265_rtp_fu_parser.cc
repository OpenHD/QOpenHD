/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_fu_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_bitstream_parser_state.h"
#include "h265_common.h"
#include "h265_nal_unit_parser.h"

namespace h265nal {

// General note: this is based off rfc7798/
// You can find it on this page:
// https://tools.ietf.org/html/rfc7798#section-4.4.2

// Unpack RBSP and parse RTP FU state from the supplied buffer.
std::unique_ptr<H265RtpFuParser::RtpFuState> H265RtpFuParser::ParseRtpFu(
    const uint8_t* data, size_t length,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtpFu(&bit_buffer, bitstream_parser_state);
}

std::unique_ptr<H265RtpFuParser::RtpFuState> H265RtpFuParser::ParseRtpFu(
    rtc::BitBuffer* bit_buffer,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  // H265 RTP FU pseudo-NAL Unit.
  auto rtp_fu = std::make_unique<RtpFuState>();

  // first read the common header
  rtp_fu->header = H265NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp_fu->header == nullptr) {
    return nullptr;
  }

  // read the fu header
  if (!bit_buffer->ReadBits(&(rtp_fu->s_bit), 1)) {
    return nullptr;
  }
  if (!bit_buffer->ReadBits(&(rtp_fu->e_bit), 1)) {
    return nullptr;
  }
  if (!bit_buffer->ReadBits(&(rtp_fu->fu_type), 6)) {
    return nullptr;
  }

  if (rtp_fu->s_bit == 0) {
    // not the start of a fragmented NAL: stop here
    return rtp_fu;
  }

  // start of a fragmented NAL: keep reading
  rtp_fu->nal_unit_payload = H265NalUnitPayloadParser::ParseNalUnitPayload(
      bit_buffer, rtp_fu->fu_type, bitstream_parser_state);
  if (rtp_fu->nal_unit_payload == nullptr) {
    return nullptr;
  }

  return rtp_fu;
}

#ifdef FDUMP_DEFINE
void H265RtpFuParser::RtpFuState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "rtp_fu {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  header->fdump(outfp, indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "s_bit: %i", s_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "e_bit: %i", e_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "fu_type: %i", fu_type);

  if (s_bit == 1) {
    // start of a fragmented NAL: dump payload
    fdump_indent_level(outfp, indent_level);
    nal_unit_payload->fdump(outfp, fu_type, indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
