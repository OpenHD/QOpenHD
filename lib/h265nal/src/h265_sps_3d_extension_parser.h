/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// A class for parsing out a sequence parameter set 3d extension syntax
// (`sps_3d_extension()`, as defined in Section I.7.3.2.2.5 of the
// 2018-02 standard) from an H265 NALU.
class H265Sps3dExtensionParser {
 public:
  // The parsed state of the Sps3dExtension.
  struct Sps3dExtensionState {
    Sps3dExtensionState() = default;
    ~Sps3dExtensionState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    Sps3dExtensionState(const Sps3dExtensionState&) = delete;
    Sps3dExtensionState(Sps3dExtensionState&&) = delete;
    Sps3dExtensionState& operator=(const Sps3dExtensionState&) = delete;
    Sps3dExtensionState& operator=(Sps3dExtensionState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // contents
    std::vector<uint32_t> iv_di_mc_enabled_flag;
    std::vector<uint32_t> iv_mv_scal_enabled_flag;
    uint32_t log2_ivmc_sub_pb_size_minus3 = 0;
    uint32_t iv_res_pred_enabled_flag = 0;
    uint32_t depth_ref_enabled_flag = 0;
    uint32_t vsp_mc_enabled_flag = 0;
    uint32_t dbbp_enabled_flag = 0;
    uint32_t tex_mc_enabled_flag = 0;
    uint32_t log2_texmc_sub_pb_size_minus3 = 0;
    uint32_t intra_contour_enabled_flag = 0;
    uint32_t intra_dc_only_wedge_enabled_flag = 0;
    uint32_t cqt_cu_part_pred_enabled_flag = 0;
    uint32_t inter_dc_only_enabled_flag = 0;
    uint32_t skip_intra_enabled_flag = 0;
  };

  // Unpack RBSP and parse Sps3dExtension state from the supplied
  // buffer.
  static std::unique_ptr<Sps3dExtensionState> ParseSps3dExtension(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<Sps3dExtensionState> ParseSps3dExtension(
      rtc::BitBuffer* bit_buffer) noexcept;
};

}  // namespace h265nal
