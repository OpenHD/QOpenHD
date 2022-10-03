/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_single_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"
#include "h264_nal_unit_parser.h"

namespace h264nal {

// General note: this is based off rfc6184.
// You can find it on this page:
// https://tools.ietf.org/html/rfc6184#section-5.6

// Unpack RBSP and parse RTP Single NAL Unit state from the supplied buffer.
std::unique_ptr<H264RtpSingleParser::RtpSingleState>
H264RtpSingleParser::ParseRtpSingle(
    const uint8_t* data, size_t length,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtpSingle(&bit_buffer, bitstream_parser_state);
}

std::unique_ptr<H264RtpSingleParser::RtpSingleState>
H264RtpSingleParser::ParseRtpSingle(
    rtc::BitBuffer* bit_buffer,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 RTP Single NAL Unit pseudo-NAL Unit.
  auto rtp_single = std::make_unique<RtpSingleState>();

  // nal_unit_header()
  rtp_single->nal_unit_header =
      H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp_single->nal_unit_header == nullptr) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: cannot ParseNalUnitHeader in rtp single\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  // nal_unit_payload()
  rtp_single->nal_unit_payload = H264NalUnitPayloadParser::ParseNalUnitPayload(
      bit_buffer, *(rtp_single->nal_unit_header), bitstream_parser_state);
  if (rtp_single->nal_unit_payload == nullptr) {
    return nullptr;
  }

  return rtp_single;
}

#ifdef FDUMP_DEFINE
void H264RtpSingleParser::RtpSingleState::fdump(FILE* outfp,
                                                int indent_level) const {
  fprintf(outfp, "rtp_single {");
  indent_level = indent_level_incr(indent_level);

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
