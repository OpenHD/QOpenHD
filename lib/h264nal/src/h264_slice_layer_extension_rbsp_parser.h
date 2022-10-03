/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_nal_unit_header_parser.h"
#include "h264_slice_header_in_scalable_extension_parser.h"
#include "h264_slice_header_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out a slice_layer_extension_rbsp NAL unit
// from an H264 NALU.
class H264SliceLayerExtensionRbspParser {
 public:
  // The parsed state of the slice. Only some select values are stored.
  // Add more as they are actually needed.
  struct SliceLayerExtensionRbspState {
    SliceLayerExtensionRbspState() = default;
    ~SliceLayerExtensionRbspState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SliceLayerExtensionRbspState(const SliceLayerExtensionRbspState&) = delete;
    SliceLayerExtensionRbspState(SliceLayerExtensionRbspState&&) = delete;
    SliceLayerExtensionRbspState& operator=(
        const SliceLayerExtensionRbspState&) = delete;
    SliceLayerExtensionRbspState& operator=(SliceLayerExtensionRbspState&&) =
        delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t svc_extension_flag = 0;
    uint32_t avc_3d_extension_flag = 0;
    uint32_t nal_ref_idc = 0;
    uint32_t nal_unit_type = 0;

    // contents
    // TODO(chemag): slice_header_in_scalable_extension()
    std::unique_ptr<struct H264SliceHeaderInScalableExtensionParser::
                        SliceHeaderInScalableExtensionState>
        slice_header_in_scalable_extension;
    // slice_data_in_scalable_extension()
    // slice_header_in_3davc_extension()
    // slice_data_in_3davc_extension()
    std::unique_ptr<struct H264SliceHeaderParser::SliceHeaderState>
        slice_header;
    // slice_data()

    // rbsp_slice_trailing_bits()
  };

  // Unpack RBSP and parse slice state from the supplied buffer.
  static std::unique_ptr<SliceLayerExtensionRbspState>
  ParseSliceLayerExtensionRbsp(
      const uint8_t* data, size_t length,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<SliceLayerExtensionRbspState>
  ParseSliceLayerExtensionRbsp(
      rtc::BitBuffer* bit_buffer,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
