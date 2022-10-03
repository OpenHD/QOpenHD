/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_nal_unit_parser.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

// A class for parsing out an H264 Bitstream.
class H264BitstreamParser {
 public:
  // The parsed state of the bitstream (a list of parsed NAL units plus
  // the accumulated PPS/SPS/SubsetSPS state).
  struct BitstreamState {
    BitstreamState() = default;
    ~BitstreamState() = default;
    // disable copy ctor, move ctor, and copy&move assignments
    BitstreamState(const BitstreamState&) = delete;
    BitstreamState(BitstreamState&&) = delete;
    BitstreamState& operator=(const BitstreamState&) = delete;
    BitstreamState& operator=(BitstreamState&&) = delete;

#ifdef FDUMP_DEFINE
    void fdump(FILE* outfp, int indent_level) const;
#endif  // FDUMP_DEFINE

    bool add_offset;
    bool add_length;
    bool add_parsed_length;
    bool add_checksum;
    // NAL units
    std::vector<std::unique_ptr<struct H264NalUnitParser::NalUnitState>>
        nal_units;
  };

  // Unpack RBSP and parse bitstream state from the supplied buffer.
  static std::unique_ptr<BitstreamState> ParseBitstream(
      const uint8_t* data, size_t length,
      H264BitstreamParserState* bitstream_parser_state,
      bool add_checksum) noexcept;

  // Unpack RBSP and parse bitstream (internal state)
  static std::unique_ptr<BitstreamState> ParseBitstream(
      const uint8_t* data, size_t length, bool add_offset, bool add_length,
      bool add_parsed_length, bool add_checksum) noexcept;

  struct NaluIndex {
    // Start index of NALU, including start sequence.
    size_t start_offset;
    // Start index of NALU payload, typically type header.
    size_t payload_start_offset;
    // Length of NALU payload, in bytes, counting from payload_start_offset.
    size_t payload_size;
  };
  // Returns a vector of the NALU indices in the given buffer.
  static std::vector<NaluIndex> FindNaluIndices(const uint8_t* data,
                                                size_t length) noexcept;
};

}  // namespace h264nal
