/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_rtp_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"
#include "h265_nal_unit_parser.h"

namespace h265nal {

// General note: this is based off rfc7798.
// You can find it on this page:
// https://tools.ietf.org/html/rfc7798#section-4.4.1

// Unpack RBSP and parse RTP NAL Unit state from the supplied buffer.
std::unique_ptr<H265RtpParser::RtpState> H265RtpParser::ParseRtp(
    const uint8_t* data, size_t length,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtp(&bit_buffer, bitstream_parser_state);
}

std::unique_ptr<H265RtpParser::RtpState> H265RtpParser::ParseRtp(
    rtc::BitBuffer* bit_buffer,
    struct H265BitstreamParserState* bitstream_parser_state) noexcept {
  // H265 RTP NAL Unit pseudo-NAL Unit.
  auto rtp = std::make_unique<RtpState>();

  // peek a pseudo-nal_unit_header
  rtp->nal_unit_header =
      H265NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp->nal_unit_header == nullptr) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: cannot ParseNalUnitHeader in rtp packet\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }
  bit_buffer->Seek(0, 0);

  if (rtp->nal_unit_header->nal_unit_type <= 47) {
    // rtp_single()
    rtp->rtp_single =
        H265RtpSingleParser::ParseRtpSingle(bit_buffer, bitstream_parser_state);
    if (rtp->rtp_single == nullptr) {
      return nullptr;
    }

  } else if (rtp->nal_unit_header->nal_unit_type == AP) {
    // rtp_ap()
    rtp->rtp_ap =
        H265RtpApParser::ParseRtpAp(bit_buffer, bitstream_parser_state);
    if (rtp->rtp_ap == nullptr) {
      return nullptr;
    }

  } else if (rtp->nal_unit_header->nal_unit_type == FU) {
    // rtp_fu()
    rtp->rtp_fu =
        H265RtpFuParser::ParseRtpFu(bit_buffer, bitstream_parser_state);
    if (rtp->rtp_fu == nullptr) {
      return nullptr;
    }
  }

  return rtp;
}

#ifdef FDUMP_DEFINE
void H265RtpParser::RtpState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "rtp {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  nal_unit_header->fdump(outfp, indent_level);

  if (nal_unit_header->nal_unit_type <= 47) {
    // rtp_single()
    rtp_single->fdump(outfp, indent_level);
  } else if (nal_unit_header->nal_unit_type == AP) {
    // rtp_ap()
    rtp_ap->fdump(outfp, indent_level);
  } else if (nal_unit_header->nal_unit_type == FU) {
    // rtp_fu()
    rtp_fu->fdump(outfp, indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
