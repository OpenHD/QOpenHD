/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_nal_unit_header_parser.h"
#include "h264_pps_parser.h"
#include "h264_prefix_nal_unit_parser.h"
#include "h264_slice_layer_extension_rbsp_parser.h"
#include "h264_slice_layer_without_partitioning_rbsp_parser.h"
#include "h264_sps_parser.h"
#include "h264_subset_sps_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an H264 NAL Unit Payload.
class H264NalUnitPayloadParser {
 public:
  // The parsed state of the NAL Unit Payload. Only some select values are
  // stored. Add more as they are actually needed.
  struct NalUnitPayloadState {
    NalUnitPayloadState() = default;
    ~NalUnitPayloadState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    NalUnitPayloadState(const NalUnitPayloadState&) = delete;
    NalUnitPayloadState(NalUnitPayloadState&&) = delete;
    NalUnitPayloadState& operator=(const NalUnitPayloadState&) = delete;
    NalUnitPayloadState& operator=(NalUnitPayloadState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level, uint32_t nal_unit_type) const;
#endif  // FDUMP_DEFINE

    std::shared_ptr<struct H264SpsParser::SpsState> sps;
    std::shared_ptr<struct H264PpsParser::PpsState> pps;
    std::unique_ptr<struct H264SliceLayerWithoutPartitioningRbspParser::
                        SliceLayerWithoutPartitioningRbspState>
        slice_layer_without_partitioning_rbsp;
    std::unique_ptr<struct H264PrefixNalUnitRbspParser::PrefixNalUnitRbspState>
        prefix_nal_unit;
    std::shared_ptr<struct H264SubsetSpsParser::SubsetSpsState> subset_sps;
    std::unique_ptr<
        struct H264SliceLayerExtensionRbspParser::SliceLayerExtensionRbspState>
        slice_layer_extension_rbsp;
  };

  // Unpack RBSP and parse NAL unit payload state from the supplied buffer.
  static std::unique_ptr<NalUnitPayloadState> ParseNalUnitPayload(
      const uint8_t* data, size_t length,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<NalUnitPayloadState> ParseNalUnitPayload(
      rtc::BitBuffer* bit_buffer,
      H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
  // used by RTP fu-a, which has a pseudo-NALU header
  static std::unique_ptr<NalUnitPayloadState> ParseNalUnitPayload(
      rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc, uint32_t nal_unit_type,
      struct H264BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h264nal
