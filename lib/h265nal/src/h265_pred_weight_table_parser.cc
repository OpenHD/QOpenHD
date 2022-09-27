/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_pred_weight_table_parser.h"

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

// Unpack RBSP and parse pred_weight_table state from the supplied buffer.
std::unique_ptr<H265PredWeightTableParser::PredWeightTableState>
H265PredWeightTableParser::ParsePredWeightTable(
    const uint8_t* data, size_t length, uint32_t ChromaArrayType,
    uint32_t num_ref_idx_l0_active_minus1) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePredWeightTable(&bit_buffer, ChromaArrayType,
                              num_ref_idx_l0_active_minus1);
}

std::unique_ptr<H265PredWeightTableParser::PredWeightTableState>
H265PredWeightTableParser::ParsePredWeightTable(
    rtc::BitBuffer* bit_buffer, uint32_t ChromaArrayType,
    uint32_t num_ref_idx_l0_active_minus1) noexcept {
  uint32_t bits_tmp;
  int32_t sgolomb_tmp;

  // H265 pred_weight_table() NAL Unit.
  // Section 7.3.6.3 ("Weighted prediction parameters syntax") of the
  // H.265 standard for a complete description.
  auto pred_weight_table = std::make_unique<PredWeightTableState>();

  pred_weight_table->ChromaArrayType = ChromaArrayType;
  pred_weight_table->num_ref_idx_l0_active_minus1 =
      num_ref_idx_l0_active_minus1;

  // luma_log2_weight_denom  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(pred_weight_table->luma_log2_weight_denom))) {
    return nullptr;
  }

  if (pred_weight_table->ChromaArrayType != 0) {
    // delta_chroma_log2_weight_denom  se(v)
    if (!bit_buffer->ReadSignedExponentialGolomb(
            &(pred_weight_table->delta_chroma_log2_weight_denom))) {
      return nullptr;
    }
  }

  for (uint32_t i = 0; i <= pred_weight_table->num_ref_idx_l0_active_minus1;
       ++i) {
    // from ffmpeg/libavcodec/cbs_h265_syntax_template.c
    // "1 (is not same POC and same layer_id)"
    // luma_weight_l0_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    pred_weight_table->luma_weight_l0_flag.push_back(bits_tmp);
  }

  if (pred_weight_table->ChromaArrayType != 0) {
    for (uint32_t i = 0; i <= pred_weight_table->num_ref_idx_l0_active_minus1;
         ++i) {
      // from ffmpeg/libavcodec/cbs_h265_syntax_template.c
      // "1 (is not same POC and same layer_id)"
      // chroma_weight_l0_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      pred_weight_table->chroma_weight_l0_flag.push_back(bits_tmp);
    }
  }

  for (uint32_t i = 0; i <= pred_weight_table->num_ref_idx_l0_active_minus1;
       ++i) {
    if (pred_weight_table->luma_weight_l0_flag[i]) {
      // delta_luma_weight_l0[i]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      pred_weight_table->delta_luma_weight_l0.push_back(sgolomb_tmp);
      // luma_offset_l0[i]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      pred_weight_table->luma_offset_l0.push_back(sgolomb_tmp);
    }
    if (pred_weight_table->ChromaArrayType != 0) {
      if (pred_weight_table->chroma_weight_l0_flag[i]) {
        pred_weight_table->delta_chroma_weight_l0.emplace_back();
        pred_weight_table->delta_chroma_offset_l0.emplace_back();
        for (int j = 0; i < 2; ++j) {
          // delta_chroma_weight_l0[i][j]  se(v)
          if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
            return nullptr;
          }
          pred_weight_table->delta_chroma_weight_l0.back().push_back(
              sgolomb_tmp);

          // delta_chroma_offset_l0[i][j]  se(v)
          if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
            return nullptr;
          }
          pred_weight_table->delta_chroma_offset_l0.back().push_back(
              sgolomb_tmp);
        }
      }
    }
  }

  return pred_weight_table;
}

#ifdef FDUMP_DEFINE
void H265PredWeightTableParser::PredWeightTableState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "pred_weight_table {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_log2_weight_denom: %i", luma_log2_weight_denom);

  if (ChromaArrayType != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_chroma_log2_weight_denom: %i",
            delta_chroma_log2_weight_denom);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_weight_l0_flag {");
  for (const uint32_t& v : luma_weight_l0_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  if (ChromaArrayType != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_weight_l0_flag {");
    for (const uint32_t& v : chroma_weight_l0_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "delta_luma_weight_l0 {");
  for (const uint32_t& v : delta_luma_weight_l0) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_offset_l0 {");
  for (const uint32_t& v : luma_offset_l0) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  if (ChromaArrayType != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_chroma_weight_l0 {");
    for (const std::vector<uint32_t>& vv : delta_chroma_weight_l0) {
      fprintf(outfp, " {");
      for (const uint32_t& v : vv) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_chroma_offset_l0 {");
    for (const std::vector<uint32_t>& vv : delta_chroma_offset_l0) {
      fprintf(outfp, " {");
      for (const uint32_t& v : vv) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, " }");
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
