/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <array>
#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

// Parse profile info state from the supplied buffer.
// A class for parsing out a piece of a profile_tier_level from an H265 NALU.
class H265ProfileInfoParser {
 public:
  // The parsed state of each layer (including general) in the
  // profile_tier_level.
  // Only some select values are stored. Add more as they are actually needed.
  struct ProfileInfoState {
    ProfileInfoState() = default;
    ~ProfileInfoState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    ProfileInfoState(const ProfileInfoState&) = delete;
    ProfileInfoState(ProfileInfoState&&) = delete;
    ProfileInfoState& operator=(const ProfileInfoState&) = delete;
    ProfileInfoState& operator=(ProfileInfoState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    uint32_t profile_space = 0;
    uint32_t tier_flag = 0;
    uint32_t profile_idc = 0;
    std::array<uint32_t, 32> profile_compatibility_flag;
    uint32_t progressive_source_flag = 0;
    uint32_t interlaced_source_flag = 0;
    uint32_t non_packed_constraint_flag = 0;
    uint32_t frame_only_constraint_flag = 0;
    uint32_t max_12bit_constraint_flag = 0;
    uint32_t max_10bit_constraint_flag = 0;
    uint32_t max_8bit_constraint_flag = 0;
    uint32_t max_422chroma_constraint_flag = 0;
    uint32_t max_420chroma_constraint_flag = 0;
    uint32_t max_monochrome_constraint_flag = 0;
    uint32_t intra_constraint_flag = 0;
    uint32_t one_picture_only_constraint_flag = 0;
    uint32_t lower_bit_rate_constraint_flag = 0;
    uint32_t max_14bit_constraint_flag = 0;
    uint64_t reserved_zero_33bits = 0;
    uint64_t reserved_zero_34bits = 0;
    uint32_t reserved_zero_7bits = 0;
    uint64_t reserved_zero_35bits = 0;
    uint64_t reserved_zero_43bits = 0;
    uint32_t inbld_flag = 0;
    uint32_t reserved_zero_bit = 0;
  };

  // Unpack RBSP and parse profile_tier_level state from the supplied buffer.
  static std::unique_ptr<ProfileInfoState> ParseProfileInfo(
      const uint8_t* data, size_t length) noexcept;
  static std::unique_ptr<ProfileInfoState> ParseProfileInfo(
      rtc::BitBuffer* bit_buffer) noexcept;
};

// A class for parsing out a video sequence parameter set (profile_tier_level)
// data from an H265 NALU.
class H265ProfileTierLevelParser {
 public:
  // The parsed state of the profile_tier_level. Only some select values are
  // stored.
  // Add more as they are actually needed.
  struct ProfileTierLevelState {
    ProfileTierLevelState() = default;
    ~ProfileTierLevelState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    ProfileTierLevelState(const ProfileTierLevelState&) = delete;
    ProfileTierLevelState(ProfileTierLevelState&&) = delete;
    ProfileTierLevelState& operator=(const ProfileTierLevelState&) = delete;
    ProfileTierLevelState& operator=(ProfileTierLevelState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    // input parameters
    bool profilePresentFlag;
    unsigned int maxNumSubLayersMinus1;

    // contents
    std::unique_ptr<struct H265ProfileInfoParser::ProfileInfoState> general;
    uint32_t general_level_idc = 0;
    std::vector<uint32_t> sub_layer_profile_present_flag;
    std::vector<uint32_t> sub_layer_level_present_flag;
    std::vector<uint32_t> reserved_zero_2bits;
    std::vector<std::unique_ptr<struct H265ProfileInfoParser::ProfileInfoState>>
        sub_layer;
    std::vector<uint32_t> sub_layer_level_idc;
  };

  // Unpack RBSP and parse profile_tier_level state from the supplied buffer.
  static std::unique_ptr<ProfileTierLevelState> ParseProfileTierLevel(
      const uint8_t* data, size_t length, const bool profilePresentFlag,
      const unsigned int maxNumSubLayersMinus1) noexcept;
  static std::unique_ptr<ProfileTierLevelState> ParseProfileTierLevel(
      rtc::BitBuffer* bit_buffer, const bool profilePresentFlag,
      const unsigned int maxNumSubLayersMinus1) noexcept;
};

}  // namespace h265nal
