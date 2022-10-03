/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h264nal {

// Classes for parsing out a video sequence parameter set (SPS) data from
// an H264 NALU.

// prefix_nal_unit_svc()
class H264PrefixNalUnitSvcParser {
 public:
  // Only some select values are stored.
  // Add more as they are actually needed.
  struct PrefixNalUnitSvcState {
    PrefixNalUnitSvcState() = default;
    ~PrefixNalUnitSvcState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    PrefixNalUnitSvcState(const PrefixNalUnitSvcState&) = delete;
    PrefixNalUnitSvcState(PrefixNalUnitSvcState&&) = delete;
    PrefixNalUnitSvcState& operator=(const PrefixNalUnitSvcState&) = delete;
    PrefixNalUnitSvcState& operator=(PrefixNalUnitSvcState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t nal_ref_idc = 0;
    uint32_t use_ref_base_pic_flag = 0;
    uint32_t idr_flag = 0;

    // contents
    uint32_t store_ref_base_pic_flag = 0;
    // TODO(chemag): dec_ref_base_pic_marking()
    uint32_t additional_prefix_nal_unit_extension_flag = 0;
    uint32_t additional_prefix_nal_unit_extension_data_flag = 0;
  };

  // Unpack RBSP and parse prefix_nal_unit_svc() state from the supplied buffer.
  static std::unique_ptr<PrefixNalUnitSvcState> ParsePrefixNalUnitSvc(
      const uint8_t* data, size_t length, uint32_t nal_ref_idc,
      uint32_t use_ref_base_pic_flag, uint32_t idr_flag) noexcept;
  static std::unique_ptr<PrefixNalUnitSvcState> ParsePrefixNalUnitSvc(
      rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc,
      uint32_t use_ref_base_pic_flag, uint32_t idr_flag) noexcept;
};

// prefix_nal_unit_rbsp()
class H264PrefixNalUnitRbspParser {
 public:
  // Only some select values are stored.
  // Add more as they are actually needed.
  struct PrefixNalUnitRbspState {
    PrefixNalUnitRbspState() = default;
    ~PrefixNalUnitRbspState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    PrefixNalUnitRbspState(const PrefixNalUnitRbspState&) = delete;
    PrefixNalUnitRbspState(PrefixNalUnitRbspState&&) = delete;
    PrefixNalUnitRbspState& operator=(const PrefixNalUnitRbspState&) = delete;
    PrefixNalUnitRbspState& operator=(PrefixNalUnitRbspState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    uint32_t svc_extension_flag = 0;
    uint32_t nal_ref_idc = 0;
    uint32_t use_ref_base_pic_flag = 0;
    uint32_t idr_flag = 0;

    // contents
    std::unique_ptr<struct H264PrefixNalUnitSvcParser::PrefixNalUnitSvcState>
        prefix_nal_unit_svc;
  };

  // Unpack RBSP and parse prefix_nal_unit_rbsp() state from the supplied
  // buffer.
  static std::unique_ptr<PrefixNalUnitRbspState> ParsePrefixNalUnitRbsp(
      const uint8_t* data, size_t length, uint32_t svc_extension_flag,
      uint32_t nal_ref_idc, uint32_t use_ref_base_pic_flag,
      uint32_t idr_flag) noexcept;
  static std::unique_ptr<PrefixNalUnitRbspState> ParsePrefixNalUnitRbsp(
      rtc::BitBuffer* bit_buffer, uint32_t svc_extension_flag,
      uint32_t nal_ref_idc, uint32_t use_ref_base_pic_flag,
      uint32_t idr_flag) noexcept;
};

}  // namespace h264nal
