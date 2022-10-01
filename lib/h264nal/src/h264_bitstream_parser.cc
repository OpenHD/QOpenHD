/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_bitstream_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_nal_unit_parser.h"

namespace {
// The size of a full NALU start sequence {0 0 0 1}, used for the first NALU
// of an access unit, and for SPS, PPS, and SubsetSPS blocks.
// const size_t kNaluLongStartSequenceSize = 4;
// The size of a shortened NALU start sequence {0 0 1}, that may be used if
// not the first NALU of an access unit or an SPS, PPS, or SubsetSPS block.
const size_t kNaluShortStartSequenceSize = 3;
}  // namespace

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

std::vector<H264BitstreamParser::NaluIndex>
H264BitstreamParser::FindNaluIndices(const uint8_t* data,
                                     size_t length) noexcept {
  // This is sorta like Boyer-Moore, but with only the first optimization step:
  // given a 3-byte sequence we're looking at, if the 3rd byte isn't 1 or 0,
  // skip ahead to the next 3-byte sequence. 0s and 1s are relatively rare, so
  // this will skip the majority of reads/checks.
  std::vector<NaluIndex> sequences;
  if (length < kNaluShortStartSequenceSize) {
    return sequences;
  }

  const size_t end = length - kNaluShortStartSequenceSize;
  for (size_t i = 0; i < end;) {
    if (data[i + 2] > 1) {
      i += 3;
    } else if (data[i + 2] == 0x01 && data[i + 1] == 0x00 && data[i] == 0x00) {
      // We found a start sequence, now check if it was a 3 of 4 byte one.
      NaluIndex index = {i, i + 3, 0};
      if (index.start_offset > 0 && data[index.start_offset - 1] == 0)
        --index.start_offset;

      // Update length of previous entry.
      auto it = sequences.rbegin();
      if (it != sequences.rend())
        it->payload_size = index.start_offset - it->payload_start_offset;

      sequences.push_back(index);

      i += 3;
    } else {
      ++i;
    }
  }

  // Update length of last entry, if any.
  auto it = sequences.rbegin();
  if (it != sequences.rend())
    it->payload_size = length - it->payload_start_offset;

  return sequences;
}

// Parse a raw (RBSP) buffer with explicit NAL unit separator (3- or 4-byte
// sequence start code prefix). Function splits the stream in NAL units,
// and then parses each NAL unit. For that, it unpacks the RBSP inside
// each NAL unit buffer, and adds the corresponding parsed struct into
// the `bitstream` list (a `BitstreamState` object).
// Function returns the said `bitstream` list.
std::unique_ptr<H264BitstreamParser::BitstreamState>
H264BitstreamParser::ParseBitstream(
    const uint8_t* data, size_t length,
    H264BitstreamParserState* bitstream_parser_state,
    bool add_checksum) noexcept {
  auto bitstream = std::make_unique<BitstreamState>();

  // (1) split the input string into a vector of NAL units
  std::vector<NaluIndex> nalu_indices = FindNaluIndices(data, length);

  // process each of the NAL units
  for (const NaluIndex& nalu_index : nalu_indices) {
    // (2) parse the NAL units, and add them to the vector
    auto nal_unit = H264NalUnitParser::ParseNalUnit(
        &data[nalu_index.payload_start_offset], nalu_index.payload_size,
        bitstream_parser_state, add_checksum);
    if (nal_unit == nullptr) {
      // cannot parse the NalUnit
#ifdef FPRINT_ERRORS
      fprintf(stderr, "error: cannot parse buffer into NalUnit\n");
#endif  // FPRINT_ERRORS
      continue;
    }
    // store the offset
    nal_unit->offset = nalu_index.payload_start_offset;
    nal_unit->length = nalu_index.payload_size;

    bitstream->nal_units.push_back(std::move(nal_unit));
  }

  return bitstream;
}

std::unique_ptr<H264BitstreamParser::BitstreamState>
H264BitstreamParser::ParseBitstream(const uint8_t* data, size_t length,
                                    bool add_offset, bool add_length,
                                    bool add_parsed_length,
                                    bool add_checksum) noexcept {
  // keep a bitstream parser state (to keep the SPS/PPS/SubsetSPS NALUs)
  H264BitstreamParserState bitstream_parser_state;

  // create bitstream parser state
  auto bitstream = std::make_unique<BitstreamState>();

  // parse the file
  bitstream =
      ParseBitstream(data, length, &bitstream_parser_state, add_checksum);
  if (bitstream == nullptr) {
    // did not work
#ifdef FPRINT_ERRORS
    fprintf(stderr, "Could not init h264 bitstream parser\n");
#endif  // FPRINT_ERRORS
    return nullptr;
  }
  bitstream->add_offset = add_offset;
  bitstream->add_length = add_length;
  bitstream->add_parsed_length = add_parsed_length;
  bitstream->add_checksum = add_checksum;
  return bitstream;
}

#ifdef FDUMP_DEFINE
void H264BitstreamParser::BitstreamState::fdump(FILE* outfp,
                                                int indent_level) const {
  for (auto& nal_unit : nal_units) {
    nal_unit->fdump(outfp, indent_level, add_offset, add_length,
                    add_parsed_length, add_checksum);
    fprintf(outfp, "\n");
  }
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
