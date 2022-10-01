/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_rtp_stapa_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// General note: this is based off rfc6184/
// You can find it on this page:
// https://tools.ietf.org/html/rfc6184#section-5.6

// Unpack RBSP and parse RTP STAP-A state from the supplied buffer.
std::unique_ptr<H264RtpStapAParser::RtpStapAState>
H264RtpStapAParser::ParseRtpStapA(
    const uint8_t* data, size_t length,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRtpStapA(&bit_buffer, bitstream_parser_state);
}

std::unique_ptr<H264RtpStapAParser::RtpStapAState>
H264RtpStapAParser::ParseRtpStapA(
    rtc::BitBuffer* bit_buffer,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 RTP STAP-A pseudo-NAL Unit.
  auto rtp_stapa = std::make_unique<RtpStapAState>();

  // first read the common header
  rtp_stapa->header = H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer);
  if (rtp_stapa->header == nullptr) {
#ifdef FPRINT_ERRORS
    fprintf(stderr, "error: cannot ParseNalUnitHeader in rtp ap\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  while (bit_buffer->RemainingBitCount() > 0) {
    // NALU size
    uint32_t nalu_size;
    if (!bit_buffer->ReadBits(&nalu_size, 16)) {
      return nullptr;
    }
    rtp_stapa->nal_unit_sizes.push_back(nalu_size);

    // NALU header
    rtp_stapa->nal_unit_headers.push_back(
        H264NalUnitHeaderParser::ParseNalUnitHeader(bit_buffer));
    if (rtp_stapa->nal_unit_headers.back() == nullptr) {
#ifdef FPRINT_ERRORS
      fprintf(stderr, "error: cannot ParseNalUnitHeader in rtp ap\n");
#endif  // FPRINT_ERRORS
      return nullptr;
    }

    // NALU payload
    rtp_stapa->nal_unit_payloads.push_back(
        H264NalUnitPayloadParser::ParseNalUnitPayload(
            bit_buffer, *(rtp_stapa->nal_unit_headers.back()),
            bitstream_parser_state));
    if (rtp_stapa->nal_unit_payloads.back() == nullptr) {
      return nullptr;
    }
  }
  return rtp_stapa;
}

#ifdef FDUMP_DEFINE
void H264RtpStapAParser::RtpStapAState::fdump(FILE* outfp,
                                              int indent_level) const {
  fprintf(outfp, "rtp_stapa {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  header->fdump(outfp, indent_level);

  for (unsigned int i = 0; i < nal_unit_sizes.size(); ++i) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "nal_unit_size: %zu", nal_unit_sizes[i]);

    fdump_indent_level(outfp, indent_level);
    nal_unit_headers[i]->fdump(outfp, indent_level);

    fdump_indent_level(outfp, indent_level);
    nal_unit_payloads[i]->fdump(outfp, nal_unit_headers[i]->nal_unit_type,
                                indent_level);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
