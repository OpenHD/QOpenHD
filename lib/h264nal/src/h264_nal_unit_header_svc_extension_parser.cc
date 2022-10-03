/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_nal_unit_header_svc_extension_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"

namespace h264nal {

// General note: this is based off the 2016/02 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse NAL Unit header SVC extension state from the
// supplied buffer.
std::unique_ptr<
    H264NalUnitHeaderSvcExtensionParser::NalUnitHeaderSvcExtensionState>
H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
    const uint8_t* data, size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseNalUnitHeaderSvcExtension(&bit_buffer);
}

std::unique_ptr<
    H264NalUnitHeaderSvcExtensionParser::NalUnitHeaderSvcExtensionState>
H264NalUnitHeaderSvcExtensionParser::ParseNalUnitHeaderSvcExtension(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H264 NAL Unit Header SVC Extension (nal_unit_header_svc_extension())
  // parser.
  // Section G.7.3.1.1 ("NAL unit header SVC Extension syntax") of the H.264
  // standard for a complete description.
  auto nal_unit_header = std::make_unique<NalUnitHeaderSvcExtensionState>();

  // idr_flag  u(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->idr_flag, 1)) {
    return nullptr;
  }

  // priority_id  u(6)
  if (!bit_buffer->ReadBits(&nal_unit_header->priority_id, 6)) {
    return nullptr;
  }

  // no_inter_layer_pred_flag  u(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->no_inter_layer_pred_flag, 1)) {
    return nullptr;
  }

  // dependency_id  u(3)
  if (!bit_buffer->ReadBits(&nal_unit_header->dependency_id, 3)) {
    return nullptr;
  }

  // quality_id  u(4)
  if (!bit_buffer->ReadBits(&nal_unit_header->quality_id, 4)) {
    return nullptr;
  }

  // temporal_id  u(3)
  if (!bit_buffer->ReadBits(&nal_unit_header->temporal_id, 3)) {
    return nullptr;
  }

  // use_ref_base_pic_flag  u(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->use_ref_base_pic_flag, 1)) {
    return nullptr;
  }

  // discardable_flag  u(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->discardable_flag, 1)) {
    return nullptr;
  }

  // output_flag  u(1)
  if (!bit_buffer->ReadBits(&nal_unit_header->output_flag, 1)) {
    return nullptr;
  }

  // reserved_three_2bits  u(2)
  if (!bit_buffer->ReadBits(&nal_unit_header->reserved_three_2bits, 2)) {
    return nullptr;
  }

  return nal_unit_header;
}

#ifdef FDUMP_DEFINE
void H264NalUnitHeaderSvcExtensionParser::NalUnitHeaderSvcExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "nal_unit_header_svc_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "idr_flag: %i", idr_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "priority_id: %i", priority_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "no_inter_layer_pred_flag: %i", no_inter_layer_pred_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "dependency_id: %i", dependency_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "quality_id: %i", quality_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "temporal_id: %i", temporal_id);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "use_ref_base_pic_flag: %i", use_ref_base_pic_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "discardable_flag: %i", discardable_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "output_flag: %i", output_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_three_2bits: %i", reserved_three_2bits);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
