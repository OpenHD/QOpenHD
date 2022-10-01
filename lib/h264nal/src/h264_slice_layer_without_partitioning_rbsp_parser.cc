/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_slice_layer_without_partitioning_rbsp_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_slice_header_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse slice header state from the supplied buffer.
std::unique_ptr<H264SliceLayerWithoutPartitioningRbspParser::
                    SliceLayerWithoutPartitioningRbspState>
H264SliceLayerWithoutPartitioningRbspParser::
    ParseSliceLayerWithoutPartitioningRbsp(
        const uint8_t* data, size_t length, uint32_t nal_ref_idc,
        uint32_t nal_unit_type,
        struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSliceLayerWithoutPartitioningRbsp(
      &bit_buffer, nal_ref_idc, nal_unit_type, bitstream_parser_state);
}

std::unique_ptr<H264SliceLayerWithoutPartitioningRbspParser::
                    SliceLayerWithoutPartitioningRbspState>
H264SliceLayerWithoutPartitioningRbspParser::
    ParseSliceLayerWithoutPartitioningRbsp(
        rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc,
        uint32_t nal_unit_type,
        struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 slice (slice_layer_without_partitioning_rbsp()) NAL Unit.
  // Section 7.3.2.8 ("Slice layer without partitioning RBSP syntax") of
  // the H.264 standard for a complete description.
  auto slice_layer_without_partitioning_rbsp =
      std::make_unique<SliceLayerWithoutPartitioningRbspState>();

  // input parameters
  slice_layer_without_partitioning_rbsp->nal_ref_idc = nal_ref_idc;
  slice_layer_without_partitioning_rbsp->nal_unit_type = nal_unit_type;

  // slice_header(slice_type)
  slice_layer_without_partitioning_rbsp->slice_header =
      H264SliceHeaderParser::ParseSliceHeader(
          bit_buffer, slice_layer_without_partitioning_rbsp->nal_ref_idc,
          slice_layer_without_partitioning_rbsp->nal_unit_type,
          bitstream_parser_state);
  if (slice_layer_without_partitioning_rbsp->slice_header == nullptr) {
    return nullptr;
  }

  // slice_data()
  // rbsp_slice_trailing_bits()

  return slice_layer_without_partitioning_rbsp;
}

#ifdef FDUMP_DEFINE
void H264SliceLayerWithoutPartitioningRbspParser::
    SliceLayerWithoutPartitioningRbspState::fdump(FILE* outfp,
                                                  int indent_level) const {
  fprintf(outfp, "slice_layer_without_partitioning_rbsp {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  slice_header->fdump(outfp, indent_level);

  // slice_data()
  // rbsp_slice_trailing_bits()

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
