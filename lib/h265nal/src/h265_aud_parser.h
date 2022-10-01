/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a video sequence parameter set (AUD) data from
// an H265 NALU.
class H265AudParser {
 public:
  // The parsed state of the AUD.
  struct AudState {
    AudState() = default;
    ~AudState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    AudState(const AudState&) = delete;
    AudState(AudState&&) = delete;
    AudState& operator=(const AudState&) = delete;
    AudState& operator=(AudState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t pic_type = 0;
  };

  // Unpack RBSP and parse AUD state from the supplied buffer.
  static std::unique_ptr<AudState> ParseAud(const uint8_t* data,
                                            size_t length) noexcept;
  static std::unique_ptr<AudState> ParseAud(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
