/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_sub_layer_hrd_parameters_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse sub_layer_hrd_parameters state from the supplied
// buffer.
std::unique_ptr<H265SubLayerHrdParametersParser::SubLayerHrdParametersState>
H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
    const uint8_t* data, size_t length, uint32_t subLayerId, uint32_t CpbCnt,
    uint32_t sub_pic_hrd_params_present_flag) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSubLayerHrdParameters(&bit_buffer, subLayerId, CpbCnt,
                                    sub_pic_hrd_params_present_flag);
}

std::unique_ptr<H265SubLayerHrdParametersParser::SubLayerHrdParametersState>
H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
    rtc::BitBuffer* bit_buffer, uint32_t subLayerId, uint32_t CpbCnt,
    uint32_t sub_pic_hrd_params_present_flag) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H265 sub_layer_hrd_parameters NAL Unit.
  // Section E.2.3 ("Sub-layer HRD parameters syntax") of the H.265
  // standard for a complete description.
  auto sub_layer_hrd_parameters =
      std::make_unique<SubLayerHrdParametersState>();

  // input parameters
  sub_layer_hrd_parameters->subLayerId = subLayerId;
  sub_layer_hrd_parameters->CpbCnt = CpbCnt;
  sub_layer_hrd_parameters->sub_pic_hrd_params_present_flag =
      sub_pic_hrd_params_present_flag;

  for (uint32_t i = 0; i < CpbCnt; i++) {
    // bit_rate_value_minus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    sub_layer_hrd_parameters->bit_rate_value_minus1.push_back(golomb_tmp);

    // cpb_size_value_minus1[i]  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
      return nullptr;
    }
    sub_layer_hrd_parameters->cpb_size_value_minus1.push_back(golomb_tmp);

    if (sub_pic_hrd_params_present_flag) {
      // cpb_size_du_value_minus1[i]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      sub_layer_hrd_parameters->cpb_size_du_value_minus1.push_back(golomb_tmp);

      // bit_rate_du_value_minus1[i]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      sub_layer_hrd_parameters->bit_rate_du_value_minus1.push_back(golomb_tmp);
    } else {
      sub_layer_hrd_parameters->cpb_size_du_value_minus1.push_back(0);
      sub_layer_hrd_parameters->bit_rate_du_value_minus1.push_back(0);
    }

    // cbr_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    sub_layer_hrd_parameters->cbr_flag.push_back(bits_tmp);
  }

  return sub_layer_hrd_parameters;
}

#ifdef FDUMP_DEFINE
void H265SubLayerHrdParametersParser::SubLayerHrdParametersState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "sub_layer_hrd_parameters {");
  indent_level = indent_level_incr(indent_level);

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
  fprintf(outfp, "cpb_size_du_value_minus1 {");
  for (const uint32_t& v : cpb_size_du_value_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "bit_rate_du_value_minus1 {");
  for (const uint32_t& v : bit_rate_du_value_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cbr_flag {");
  for (const uint32_t& v : cbr_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
