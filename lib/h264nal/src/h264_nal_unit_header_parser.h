/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h264_common.h"
#include "h264_nal_unit_header_svc_extension_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an H264 NAL Unit Header.
class H264NalUnitHeaderParser {
 public:
  // The parsed state of the NAL Unit Header.
  struct NalUnitHeaderState {
    NalUnitHeaderState() = default;
    ~NalUnitHeaderState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    NalUnitHeaderState(const NalUnitHeaderState&) = delete;
    NalUnitHeaderState(NalUnitHeaderState&&) = delete;
    NalUnitHeaderState& operator=(const NalUnitHeaderState&) = delete;
    NalUnitHeaderState& operator=(NalUnitHeaderState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t forbidden_zero_bit = 0;
    uint32_t nal_ref_idc = 0;
    uint32_t nal_unit_type = 0;
    uint32_t svc_extension_flag = 0;
    uint32_t avc_3d_extension_flag = 0;
    std::unique_ptr<struct H264NalUnitHeaderSvcExtensionParser::
                        NalUnitHeaderSvcExtensionState>
        nal_unit_header_svc_extension;
    // TODO(chema): nal_unit_header_3davc_extension()  // specified in Annex J
    // TODO(chema): nal_unit_header_mvc_extension()  // specified in Annex H
  };

  // Unpack RBSP and parse NAL unit header state from the supplied buffer.
  static std::unique_ptr<NalUnitHeaderState> ParseNalUnitHeader(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<NalUnitHeaderState> ParseNalUnitHeader(
      rtc::BitBuffer* bit_buffer) noexcept;
  // Parses nalu type from the given buffer
  static bool GetNalUnitType(const uint8_t* data, const size_t length,
                             NalUnitType& naluType) noexcept;
};

}  // namespace h264nal
