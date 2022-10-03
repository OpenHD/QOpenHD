/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_sps_svc_extension_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"

namespace h264nal {

// General note: this is based off the 2016/02 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse SPS SVC extension state from the supplied buffer.
std::unique_ptr<H264SpsSvcExtensionParser::SpsSvcExtensionState>
H264SpsSvcExtensionParser::ParseSpsSvcExtension(
    const uint8_t* data, size_t length, uint32_t ChromaArrayType) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSpsSvcExtension(&bit_buffer, ChromaArrayType);
}

std::unique_ptr<H264SpsSvcExtensionParser::SpsSvcExtensionState>
H264SpsSvcExtensionParser::ParseSpsSvcExtension(
    rtc::BitBuffer* bit_buffer, uint32_t ChromaArrayType) noexcept {
  // H264 seq_parameter_set_svc_extension() parser.
  // Section G.7.3.2.1.4 ("Sequence parameter set SVC extension syntax") of
  // the H.264 standard for a complete description.
  auto sps_svc_extension = std::make_unique<SpsSvcExtensionState>();

  // store input values
  sps_svc_extension->ChromaArrayType = ChromaArrayType;

  // inter_layer_deblocking_filter_control_present_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_svc_extension
                ->inter_layer_deblocking_filter_control_present_flag),
          1)) {
    return nullptr;
  }

  // extended_spatial_scalability_idc  u(2)
  if (!bit_buffer->ReadBits(
          &(sps_svc_extension->extended_spatial_scalability_idc), 2)) {
    return nullptr;
  }

  if (sps_svc_extension->ChromaArrayType == 1 ||
      sps_svc_extension->ChromaArrayType == 2) {
    // chroma_phase_x_plus1_flag  u(1)
    if (!bit_buffer->ReadBits(&(sps_svc_extension->chroma_phase_x_plus1_flag),
                              1)) {
      return nullptr;
    }
  }

  if (sps_svc_extension->ChromaArrayType == 1) {
    // chroma_phase_y_plus1  u(2)
    if (!bit_buffer->ReadBits(&(sps_svc_extension->chroma_phase_y_plus1), 2)) {
      return nullptr;
    }
  }

  if (sps_svc_extension->extended_spatial_scalability_idc == 1) {
    if (sps_svc_extension->ChromaArrayType > 0) {
      // seq_ref_layer_chroma_phase_x_plus1_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(sps_svc_extension->seq_ref_layer_chroma_phase_x_plus1_flag),
              1)) {
        return nullptr;
      }

      // seq_ref_layer_chroma_phase_y_plus1  u(2)
      if (!bit_buffer->ReadBits(
              &(sps_svc_extension->seq_ref_layer_chroma_phase_y_plus1), 2)) {
        return nullptr;
      }
    }

    // seq_scaled_ref_layer_left_offset  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_svc_extension->seq_scaled_ref_layer_left_offset))) {
      return nullptr;
    }

    // seq_scaled_ref_layer_top_offset  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_svc_extension->seq_scaled_ref_layer_top_offset))) {
      return nullptr;
    }

    // seq_scaled_ref_layer_right_offset  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_svc_extension->seq_scaled_ref_layer_right_offset))) {
      return nullptr;
    }

    // seq_scaled_ref_layer_bottom_offset  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(sps_svc_extension->seq_scaled_ref_layer_bottom_offset))) {
      return nullptr;
    }
  }

  // seq_tcoeff_level_prediction_flag  u(1)
  if (!bit_buffer->ReadBits(
          &(sps_svc_extension->seq_tcoeff_level_prediction_flag), 1)) {
    return nullptr;
  }

  if (sps_svc_extension->seq_tcoeff_level_prediction_flag == 1) {
    // adaptive_tcoeff_level_prediction_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(sps_svc_extension->adaptive_tcoeff_level_prediction_flag), 1)) {
      return nullptr;
    }
  }

  // slice_header_restriction_flag  u(1)
  if (!bit_buffer->ReadBits(&(sps_svc_extension->slice_header_restriction_flag),
                            1)) {
    return nullptr;
  }

  return sps_svc_extension;
}

#ifdef FDUMP_DEFINE
void H264SpsSvcExtensionParser::SpsSvcExtensionState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "seq_parameter_set_svc_extension {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "inter_layer_deblocking_filter_control_present_flag: %i",
          inter_layer_deblocking_filter_control_present_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "extended_spatial_scalability_idc: %i",
          extended_spatial_scalability_idc);

  if (ChromaArrayType == 1 || ChromaArrayType == 2) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_phase_x_plus1_flag: %i", chroma_phase_x_plus1_flag);
  }

  if (ChromaArrayType == 1) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_phase_y_plus1: %i", chroma_phase_y_plus1);
  }

  if (extended_spatial_scalability_idc == 1) {
    if (ChromaArrayType > 0) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "seq_ref_layer_chroma_phase_x_plus1_flag: %i",
              seq_ref_layer_chroma_phase_x_plus1_flag);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "seq_ref_layer_chroma_phase_y_plus1: %i",
              seq_ref_layer_chroma_phase_y_plus1);
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaled_ref_layer_left_offset: %i",
            seq_scaled_ref_layer_left_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaled_ref_layer_top_offset: %i",
            seq_scaled_ref_layer_top_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaled_ref_layer_right_offset: %i",
            seq_scaled_ref_layer_right_offset);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "seq_scaled_ref_layer_bottom_offset: %i",
            seq_scaled_ref_layer_bottom_offset);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "seq_tcoeff_level_prediction_flag: %i",
          seq_tcoeff_level_prediction_flag);

  if (seq_tcoeff_level_prediction_flag == 1) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "adaptive_tcoeff_level_prediction_flag: %i",
            adaptive_tcoeff_level_prediction_flag);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "slice_header_restriction_flag: %i",
          slice_header_restriction_flag);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
