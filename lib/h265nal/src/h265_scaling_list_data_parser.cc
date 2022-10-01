/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_scaling_list_data_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <algorithm>
#include <cstdint>
#include <memory>
#include <vector>

#include "h265_common.h"

namespace h265nal {

// General note: this is based off the 2018/02 version of the H.265 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.265

// Unpack RBSP and parse scaling_list_data state from the supplied buffer.
std::unique_ptr<H265ScalingListDataParser::ScalingListDataState>
H265ScalingListDataParser::ParseScalingListData(const uint8_t* data,
                                                size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseScalingListData(&bit_buffer);
}

std::unique_ptr<H265ScalingListDataParser::ScalingListDataState>
H265ScalingListDataParser::ParseScalingListData(
    rtc::BitBuffer* bit_buffer) noexcept {
  // H265 scaling_list_data() NAL Unit.
  // Section 7.3.4 ("Scaling list data syntax") of the H.265
  // standard for a complete description.
  auto scaling_list_data = std::make_unique<ScalingListDataState>();

  // allocate the external vectors
  for (uint32_t sizeId = 0; sizeId < 4; sizeId++) {
    scaling_list_data->scaling_list_pred_mode_flag.emplace_back();
    scaling_list_data->scaling_list_pred_matrix_id_delta.emplace_back();
    scaling_list_data->scaling_list_dc_coef_minus8.emplace_back();
    scaling_list_data->ScalingList.emplace_back();
    for (uint32_t matrixId = 0; matrixId < 6; matrixId += 1) {
      scaling_list_data->scaling_list_pred_mode_flag[sizeId].emplace_back(0);
      scaling_list_data->scaling_list_pred_matrix_id_delta[sizeId].emplace_back(
          0);
      scaling_list_data->scaling_list_dc_coef_minus8[sizeId].emplace_back(0);
      scaling_list_data->ScalingList[sizeId].emplace_back();
    }
  }

  // calculate the values
  for (uint32_t sizeId = 0; sizeId < 4; sizeId++) {
    for (uint32_t matrixId = 0; matrixId < 6;
         matrixId += (sizeId == 3) ? 3 : 1) {
      // scaling_list_pred_mode_flag[sizeId][matrixId]  u(1)
      if (!bit_buffer->ReadBits(
              &scaling_list_data->scaling_list_pred_mode_flag[sizeId][matrixId],
              1)) {
        return nullptr;
      }

      if (!scaling_list_data->scaling_list_pred_mode_flag[sizeId][matrixId]) {
        // scaling_list_pred_matrix_id_delta[sizeId][matrixId]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(
                &scaling_list_data
                     ->scaling_list_pred_matrix_id_delta[sizeId][matrixId])) {
          return nullptr;
        }

      } else {
        uint32_t nextCoef = 8;
        uint32_t coefNum = std::min(64, (1 << (4 + (sizeId << 1))));
        if (sizeId > 1) {
          // scaling_list_dc_coef_minus8[sizeId - 2][matrixId]  se(v)
          if (!bit_buffer->ReadSignedExponentialGolomb(
                  &scaling_list_data
                       ->scaling_list_dc_coef_minus8[sizeId - 2][matrixId])) {
            return nullptr;
          }
          nextCoef = scaling_list_data
                         ->scaling_list_dc_coef_minus8[sizeId - 2][matrixId] +
                     8;
        }
        for (uint32_t i = 0; i < coefNum; i++) {
          // scaling_list_delta_coef  se(v)
          int32_t scaling_list_delta_coef;
          if (!bit_buffer->ReadSignedExponentialGolomb(
                  &scaling_list_delta_coef)) {
            return nullptr;
          }
          nextCoef = (nextCoef + scaling_list_delta_coef + 256) % 256;
          scaling_list_data->ScalingList[sizeId][matrixId].push_back(nextCoef);
        }
      }
    }
  }

  return scaling_list_data;
}

#ifdef FDUMP_DEFINE
void H265ScalingListDataParser::ScalingListDataState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "scaling_list_data {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "scaling_list_pred_mode_flag {");
  for (const std::vector<uint32_t>& vv : scaling_list_pred_mode_flag) {
    fprintf(outfp, " {");
    for (const uint32_t& v : vv) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "scaling_list_pred_matrix_id_delta {");
  for (const std::vector<uint32_t>& vv : scaling_list_pred_matrix_id_delta) {
    fprintf(outfp, " {");
    for (const uint32_t& v : vv) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "scaling_list_dc_coef_minus8 {");
  for (const std::vector<int32_t>& vv : scaling_list_dc_coef_minus8) {
    fprintf(outfp, " {");
    for (const int32_t& v : vv) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "ScalingList {");
  for (const std::vector<std::vector<uint32_t>>& vvv : ScalingList) {
    fprintf(outfp, " {");
    for (const std::vector<uint32_t>& vv : vvv) {
      fprintf(outfp, " {");
      for (const uint32_t& v : vv) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, " }");
  }
  fprintf(outfp, " }");

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
