/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_hrd_parameters_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"
#include "h265_sub_layer_hrd_parameters_parser.h"

namespace h265nal {

// General note: this is based off the 2016/12 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse hrd_parameters state from the supplied buffer.
std::unique_ptr<H265HrdParametersParser::HrdParametersState>
H265HrdParametersParser::ParseHrdParameters(
    const uint8_t* data, size_t length, uint32_t commonInfPresentFlag,
    uint32_t maxNumSubLayersMinus1) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseHrdParameters(&bit_buffer, commonInfPresentFlag,
                            maxNumSubLayersMinus1);
}

std::unique_ptr<H265HrdParametersParser::HrdParametersState>
H265HrdParametersParser::ParseHrdParameters(
    rtc::BitBuffer* bit_buffer, uint32_t commonInfPresentFlag,
    uint32_t maxNumSubLayersMinus1) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  // H265 hrd_parameters NAL Unit.
  // Section E.2.2 ("HRD parameters syntax") of the H.265
  // standard for a complete description.
  auto hrd_parameters = std::make_unique<HrdParametersState>();

  // input parameters
  hrd_parameters->commonInfPresentFlag = commonInfPresentFlag;
  hrd_parameters->maxNumSubLayersMinus1 = maxNumSubLayersMinus1;

  if (commonInfPresentFlag) {
    // nal_hrd_parameters_present_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(hrd_parameters->nal_hrd_parameters_present_flag), 1)) {
      return nullptr;
    }

    // vcl_hrd_parameters_present_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(hrd_parameters->vcl_hrd_parameters_present_flag), 1)) {
      return nullptr;
    }

    if (hrd_parameters->nal_hrd_parameters_present_flag ||
        hrd_parameters->vcl_hrd_parameters_present_flag) {
      // sub_pic_hrd_params_present_flag  u(1)
      if (!bit_buffer->ReadBits(
              &(hrd_parameters->sub_pic_hrd_params_present_flag), 1)) {
        return nullptr;
      }

      if (hrd_parameters->sub_pic_hrd_params_present_flag) {
        // tick_divisor_minus2  u(8)
        if (!bit_buffer->ReadBits(&(hrd_parameters->tick_divisor_minus2), 8)) {
          return nullptr;
        }

        // du_cpb_removal_delay_increment_length_minus1  u(5)
        if (!bit_buffer->ReadBits(
                &(hrd_parameters->du_cpb_removal_delay_increment_length_minus1),
                5)) {
          return nullptr;
        }

        // sub_pic_cpb_params_in_pic_timing_sei_flag  u(1)
        if (!bit_buffer->ReadBits(
                &(hrd_parameters->sub_pic_cpb_params_in_pic_timing_sei_flag),
                1)) {
          return nullptr;
        }

        // dpb_output_delay_du_length_minus1  u(5)
        if (!bit_buffer->ReadBits(
                &(hrd_parameters->dpb_output_delay_du_length_minus1), 5)) {
          return nullptr;
        }
      }

      // bit_rate_scale  u(4)
      if (!bit_buffer->ReadBits(&(hrd_parameters->bit_rate_scale), 4)) {
        return nullptr;
      }

      // cpb_size_scale  u(4)
      if (!bit_buffer->ReadBits(&(hrd_parameters->cpb_size_scale), 4)) {
        return nullptr;
      }

      if (hrd_parameters->sub_pic_hrd_params_present_flag) {
        // cpb_size_du_scale  u(4)
        if (!bit_buffer->ReadBits(&(hrd_parameters->cpb_size_du_scale), 4)) {
          return nullptr;
        }
      }

      // initial_cpb_removal_delay_length_minus1  u(5)
      if (!bit_buffer->ReadBits(
              &(hrd_parameters->initial_cpb_removal_delay_length_minus1), 5)) {
        return nullptr;
      }

      // au_cpb_removal_delay_length_minus1  u(5)
      if (!bit_buffer->ReadBits(
              &(hrd_parameters->au_cpb_removal_delay_length_minus1), 5)) {
        return nullptr;
      }

      // dpb_output_delay_length_minus1  u(5)
      if (!bit_buffer->ReadBits(
              &(hrd_parameters->dpb_output_delay_length_minus1), 5)) {
        return nullptr;
      }
    }
  }

  for (uint32_t i = 0; i <= maxNumSubLayersMinus1; i++) {
    // fixed_pic_rate_general_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    hrd_parameters->fixed_pic_rate_general_flag.push_back(bits_tmp);

    if (!hrd_parameters->fixed_pic_rate_general_flag[i]) {
      // fixed_pic_rate_within_cvs_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      hrd_parameters->fixed_pic_rate_within_cvs_flag.push_back(bits_tmp);
    } else {
      hrd_parameters->fixed_pic_rate_within_cvs_flag.push_back(0);
    }

    if (hrd_parameters->fixed_pic_rate_within_cvs_flag[i]) {
      // elemental_duration_in_tc_minus1[i]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      hrd_parameters->elemental_duration_in_tc_minus1.push_back(golomb_tmp);

      // need to set low_delay_hrd_flag[i] to 0
      hrd_parameters->low_delay_hrd_flag.push_back(0);
    } else {
      // need to set elemental_duration_in_tc_minus1[i] to 0
      hrd_parameters->elemental_duration_in_tc_minus1.push_back(0);

      // low_delay_hrd_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      hrd_parameters->low_delay_hrd_flag.push_back(bits_tmp);
    }

    if (!hrd_parameters->low_delay_hrd_flag[i]) {
      // cpb_cnt_minus1[i]  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      hrd_parameters->cpb_cnt_minus1.push_back(golomb_tmp);
    } else {
      // need to set cpb_cnt_minus1[i] to 0
      hrd_parameters->cpb_cnt_minus1.push_back(0);
    }

    if (hrd_parameters->nal_hrd_parameters_present_flag) {
      // sub_layer_hrd_parameters(i)
      auto CpbCnt = hrd_parameters->cpb_cnt_minus1[i] + 1;
      auto sub_layer_hrd_parameters =
          H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
              bit_buffer, i, CpbCnt,
              hrd_parameters->sub_pic_hrd_params_present_flag);
      if (sub_layer_hrd_parameters == nullptr) {
        return nullptr;
      }
      hrd_parameters->sub_layer_hrd_parameters_vector.push_back(
          std::move(sub_layer_hrd_parameters));
    }

    if (hrd_parameters->vcl_hrd_parameters_present_flag) {
      // sub_layer_hrd_parameters(i)
      auto CpbCnt = hrd_parameters->cpb_cnt_minus1[i] + 1;
      auto sub_layer_hrd_parameters =
          H265SubLayerHrdParametersParser::ParseSubLayerHrdParameters(
              bit_buffer, i, CpbCnt,
              hrd_parameters->sub_pic_hrd_params_present_flag);
      if (sub_layer_hrd_parameters == nullptr) {
        return nullptr;
      }
      hrd_parameters->sub_layer_hrd_parameters_vector.push_back(
          std::move(sub_layer_hrd_parameters));
    }
  }

  return hrd_parameters;
}

