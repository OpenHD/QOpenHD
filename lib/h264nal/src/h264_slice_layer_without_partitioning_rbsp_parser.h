/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_slice_header_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a slice_layer_without_partitioning_rbsp NAL unit
// from an H264 NALU.
class H264SliceLayerWithoutPartitioningRbspParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceLayerWithoutPartitioningRbspState {
    SliceLayerWithoutPartitioningRbspState() = default;
    ~SliceLayerWithoutPartitioningRbspState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceLayerWithoutPartitioningRbspState(
        const SliceLayerWithoutPartitioningRbspState&) = delete;
    SliceLayerWithoutPartitioningRbspState(
        SliceLayerWithoutPartitioningRbspState&&) = delete;
    SliceLayerWithoutPartitioningRbspState& operator=(
        const SliceLayerWithoutPartitioningRbspState&) = delete;
    SliceLayerWithoutPartitioningRbspState& operator=(
        SliceLayerWithoutPartitioningRbspState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_ref_idc = 0;
    uint32_t nal_unit_type = 0;

    // contents
    std::unique_ptr<struct H264SliceHeaderParser::SliceHeaderState>
        slice_header;

    // slice_data()
    // rbsp_slice_trailing_bits()
  };

  // Unpack RBSP and parse slice state from the supplied buffer.
  static std::unique_ptr<SliceLayerWithoutPartitioningRbspState>
  ParseSliceLayerWithoutPartitioningRbsp(
      const uint8_t* data, size_t length, uint32_t nal_ref_idc,
      uint32_t nal_unit_type,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceLayerWithoutPartitioningRbspState>
  ParseSliceLayerWithoutPartitioningRbsp(
      rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc, uint32_t nal_unit_type,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
