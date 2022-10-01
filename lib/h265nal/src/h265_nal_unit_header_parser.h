/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "h265_common.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out an H265 NAL Unit Header.
class H265NalUnitHeaderParser {
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
    uint32_t nal_unit_type = 0;
    uint32_t nuh_layer_id = 0;
    uint32_t nuh_temporal_id_plus1 = 0;
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

}  // namespace h265nal
