/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#pragma once

#include <stdio.h>

#include <map>
#include <memory>

#include "h264_pps_parser.h"
#include "h264_sps_parser.h"
#include "h264_subset_sps_parser.h"

namespace h264nal {

// A class for keeping the state of a H264 Bitstream.
// The parsed state of the bitstream.
struct H264BitstreamParserState {
  H264BitstreamParserState() = default;
  ~H264BitstreamParserState() = default;
  // disable copy ctor, move ctor, and copy&move assignments
  H264BitstreamParserState(const H264BitstreamParserState&) = delete;
  H264BitstreamParserState(H264BitstreamParserState&&) = delete;
  H264BitstreamParserState& operator=(const H264BitstreamParserState&) = delete;
  H264BitstreamParserState& operator=(H264BitstreamParserState&&) = delete;

  // SPS state
  std::map<uint32_t, std::shared_ptr<struct H264SpsParser::SpsState>> sps;
  // PPS state
  std::map<uint32_t, std::shared_ptr<struct H264PpsParser::PpsState>> pps;
  // SubsetSPS state
  std::map<uint32_t,
           std::shared_ptr<struct H264SubsetSpsParser::SubsetSpsState>>
      subset_sps;

  // some accessors
  std::shared_ptr<struct H264SpsParser::SpsState> GetSps(uint32_t sps_id) const;
  std::shared_ptr<struct H264PpsParser::PpsState> GetPps(uint32_t pps_id) const;
  std::shared_ptr<struct H264SubsetSpsParser::SubsetSpsState> GetSubsetSps(
      uint32_t subset_sps_id) const;
};

}  // namespace h264nal
