/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>

#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an H264 NAL Unit Header SVC Extension.
class H264NalUnitHeaderSvcExtensionParser {
 public:
  // The parsed state of the NAL Unit Header SVC Extension.
  struct NalUnitHeaderSvcExtensionState {
    NalUnitHeaderSvcExtensionState() = default;
    ~NalUnitHeaderSvcExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    NalUnitHeaderSvcExtensionState(const NalUnitHeaderSvcExtensionState&) =
        delete;
    NalUnitHeaderSvcExtensionState(NalUnitHeaderSvcExtensionState&&) = delete;
    NalUnitHeaderSvcExtensionState& operator=(
        const NalUnitHeaderSvcExtensionState&) = delete;
    NalUnitHeaderSvcExtensionState& operator=(
        NalUnitHeaderSvcExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t idr_flag = 0;
    uint32_t priority_id = 0;
    uint32_t no_inter_layer_pred_flag = 0;
    uint32_t dependency_id = 0;
    uint32_t quality_id = 0;
    uint32_t temporal_id = 0;
    uint32_t use_ref_base_pic_flag = 0;
    uint32_t discardable_flag = 0;
    uint32_t output_flag = 0;
    uint32_t reserved_three_2bits = 0;
  };

  // Unpack RBSP and parse NAL unit header state from the supplied buffer.
  static std::unique_ptr<NalUnitHeaderSvcExtensionState>
  ParseNalUnitHeaderSvcExtension(const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<NalUnitHeaderSvcExtensionState>
  ParseNalUnitHeaderSvcExtension(rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h264nal
