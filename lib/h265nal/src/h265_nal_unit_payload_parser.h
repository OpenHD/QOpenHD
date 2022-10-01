/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h265_aud_parser.h"
#include "h265_common.h"
#include "h265_pps_parser.h"
#include "h265_slice_parser.h"
#include "h265_sps_parser.h"
#include "h265_vps_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out an H265 NAL Unit Payload.
class H265NalUnitPayloadParser {
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

    std::shared_ptr<struct H265VpsParser::VpsState> vps;
    std::shared_ptr<struct H265SpsParser::SpsState> sps;
    std::shared_ptr<struct H265PpsParser::PpsState> pps;
    std::unique_ptr<struct H265AudParser::AudState> aud;
    std::unique_ptr<struct H265SliceSegmentLayerParser::SliceSegmentLayerState>
        slice_segment_layer;
  };

  // Unpack RBSP and parse NAL unit payload state from the supplied buffer.
  static std::unique_ptr<NalUnitPayloadState> ParseNalUnitPayload(
      const uint8_t* data, size_t length, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
  static std::unique_ptr<NalUnitPayloadState> ParseNalUnitPayload(
      rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type,
      struct H265BitstreamParserState* bitstream_parser_state) noexcept;
};

}  // namespace h265nal
