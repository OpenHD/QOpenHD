/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_fua_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_nal_unit_parser.h"

namespace h264nal {

// General note: this is based off rfc6184/
// You can find it on this page:
// https://tools.ietf.org/html/rfc6184#section-5.6

// Unpack RBSP and parse RTP FU-A state from the supplied buffer.
std::unique_ptr<H264RtpFuAParser::RtpFuAState> H264RtpFuAParser::ParseRtpFuA(
    const uint8_t* data, size_t length, uint32_t nal_ref_idc,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtpFuA(&bit_buffer, nal_ref_idc, bitstream_parser_state);
}

std::unique_ptr<H264RtpFuAParser::RtpFuAState> H264RtpFuAParser::ParseRtpFuA(
    rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 RTP FU-A pseudo-NAL Unit.
  auto rtp_fua = std::make_unique<RtpFuAState>();

  // store input values
  rtp_fua->nal_ref_idc = nal_ref_idc;

  // first read the common header
  rtp_fua->header = H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp_fua->header == nullptr) {
    return nullptr;
  }

  // read the fu-A header
  if (!bit_buffer->ReadBits(&(rtp_fua->s_bit), 1)) {
    return nullptr;
  }
  if (!bit_buffer->ReadBits(&(rtp_fua->e_bit), 1)) {
    return nullptr;
  }
  if (!bit_buffer->ReadBits(&(rtp_fua->r_bit), 1)) {
    return nullptr;
  }
  if (!bit_buffer->ReadBits(&(rtp_fua->fu_type), 5)) {
    return nullptr;
  }

  if (rtp_fua->s_bit == 0) {
    // not the start of a fragmented NAL: stop here
    return rtp_fua;
  }

  // start of a fragmented NAL: keep reading
  rtp_fua->nal_unit_payload = H264NalUnitPayloadParser::ParseNalUnitPayload(
      bit_buffer, rtp_fua->nal_ref_idc, rtp_fua->fu_type,
      bitstream_parser_state);
  if (rtp_fua->nal_unit_payload == nullptr) {
    return nullptr;
  }

  return rtp_fua;
}

#ifdef FDUMP_DEFINE
void H264RtpFuAParser::RtpFuAState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "rtp_fua {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  header->fdump(outfp, indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "s_bit: %i", s_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "e_bit: %i", e_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "r_bit: %i", r_bit);

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

}  // namespace h264nal
