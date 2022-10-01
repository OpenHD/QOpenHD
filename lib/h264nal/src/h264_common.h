/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "rtc_base/bit_buffer.h"

namespace h264nal {

// Table 7-1 of the 2012 standard.
enum NalUnitType : uint8_t {
  UNSPECIFIED_NUT = 0,
  CODED_SLICE_OF_NON_IDR_PICTURE_NUT = 1,
  CODED_SLICE_DATA_PARTITION_A_NUT = 2,
  CODED_SLICE_DATA_PARTITION_B_NUT = 3,
  CODED_SLICE_DATA_PARTITION_C_NUT = 4,
  CODED_SLICE_OF_IDR_PICTURE_NUT = 5,
  SEI_NUT = 6,
  SPS_NUT = 7,
  PPS_NUT = 8,
  AUD_NUT = 9,
  EOSEQ_NUT = 10,
  EOSTREAM_NUT = 11,
  FILLER_DATA_NUT = 12,
  SPS_EXTENSION_NUT = 13,
  PREFIX_NUT = 14,
  SUBSET_SPS_NUT = 15,
  // 16-18: reserved
  RSV16_NUT = 16,
  RSV17_NUT = 17,
  RSV18_NUT = 18,
  CODED_SLICE_OF_AUXILIARY_CODED_PICTURE_NUT = 19,
  CODED_SLICE_EXTENSION = 20,
  // 21-23: reserved
  RSV21_NUT = 21,
  RSV22_NUT = 22,
  RSV23_NUT = 23,
  // 24-29: RTP
  RTP_STAPA_NUT = 24,
  RTP_FUA_NUT = 28,
  // 24-31: unspecified
  UNSPEC24_NUT = 24,
  UNSPEC25_NUT = 25,
  UNSPEC26_NUT = 26,
  UNSPEC27_NUT = 27,
  UNSPEC28_NUT = 28,
  UNSPEC29_NUT = 29,
  UNSPEC30_NUT = 30,
  UNSPEC31_NUT = 31,
};

bool IsNalUnitTypeReserved(uint32_t nal_unit_type);
bool IsNalUnitTypeUnspecified(uint32_t nal_unit_type);

// Table 7-3
enum SliceType : uint8_t {
  P = 0,
  B = 1,
  I = 2,
  SP = 3,
  SI = 4,
  // slice_type values in the range 5..9 specify, in addition to the coding
  // type of the current slice, that all other slices of the current coded
  // picture shall have a value of slice_type equal to the current value of
  // slice_type or equal to the current value of slice_type - 5.
  P_ALL = 5,
  B_ALL = 6,
  I_ALL = 7,
  SP_ALL = 8,
  SI_ALL = 9,
};

// Table G-1
enum SvcSliceType : uint8_t {
  EPa = 0,
  EBa = 1,
  EIa = 2,
  EPb = 5,
  EBb = 6,
  EIb = 7,
};

// Methods for parsing RBSP. See section 7.4 of the H264 spec.
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

}  // namespace h264nal
