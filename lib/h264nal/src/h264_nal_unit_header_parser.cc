/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_nal_unit_header_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse NAL Unit header state from the supplied buffer.
std::unique_ptr<H264NalUnitHeaderParser::NalUnitHeaderState>
H264NalUnitHeaderParser::ParseNalUnitHeader(const uint8_t* data,
                                            size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseNalUnitHeader(&bit_buffer);
}

bool H264NalUnitHeaderParser::GetNalUnitType(const uint8_t* data,
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

std::unique_ptr<H264NalUnitHeaderParser::NalUnitHeaderState>
H264NalUnitHeaderParser::ParseNalUnitHeader(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H264 NAL Unit Header (nal_unit_header()) parser.
  // Section 7.3.1.2 ("NAL unit header syntax") of the H.264
  // standard for a complete description.
  auto nal_unit_header = std::make_unique<NalUnitHeaderState>();

  // forbidden_zero_bit  f(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->forbidden_zero_bit, 1)) {
    return nullptr;
  }

  // nal_ref_idc  u(2)
  if (!bit_buffer->ReadBits(&nal_unit_header->nal_ref_idc, 2)) {
    return nullptr;
  }

  // nal_unit_type  u(5)
  if (!bit_buffer->ReadBits(&nal_unit_header->nal_unit_type, 5)) {
    return nullptr;
  }

  if (nal_unit_header->nal_unit_type == 14 ||
      nal_unit_header->nal_unit_type == 20 ||
      nal_unit_header->nal_unit_type == 21) {
    if (nal_unit_header->nal_unit_type != 21) {
      // svc_extension_flag  u(1)
      if (!bit_buffer->ReadBits(&nal_unit_header->svc_extension_flag, 1)) {
        return nullptr;
      }
      if (nal_unit_header->svc_extension_flag == 1) {
        // nal_unit_header_svc_extension()
        nal_unit_header->nal_unit_header_svc_extension =
            H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
                bit_buffer);
        if (nal_unit_header->nal_unit_header_svc_extension == nullptr) {
          return nullptr;
        }
      }

    } else {
      // avc_3d_extension_flag  u(1)
      if (!bit_buffer->ReadBits(&nal_unit_header->avc_3d_extension_flag, 1)) {
        return nullptr;
      }
    }
  }

  return nal_unit_header;
}

#ifdef FDUMP_DEFINE
void H264NalUnitHeaderParser::NalUnitHeaderState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "nal_unit_header {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "forbidden_zero_bit: %i", forbidden_zero_bit);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "nal_ref_idc: %i", nal_ref_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "nal_unit_type: %i", nal_unit_type);

  if (nal_unit_type == 14 || nal_unit_type == 20 || nal_unit_type == 21) {
    if (nal_unit_type != 21) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "svc_extension_flag: %i", svc_extension_flag);
      if (svc_extension_flag && nal_unit_header_svc_extension != nullptr) {
        fdump_indent_level(outfp, indent_level);
        nal_unit_header_svc_extension->fdump(outfp, indent_level);
      }
    } else {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "avc_3d_extension_flag: %i", avc_3d_extension_flag);
    }
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
