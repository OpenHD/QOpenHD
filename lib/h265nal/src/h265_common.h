/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h265nal {

enum NalUnitType : uint8_t {
  TRAIL_N = 0,
  TRAIL_R = 1,
  TSA_N = 2,
  TSA_R = 3,
  STSA_N = 4,
  STSA_R = 5,
  RADL_N = 6,
  RADL_R = 7,
  RASL_N = 8,
  RASL_R = 9,
  RSV_VCL_N10 = 10,
  RSV_VCL_R11 = 11,
  RSV_VCL_N12 = 12,
  RSV_VCL_R13 = 13,
  RSV_VCL_N14 = 14,
  RSV_VCL_R15 = 15,
  BLA_W_LP = 16,
  BLA_W_RADL = 17,
  BLA_N_LP = 18,
  IDR_W_RADL = 19,
  IDR_N_LP = 20,
  CRA_NUT = 21,
  RSV_IRAP_VCL22 = 22,
  RSV_IRAP_VCL23 = 23,
  RSV_VCL24 = 24,
  RSV_VCL25 = 25,
  RSV_VCL26 = 26,
  RSV_VCL27 = 27,
  RSV_VCL28 = 28,
  RSV_VCL29 = 29,
  RSV_VCL30 = 30,
  RSV_VCL31 = 31,
  VPS_NUT = 32,
  SPS_NUT = 33,
  PPS_NUT = 34,
  AUD_NUT = 35,
  EOS_NUT = 36,
  EOB_NUT = 37,
  FD_NUT = 38,
  PREFIX_SEI_NUT = 39,
  SUFFIX_SEI_NUT = 40,
  RSV_NVCL41 = 41,
  RSV_NVCL42 = 42,
  RSV_NVCL43 = 43,
  RSV_NVCL44 = 44,
  RSV_NVCL45 = 45,
  RSV_NVCL46 = 46,
  RSV_NVCL47 = 47,
  // 48-63: unspecified
  AP = 48,
  FU = 49,
  UNSPEC50 = 50,
  UNSPEC51 = 51,
  UNSPEC52 = 52,
  UNSPEC53 = 53,
  UNSPEC54 = 54,
  UNSPEC55 = 55,
  UNSPEC56 = 56,
  UNSPEC57 = 57,
  UNSPEC58 = 58,
  UNSPEC59 = 59,
  UNSPEC60 = 60,
  UNSPEC61 = 61,
  UNSPEC62 = 62,
  UNSPEC63 = 63,
};

namespace h265limits {
// Rec. ITU-T H.265 v5 (02/2018) Page 81
// "The value of num_short_term_ref_pic_sets shall be in the range of
// 0 to 64, inclusive."
const uint32_t NUM_SHORT_TERM_REF_PIC_SETS_MAX = 64;

// Rec. ITU-T H.265 F.7.4.8
// The value of num_positive_pics / num_negative_pics shall be in the range of
// 0 to MaxDpbSize-1, inclusive.
const uint32_t HEVC_MAX_DPB_SIZE = 16;

// Rec. ITU-T H.265 v5 (02/2018) Page 74
// "vps_max_layer_id shall be less than 63 in bitstreams conforming
// to this version of this Specification."
const uint32_t VPS_MAX_LAYER_ID_MAX = 62;

// Rec. ITU-T H.265 v5 (02/2018) Page 74
// "The value of vps_num_layer_sets_minus1 shall be in the range of
// 0 to 1023, inclusive."
const uint32_t VPS_NUM_LAYER_SETS_MINUS1_MAX = 1023;
}  // namespace h265limits

// Slice detector
bool IsSliceSegment(uint32_t nal_unit_type);

bool IsNalUnitTypeVcl(uint32_t nal_unit_type);

bool IsNalUnitTypeNonVcl(uint32_t nal_unit_type);

bool IsNalUnitTypeUnspecified(uint32_t nal_unit_type);

// Methods for parsing RBSP. See section 7.4.1 of the H265 spec.
//
// Decoding is simply a matter of finding any 00 00 03 sequence and removing
// the 03 byte (emulation byte).

// Remove any emulation byte escaping from a buffer. This is needed for
// byte-stream format packetization (e.g. Annex B data), but not for
// packet-stream format packetization (e.g. RTP payloads).
std::vector<uint8_t> UnescapeRbsp(const uint8_t *data, size_t length);

// Syntax functions and descriptors) (Section 7.2)
bool byte_aligned(rtc::BitBuffer *bit_buffer);
int get_current_offset(rtc::BitBuffer *bit_buffer);
bool more_rbsp_data(rtc::BitBuffer *bit_buffer);
bool rbsp_trailing_bits(rtc::BitBuffer *bit_buffer);

#if defined(FDUMP_DEFINE)
// fdump() indentation help
int indent_level_incr(int indent_level);
int indent_level_decr(int indent_level);
void fdump_indent_level(FILE *outfp, int indent_level);
#endif  // FDUMP_DEFINE

class NaluChecksum {
 public:
  static std::shared_ptr<NaluChecksum> GetNaluChecksum(
      rtc::BitBuffer *bit_buffer) noexcept;
  void fdump(char *output, int output_len) const;
  const char *GetChecksum() { return checksum; };
  int GetLength() { return length; };

 private:
  char checksum[32];
  int length;
};

}  // namespace h265nal
