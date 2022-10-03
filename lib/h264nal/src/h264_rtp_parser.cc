/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"
#include "h264_nal_unit_parser.h"
#include "h264_rtp_stapa_parser.h"

namespace h264nal {

// General note: this is based off rfc6184.
// You can find it on this page:
// https://tools.ietf.org/html/rfc6184#section-5.6

// Unpack RBSP and parse RTP NAL Unit state from the supplied buffer.
std::unique_ptr<H264RtpParser::RtpState> H264RtpParser::ParseRtp(
    const uint8_t* data, size_t length,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtp(&bit_buffer, bitstream_parser_state);
}

std::unique_ptr<H264RtpParser::RtpState> H264RtpParser::ParseRtp(
    rtc::BitBuffer* bit_buffer,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 RTP NAL Unit pseudo-NAL Unit.
  auto rtp = std::make_unique<RtpState>();

  // peek a pseudo-nal_unit_header
  rtp->nal_unit_header =
      H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp->nal_unit_header == nullptr) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: cannot ParseNalUnitHeader in rtp packet\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }
  bit_buffer->Seek(0, 0);

  if (rtp->nal_unit_header->nal_unit_type <= 23) {
    // rtp_single()
    rtp->rtp_single =
        H264RtpSingleParser::ParseRtpSingle(bit_buffer, bitstream_parser_state);
    if (rtp->rtp_single == nullptr) {
      return nullptr;
    }

  } else if (rtp->nal_unit_header->nal_unit_type == RTP_STAPA_NUT) {
    // rtp_stapa()
    rtp->rtp_stapa =
        H264RtpStapAParser::ParseRtpStapA(bit_buffer, bitstream_parser_state);
    if (rtp->rtp_stapa == nullptr) {
      return nullptr;
    }

  } else if (rtp->nal_unit_header->nal_unit_type == RTP_FUA_NUT) {
    // rtp_fua()
    rtp->rtp_fua = H264RtpFuAParser::ParseRtpFuA(
        bit_buffer, rtp->nal_unit_header->nal_ref_idc, bitstream_parser_state);
    if (rtp->rtp_fua == nullptr) {
      return nullptr;
    }
  }

  return rtp;
}

#ifdef FDUMP_DEFINE
void H264RtpParser::RtpState::fdump(FILE* outfp, int indent_level) const {
  fprintf(outfp, "rtp {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  nal_unit_header->fdump(outfp, indent_level);

  if (nal_unit_header->nal_unit_type <= 23) {
    // rtp_single()
    rtp_single->fdump(outfp, indent_level);
  } else if (nal_unit_header->nal_unit_type == RTP_STAPA_NUT) {
    // rtp_stapa()
    rtp_stapa->fdump(outfp, indent_level);
  } else if (nal_unit_header->nal_unit_type == RTP_FUA_NUT) {
    // rtp_fua()
    rtp_fua->fdump(outfp, indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
