/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a sequence parameter set multilayer extension syntax
// (`sps_multilayer_extension()`, as defined in Section F.7.3.2.2.4 of the
// 2018-02 standard) from an H265 NALU.
class H265SpsMultilayerExtensionParser {
 public:
  // The parsed state of the SpsMultilayerExtension.
  struct SpsMultilayerExtensionState {
    SpsMultilayerExtensionState() = default;
    ~SpsMultilayerExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SpsMultilayerExtensionState(const SpsMultilayerExtensionState&) = delete;
    SpsMultilayerExtensionState(SpsMultilayerExtensionState&&) = delete;
    SpsMultilayerExtensionState& operator=(const SpsMultilayerExtensionState&) =
        delete;
    SpsMultilayerExtensionState& operator=(SpsMultilayerExtensionState&&) =
        delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    uint32_t inter_view_mv_vert_constraint_flag = 0;
  };

  // Unpack RBSP and parse SpsMultilayerExtension state from the supplied
  // buffer.
  static std::unique_ptr<SpsMultilayerExtensionState>
  ParseSpsMultilayerExtension(const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<SpsMultilayerExtensionState>
  ParseSpsMultilayerExtension(rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
