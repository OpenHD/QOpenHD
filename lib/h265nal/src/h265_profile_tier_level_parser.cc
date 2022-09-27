/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_profile_tier_level_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse PROFILE_TIER_LEVEL state from the supplied buffer.
std::unique_ptr<H265ProfileTierLevelParser::ProfileTierLevelState>
H265ProfileTierLevelParser::ParseProfileTierLevel(
    const uint8_t* data, size_t length, const bool profilePresentFlag,
    const unsigned int maxNumSubLayersMinus1) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseProfileTierLevel(&bit_buffer, profilePresentFlag,
                               maxNumSubLayersMinus1);
}

std::unique_ptr<H265ProfileTierLevelParser::ProfileTierLevelState>
H265ProfileTierLevelParser::ParseProfileTierLevel(
    rtc::BitBuffer* bit_buffer, const bool profilePresentFlag,
    const unsigned int maxNumSubLayersMinus1) noexcept {
  uint32_t bits_tmp;

  // profile_tier_level() parser.
  // Section 7.3.3 ("Profile, tier and level syntax") of the H.265
  // standard for a complete description.
  auto profile_tier_level = std::make_unique<ProfileTierLevelState>();

  // input parameters
  profile_tier_level->profilePresentFlag = profilePresentFlag;
  profile_tier_level->maxNumSubLayersMinus1 = maxNumSubLayersMinus1;

  if (profilePresentFlag) {
    profile_tier_level->general =
        H265ProfileInfoParser::ParseProfileInfo(bit_buffer);
    if (profile_tier_level->general == nullptr) {
      return nullptr;
    }
  }

  // general_level_idc  u(8)
  if (!bit_buffer->ReadBits(&(profile_tier_level->general_level_idc), 8)) {
    return nullptr;
  }

  for (uint32_t i = 0; i < maxNumSubLayersMinus1; i++) {
    // sub_layer_profile_present_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    profile_tier_level->sub_layer_profile_present_flag.push_back(bits_tmp);

    // sub_layer_level_present_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    profile_tier_level->sub_layer_level_present_flag.push_back(bits_tmp);
  }

  if (maxNumSubLayersMinus1 > 0) {
    for (uint32_t i = maxNumSubLayersMinus1; i < 8; i++) {
      // reserved_zero_2bits[i]  u(2)
      if (!bit_buffer->ReadBits(&bits_tmp, 2)) {
        return nullptr;
      }
      profile_tier_level->reserved_zero_2bits.push_back(bits_tmp);
    }
  }

  for (uint32_t i = 0; i < maxNumSubLayersMinus1; i++) {
    if (profile_tier_level->sub_layer_profile_present_flag[i]) {
      profile_tier_level->sub_layer.push_back(
          H265ProfileInfoParser::ParseProfileInfo(bit_buffer));
      if (profile_tier_level->sub_layer.back() == nullptr) {
        return nullptr;
      }
    }

    if (profile_tier_level->sub_layer_profile_present_flag[i]) {
      // sub_layer_level_idc  u(8)
      if (!bit_buffer->ReadBits(&bits_tmp, 8)) {
        return nullptr;
      }
      profile_tier_level->sub_layer_level_idc.push_back(bits_tmp);
    }
  }

  return profile_tier_level;
}

std::unique_ptr<H265ProfileInfoParser::ProfileInfoState>
H265ProfileInfoParser::ParseProfileInfo(const uint8_t* data,
                                        size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseProfileInfo(&bit_buffer);
}

