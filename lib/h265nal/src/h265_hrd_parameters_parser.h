/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h265_sub_layer_hrd_parameters_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a hrd_parameters NAL from an H265 NALU.
class H265HrdParametersParser {
 public:
  // The parsed state of the HRD parameters. Only some select values are stored.
  // Add more as they are actually needed.
  struct HrdParametersState {
    HrdParametersState() = default;
    ~HrdParametersState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    HrdParametersState(const HrdParametersState&) = delete;
    HrdParametersState(HrdParametersState&&) = delete;
    HrdParametersState& operator=(const HrdParametersState&) = delete;
    HrdParametersState& operator=(HrdParametersState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t commonInfPresentFlag = 0;
    uint32_t maxNumSubLayersMinus1 = 0;

    // contents
    uint32_t nal_hrd_parameters_present_flag = 0;
    uint32_t vcl_hrd_parameters_present_flag = 0;
    uint32_t sub_pic_hrd_params_present_flag = 0;
    uint32_t tick_divisor_minus2 = 0;
    uint32_t du_cpb_removal_delay_increment_length_minus1 = 0;
    uint32_t sub_pic_cpb_params_in_pic_timing_sei_flag = 0;
    uint32_t dpb_output_delay_du_length_minus1 = 0;
    uint32_t bit_rate_scale = 0;
    uint32_t cpb_size_scale = 0;
    uint32_t cpb_size_du_scale = 0;
    uint32_t initial_cpb_removal_delay_length_minus1 = 0;
    uint32_t au_cpb_removal_delay_length_minus1 = 0;
    uint32_t dpb_output_delay_length_minus1 = 0;
    std::vector<uint32_t> fixed_pic_rate_general_flag;
    std::vector<uint32_t> fixed_pic_rate_within_cvs_flag;
    std::vector<uint32_t> elemental_duration_in_tc_minus1;
    std::vector<uint32_t> low_delay_hrd_flag;
    std::vector<uint32_t> cpb_cnt_minus1;
    std::vector<std::unique_ptr<
        struct H265SubLayerHrdParametersParser::SubLayerHrdParametersState>>
        sub_layer_hrd_parameters_vector;
  };

  // Unpack RBSP and parse VPS state from the supplied buffer.
  static std::unique_ptr<HrdParametersState> ParseHrdParameters(
      const uint8_t* data, size_t length, uint32_t commonInfPresentFlag,
      uint32_t maxNumSubLayersMinus1) noexcept;
  static std::unique_ptr<HrdParametersState> ParseHrdParameters(
      rtc::BitBuffer* bit_buffer, uint32_t commonInfPresentFlag,
      uint32_t maxNumSubLayersMinus1) noexcept;
};

}  // namespace h265nal
