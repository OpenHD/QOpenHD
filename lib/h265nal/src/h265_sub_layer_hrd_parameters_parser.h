/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a sub_layer_hrd_parameters NAL from an H265 NALU.
class H265SubLayerHrdParametersParser {
 public:
  // The parsed state of the HRD parameters. Only some select values are stored.
  // Add more as they are actually needed.
  struct SubLayerHrdParametersState {
    SubLayerHrdParametersState() = default;
    ~SubLayerHrdParametersState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    SubLayerHrdParametersState(const SubLayerHrdParametersState&) = delete;
    SubLayerHrdParametersState(SubLayerHrdParametersState&&) = delete;
    SubLayerHrdParametersState& operator=(const SubLayerHrdParametersState&) =
        delete;
    SubLayerHrdParametersState& operator=(SubLayerHrdParametersState&&) =
        delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t subLayerId = 0;
    uint32_t CpbCnt = 0;
    uint32_t sub_pic_hrd_params_present_flag = 0;

    // contents
    std::vector<uint32_t> bit_rate_value_minus1;
    std::vector<uint32_t> cpb_size_value_minus1;
    std::vector<uint32_t> cpb_size_du_value_minus1;
    std::vector<uint32_t> bit_rate_du_value_minus1;
    std::vector<uint32_t> cbr_flag;
  };

  // Unpack RBSP and parse VPS state from the supplied buffer.
  static std::unique_ptr<SubLayerHrdParametersState> ParseSubLayerHrdParameters(
      const uint8_t* data, size_t length, uint32_t subLayerId, uint32_t CpbCnt,
      uint32_t sub_pic_hrd_params_present_flag) noexcept;
  static std::unique_ptr<SubLayerHrdParametersState> ParseSubLayerHrdParameters(
      rtc::BitBuffer* bit_buffer, uint32_t subLayerId, uint32_t CpbCnt,
      uint32_t sub_pic_hrd_params_present_flag) noexcept;
};

}  // namespace h265nal