std::unique_ptr<H265ProfileInfoParser::ProfileInfoState>
H265ProfileInfoParser::ParseProfileInfo(rtc::BitBuffer* bit_buffer) noexcept {
  auto profile_info = std::make_unique<ProfileInfoState>();
  uint32_t bits_tmp, bits_tmp_hi;

  // profile_space  u(2)
  if (!bit_buffer->ReadBits(&profile_info->profile_space, 2)) {
    return nullptr;
  }
  // tier_flag  u(1)
  if (!bit_buffer->ReadBits(&profile_info->tier_flag, 1)) {
    return nullptr;
  }
  // profile_idc  u(5)
  if (!bit_buffer->ReadBits(&profile_info->profile_idc, 5)) {
    return nullptr;
  }
  // for (j = 0; j < 32; j++)
  for (uint32_t j = 0; j < 32; j++) {
    // profile_compatibility_flag[j]  u(1)
    if (!bit_buffer->ReadBits(&profile_info->profile_compatibility_flag[j],
                              1)) {
      return nullptr;
    }
  }
  // progressive_source_flag  u(1)
  if (!bit_buffer->ReadBits(&profile_info->progressive_source_flag, 1)) {
    return nullptr;
  }
  // interlaced_source_flag  u(1)
  if (!bit_buffer->ReadBits(&profile_info->interlaced_source_flag, 1)) {
    return nullptr;
  }
  // non_packed_constraint_flag  u(1)
  if (!bit_buffer->ReadBits(&profile_info->non_packed_constraint_flag, 1)) {
    return nullptr;
  }
  // frame_only_constraint_flag  u(1)
  if (!bit_buffer->ReadBits(&profile_info->frame_only_constraint_flag, 1)) {
    return nullptr;
  }
  if (profile_info->profile_idc == 4 ||
      profile_info->profile_compatibility_flag[4] == 1 ||
      profile_info->profile_idc == 5 ||
      profile_info->profile_compatibility_flag[5] == 1 ||
      profile_info->profile_idc == 6 ||
      profile_info->profile_compatibility_flag[6] == 1 ||
      profile_info->profile_idc == 7 ||
      profile_info->profile_compatibility_flag[7] == 1 ||
      profile_info->profile_idc == 8 ||
      profile_info->profile_compatibility_flag[8] == 1 ||
      profile_info->profile_idc == 9 ||
      profile_info->profile_compatibility_flag[9] == 1 ||
      profile_info->profile_idc == 10 ||
      profile_info->profile_compatibility_flag[10] == 1) {
    // The number of bits in this syntax structure is not affected by
    // this condition
    // max_12bit_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_12bit_constraint_flag, 1)) {
      return nullptr;
    }
    // max_10bit_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_10bit_constraint_flag, 1)) {
      return nullptr;
    }
    // max_8bit_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_8bit_constraint_flag, 1)) {
      return nullptr;
    }
    // max_422chroma_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_422chroma_constraint_flag,
                              1)) {
      return nullptr;
    }
    // max_420chroma_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_420chroma_constraint_flag,
                              1)) {
      return nullptr;
    }
    // max_monochrome_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->max_monochrome_constraint_flag,
                              1)) {
      return nullptr;
    }
    // intra_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->intra_constraint_flag, 1)) {
      return nullptr;
    }
    // one_picture_only_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->one_picture_only_constraint_flag,
                              1)) {
      return nullptr;
    }
    // lower_bit_rate_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->lower_bit_rate_constraint_flag,
                              1)) {
      return nullptr;
    }
    if (profile_info->profile_idc == 5 ||
        profile_info->profile_compatibility_flag[5] == 1 ||
        profile_info->profile_idc == 9 ||
        profile_info->profile_compatibility_flag[9] == 1 ||
        profile_info->profile_idc == 10 ||
        profile_info->profile_compatibility_flag[10] == 1) {
      // max_14bit_constraint_flag  u(1)
      if (!bit_buffer->ReadBits(&profile_info->max_14bit_constraint_flag, 1)) {
        return nullptr;
      }
      // reserved_zero_33bits  u(33)
      if (!bit_buffer->ReadBits(&bits_tmp_hi, 1)) {
        return nullptr;
      }
      if (!bit_buffer->ReadBits(&bits_tmp, 32)) {
        return nullptr;
      }
      profile_info->reserved_zero_33bits =
          ((uint64_t)bits_tmp_hi << 32) | bits_tmp;
    } else {
      // reserved_zero_34bits  u(34)
      if (!bit_buffer->ReadBits(&bits_tmp_hi, 2)) {
        return nullptr;
      }
      if (!bit_buffer->ReadBits(&bits_tmp, 32)) {
        return nullptr;
      }
      profile_info->reserved_zero_34bits =
          ((uint64_t)bits_tmp_hi << 32) | bits_tmp;
    }
  } else if (profile_info->profile_idc == 2 ||
             profile_info->profile_compatibility_flag[2] == 1) {
    // reserved_zero_7bits  u(7)
    if (!bit_buffer->ReadBits(&profile_info->reserved_zero_7bits, 7)) {
      return nullptr;
    }
    // one_picture_only_constraint_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->one_picture_only_constraint_flag,
                              1)) {
      return nullptr;
    }
    // reserved_zero_35bits  u(35)
    if (!bit_buffer->ReadBits(&bits_tmp_hi, 3)) {
      return nullptr;
    }
    if (!bit_buffer->ReadBits(&bits_tmp, 32)) {
      return nullptr;
    }
    profile_info->reserved_zero_35bits =
        ((uint64_t)bits_tmp_hi << 32) | bits_tmp;
  } else {
    // reserved_zero_43bits  u(43)
    if (!bit_buffer->ReadBits(&bits_tmp_hi, 11)) {
      return nullptr;
    }
    if (!bit_buffer->ReadBits(&bits_tmp, 32)) {
      return nullptr;
    }
    profile_info->reserved_zero_43bits =
        ((uint64_t)bits_tmp_hi << 32) | bits_tmp;
  }
  // The number of bits in this syntax structure is not affected by
  // this condition
  if ((profile_info->profile_idc >= 1 && profile_info->profile_idc <= 5) ||
      profile_info->profile_idc == 9 ||
      profile_info->profile_compatibility_flag[1] == 1 ||
      profile_info->profile_compatibility_flag[2] == 1 ||
      profile_info->profile_compatibility_flag[3] == 1 ||
      profile_info->profile_compatibility_flag[4] == 1 ||
      profile_info->profile_compatibility_flag[5] == 1 ||
      profile_info->profile_compatibility_flag[9] == 1) {
    // inbld_flag  u(1)
    if (!bit_buffer->ReadBits(&profile_info->inbld_flag, 1)) {
      return nullptr;
    }
  } else {
    // reserved_zero_bit  u(1)
    if (!bit_buffer->ReadBits(&profile_info->reserved_zero_bit, 1)) {
      return nullptr;
    }
  }

  return profile_info;
}

