/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_hrd_parameters_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse hrd_parameters state from the supplied buffer.
std::unique_ptr<H264HrdParametersParser::HrdParametersState>
H264HrdParametersParser::ParseHrdParameters(const uint8_t* data,
                                            size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseHrdParameters(&bit_buffer);
}

std::unique_ptr<H264HrdParametersParser::HrdParametersState>
H264HrdParametersParser::ParseHrdParameters(
    rtc::BitBuffer* bit_buffer) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H264 hrd_parameters() NAL Unit.
  // Section E.1.2. ("HRD parameters syntax") of the
  // H.264 standard for a complete description.
  auto hrd_parameters = std::make_unique<HrdParametersState>();

  // cpb_cnt_minus1[i]  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(&(hrd_parameters->cpb_cnt_minus1))) {
    return nullptr;
  }

  // bit_rate_scale  u(4)
  if (!bit_buffer->ReadBits(&(hrd_parameters->bit_rate_scale), 4)) {
    return nullptr;
  }

  // cpb_size_scale  u(4)
  if (!bit_buffer->ReadBits(&(hrd_parameters->cpb_size_scale), 4)) {
    return nullptr;
  }

  for (uint32_t SchedSelIdx = 0; SchedSelIdx <= hrd_parameters->cpb_cnt_minus1;
       SchedSelIdx++) {
    // bit_rate_value_minus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    hrd_parameters->bit_rate_value_minus1.push_back(golomb_tmp);

    // cpb_size_value_minus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    hrd_parameters->cpb_size_value_minus1.push_back(golomb_tmp);

    // cbr_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    hrd_parameters->cbr_flag.push_back(bits_tmp);
  }

  // initial_cpb_removal_delay_length_minus1  u(5)
  if (!bit_buffer->ReadBits(
          &(hrd_parameters->initial_cpb_removal_delay_length_minus1), 5)) {
    return nullptr;
  }

  // cpb_removal_delay_length_minus1  u(5)
  if (!bit_buffer->ReadBits(&(hrd_parameters->cpb_removal_delay_length_minus1),
                            5)) {
    return nullptr;
  }

  // dpb_output_delay_length_minus1  u(5)
  if (!bit_buffer->ReadBits(&(hrd_parameters->dpb_output_delay_length_minus1),
                            5)) {
    return nullptr;
  }

  // time_offset_length  u(5)
  if (!bit_buffer->ReadBits(&(hrd_parameters->time_offset_length), 5)) {
    return nullptr;
  }

  return hrd_parameters;
}

#ifdef FDUMP_DEFINE
void H264HrdParametersParser::HrdParametersState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "hrd_parameters {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cpb_cnt_minus1: %i", cpb_cnt_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bit_rate_scale: %i", bit_rate_scale);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bit_rate_value_minus1 {");
  for (const uint32_t& v : bit_rate_value_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cpb_size_value_minus1 {");
  for (const uint32_t& v : cpb_size_value_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cbr_flag {");
  for (const uint32_t& v : cbr_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "initial_cpb_removal_delay_length_minus1: %i",
          initial_cpb_removal_delay_length_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cpb_removal_delay_length_minus1: %i",
          cpb_removal_delay_length_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "dpb_output_delay_length_minus1: %i",
          dpb_output_delay_length_minus1);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "time_offset_length: %i", time_offset_length);

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