#ifdef FDUMP_DEFINE
void H265HrdParametersParser::HrdParametersState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "hrd_parameters {");
  indent_level = indent_level_incr(indent_level);

  if (commonInfPresentFlag) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "nal_hrd_parameters_present_flag: %i",
            nal_hrd_parameters_present_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "vcl_hrd_parameters_present_flag: %i",
            vcl_hrd_parameters_present_flag);

    if (nal_hrd_parameters_present_flag || vcl_hrd_parameters_present_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "sub_pic_hrd_params_present_flag: %i",
              sub_pic_hrd_params_present_flag);

      if (sub_pic_hrd_params_present_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "tick_divisor_minus2: %i", tick_divisor_minus2);

        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "du_cpb_removal_delay_increment_length_minus1: %i",
                du_cpb_removal_delay_increment_length_minus1);

        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "sub_pic_cpb_params_in_pic_timing_sei_flag: %i",
                sub_pic_cpb_params_in_pic_timing_sei_flag);

        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "dpb_output_delay_du_length_minus1: %i",
                dpb_output_delay_du_length_minus1);
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "bit_rate_scale: %i", bit_rate_scale);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "cpb_size_scale: %i", cpb_size_scale);

      if (sub_pic_hrd_params_present_flag) {
        fdump_indent_level(outfp, indent_level);
        fprintf(outfp, "cpb_size_du_scale: %i", cpb_size_du_scale);
      }

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "initial_cpb_removal_delay_length_minus1: %i",
              initial_cpb_removal_delay_length_minus1);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "au_cpb_removal_delay_length_minus1: %i",
              au_cpb_removal_delay_length_minus1);

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "dpb_output_delay_length_minus1: %i",
              dpb_output_delay_length_minus1);
    }
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "fixed_pic_rate_general_flag {");
  for (const uint32_t& v : fixed_pic_rate_general_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "fixed_pic_rate_within_cvs_flag {");
  for (const uint32_t& v : fixed_pic_rate_within_cvs_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "elemental_duration_in_tc_minus1 {");
  for (const uint32_t& v : elemental_duration_in_tc_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "low_delay_hrd_flag {");
  for (const uint32_t& v : low_delay_hrd_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "cpb_cnt_minus1 {");
  for (const uint32_t& v : cpb_cnt_minus1) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  if (nal_hrd_parameters_present_flag) {
    // sublayer_hrd_parameters()
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sub_layer_hrd_parameters_vector {");
    indent_level = indent_level_incr(indent_level);
    for (auto& v : sub_layer_hrd_parameters_vector) {
      fdump_indent_level(outfp, indent_level);
      v->fdump(outfp, indent_level);
    }
    indent_level = indent_level_decr(indent_level);
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "}");
  }

  if (vcl_hrd_parameters_present_flag) {
    // sublayer_hrd_parameters()
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "sub_layer_hrd_parameters_vector {");
    indent_level = indent_level_incr(indent_level);
    for (auto& v : sub_layer_hrd_parameters_vector) {
      fdump_indent_level(outfp, indent_level);
      v->fdump(outfp, indent_level);
    }
    indent_level = indent_level_decr(indent_level);
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "}");
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