#ifdef FDUMP_DEFINE
void H265ProfileInfoParser::ProfileInfoState::fdump(FILE* outfp,
                                                    int indent_level) const {
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "profile_space: %i", profile_space);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "tier_flag: %i", tier_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "profile_idc: %i", profile_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "profile_compatibility_flag {");
  for (const uint32_t& v : profile_compatibility_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "progressive_source_flag: %i", progressive_source_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "interlaced_source_flag: %i", interlaced_source_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "non_packed_constraint_flag: %i", non_packed_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "frame_only_constraint_flag: %i", frame_only_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_12bit_constraint_flag: %i", max_12bit_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_10bit_constraint_flag: %i", max_10bit_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_8bit_constraint_flag: %i", max_8bit_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_422chroma_constraint_flag: %i",
          max_422chroma_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_420chroma_constraint_flag: %i",
          max_420chroma_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_monochrome_constraint_flag: %i",
          max_monochrome_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "intra_constraint_flag: %i", intra_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "one_picture_only_constraint_flag: %i",
          one_picture_only_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "lower_bit_rate_constraint_flag: %i",
          lower_bit_rate_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "max_14bit_constraint_flag: %i", max_14bit_constraint_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_33bits: %" PRIu64 "", reserved_zero_33bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_34bits: %" PRIu64 "", reserved_zero_34bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_7bits: %" PRIu32 "", reserved_zero_7bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_35bits: %" PRIu64 "", reserved_zero_35bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_43bits: %" PRIu64 "", reserved_zero_43bits);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "inbld_flag: %i", inbld_flag);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "reserved_zero_bit: %i", reserved_zero_bit);
}

void H265ProfileTierLevelParser::ProfileTierLevelState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "profile_tier_level {");
  indent_level = indent_level_incr(indent_level);

  if (profilePresentFlag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "general {");
    indent_level = indent_level_incr(indent_level);

    general->fdump(outfp, indent_level);

    indent_level = indent_level_decr(indent_level);
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "}");
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "general_level_idc: %i", general_level_idc);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sub_layer_profile_present_flag {");
  for (const uint32_t& v : sub_layer_profile_present_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "sub_layer_level_present_flag {");
  for (const uint32_t& v : sub_layer_level_present_flag) {
    fprintf(outfp, " %i ", v);
  }
  fprintf(outfp, " }");

  if (maxNumSubLayersMinus1 > 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "reserved_zero_2bits {");
    for (const uint32_t& v : reserved_zero_2bits) {
      fprintf(outfp, " %i ", v);
    }
    fprintf(outfp, " }");
  }

  if (maxNumSubLayersMinus1 > 0) {
    for (auto& v : sub_layer) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sub_layer {");
      indent_level = indent_level_incr(indent_level);

      v->fdump(outfp, indent_level);

      indent_level = indent_level_decr(indent_level);
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "}");
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sub_layer_level_idc {");
    for (const uint32_t& v : sub_layer_level_idc) {
      fprintf(outfp, " %i ", v);
    }
    fprintf(outfp, " }");
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
