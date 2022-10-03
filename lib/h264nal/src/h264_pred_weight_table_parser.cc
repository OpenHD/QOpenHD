/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_pred_weight_table_parser.h"

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

// Unpack RBSP and parse pred_weight_table state from the supplied buffer.
std::unique_ptr<H264PredWeightTableParser::PredWeightTableState>
H264PredWeightTableParser::ParsePredWeightTable(
    const uint8_t* data, size_t length, uint32_t chroma_array_type,
    uint32_t slice_type, uint32_t num_ref_idx_l0_active_minus1,
    uint32_t num_ref_idx_l1_active_minus1) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePredWeightTable(&bit_buffer, chroma_array_type, slice_type,
                              num_ref_idx_l0_active_minus1,
                              num_ref_idx_l1_active_minus1);
}

std::unique_ptr<H264PredWeightTableParser::PredWeightTableState>
H264PredWeightTableParser::ParsePredWeightTable(
    rtc::BitBuffer* bit_buffer, uint32_t chroma_array_type, uint32_t slice_type,
    uint32_t num_ref_idx_l0_active_minus1,
    uint32_t num_ref_idx_l1_active_minus1) noexcept {
  uint32_t bits_tmp;
  int32_t sgolomb_tmp;

  // H264 pred_weight_table() NAL Unit.
  // Section 7.3.3.2 ("Prediction weight table syntax") of the
  // H.264 standard for a complete description.
  auto pred_weight_table = std::make_unique<PredWeightTableState>();

  // store input values
  pred_weight_table->chroma_array_type = chroma_array_type;
  pred_weight_table->slice_type = slice_type;
  pred_weight_table->num_ref_idx_l0_active_minus1 =
      num_ref_idx_l0_active_minus1;
  pred_weight_table->num_ref_idx_l1_active_minus1 =
      num_ref_idx_l1_active_minus1;

  // luma_log2_weight_denom  ue(v)
  if (!bit_buffer->ReadExponentialGolomb(
          &(pred_weight_table->luma_log2_weight_denom))) {
    return nullptr;
  }

  if (pred_weight_table->chroma_array_type != 0) {
    // chroma_log2_weight_denom  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(pred_weight_table->chroma_log2_weight_denom))) {
      return nullptr;
    }
  }

  for (uint32_t i = 0; i <= pred_weight_table->num_ref_idx_l0_active_minus1;
       ++i) {
    // luma_weight_l0_flag[i]  u(1)
    if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
      return nullptr;
    }
    pred_weight_table->luma_weight_l0_flag.push_back(bits_tmp);

    if (pred_weight_table->luma_weight_l0_flag[i]) {
      // luma_weight_l0[i]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      pred_weight_table->luma_weight_l0.push_back(sgolomb_tmp);

      // luma_offset_l0[i]  se(v)
      if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
        return nullptr;
      }
      pred_weight_table->luma_offset_l0.push_back(sgolomb_tmp);
    }

    if (pred_weight_table->chroma_array_type != 0) {
      // chroma_weight_l0_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      pred_weight_table->chroma_weight_l0_flag.push_back(bits_tmp);

      if (pred_weight_table->chroma_weight_l0_flag[i]) {
        pred_weight_table->chroma_weight_l0.emplace_back();
        pred_weight_table->chroma_offset_l0.emplace_back();
        for (uint32_t j = 0; j < 2; ++j) {
          // chroma_weight_l0[i][j]  se(v)
          if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
            return nullptr;
          }
          pred_weight_table->chroma_weight_l0.back().push_back(sgolomb_tmp);

          // chroma_offset_l0[i][j]  se(v)
          if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
            return nullptr;
          }
          pred_weight_table->chroma_offset_l0.back().push_back(sgolomb_tmp);
        }
      }
    }
  }

  if ((slice_type == SliceType::B) ||
      (slice_type == SliceType::B_ALL)) {  // slice_type == B
    for (uint32_t i = 0; i <= pred_weight_table->num_ref_idx_l1_active_minus1;
         ++i) {
      // luma_weight_l1_flag[i]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      pred_weight_table->luma_weight_l1_flag.push_back(bits_tmp);

      if (pred_weight_table->luma_weight_l1_flag[i]) {
        // luma_weight_l1[i]  se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
          return nullptr;
        }
        pred_weight_table->luma_weight_l1.push_back(sgolomb_tmp);

        // luma_offset_l1[i]  se(v)
        if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
          return nullptr;
        }
        pred_weight_table->luma_offset_l1.push_back(sgolomb_tmp);
      }

      if (pred_weight_table->chroma_array_type != 0) {
        // chroma_weight_l1_flag[i]  u(1)
        if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
          return nullptr;
        }
        pred_weight_table->chroma_weight_l1_flag.push_back(bits_tmp);

        if (pred_weight_table->chroma_weight_l1_flag[i]) {
          // chroma_weight_l1[i][j]  se(v)
          pred_weight_table->chroma_weight_l1.emplace_back();

          // chroma_offset_l1[i][j]  se(v)
          pred_weight_table->chroma_offset_l1.emplace_back();
          for (uint32_t j = 0; j < 2; ++j) {
            if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
              return nullptr;
            }
            pred_weight_table->chroma_weight_l1.back().push_back(sgolomb_tmp);

            if (!bit_buffer->ReadSignedExponentialGolomb(&sgolomb_tmp)) {
              return nullptr;
            }
            pred_weight_table->chroma_offset_l1.back().push_back(sgolomb_tmp);
          }
        }
      }
    }
  }

  return pred_weight_table;
}

#ifdef FDUMP_DEFINE
void H264PredWeightTableParser::PredWeightTableState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "pred_weight_table {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_log2_weight_denom: %i", luma_log2_weight_denom);

  if (chroma_array_type != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_log2_weight_denom: %i", chroma_log2_weight_denom);
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_weight_l0_flag {");
  for (const uint32_t& v : luma_weight_l0_flag) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_weight_l0 {");
  for (const uint32_t& v : luma_weight_l0) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "luma_offset_l0 {");
  for (const uint32_t& v : luma_offset_l0) {
    fprintf(outfp, " %i", v);
  }
  fprintf(outfp, " }");

  if (chroma_array_type != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_weight_l0_flag {");
    for (const uint32_t& v : chroma_weight_l0_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_weight_l0 {");
    for (const std::vector<uint32_t>& vv : chroma_weight_l0) {
      fprintf(outfp, " {");
      for (const uint32_t& v : vv) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "chroma_offset_l0 {");
    for (const std::vector<uint32_t>& vv : chroma_offset_l0) {
      fprintf(outfp, " {");
      for (const uint32_t& v : vv) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, " }");
  }

  if ((slice_type == SliceType::B) ||
      (slice_type == SliceType::B_ALL)) {  // slice_type == B
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "luma_weight_l1_flag {");
    for (const uint32_t& v : luma_weight_l1_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "luma_weight_l1 {");
    for (const uint32_t& v : luma_weight_l1) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "luma_offset_l1 {");
    for (const uint32_t& v : luma_offset_l1) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    if (chroma_array_type != 0) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "chroma_weight_l1_flag {");
      for (const uint32_t& v : chroma_weight_l1_flag) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "chroma_weight_l1 {");
      for (const std::vector<uint32_t>& vv : chroma_weight_l1) {
        fprintf(outfp, " {");
        for (const uint32_t& v : vv) {
          fprintf(outfp, " %i", v);
        }
        fprintf(outfp, " }");
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "chroma_offset_l1 {");
      for (const std::vector<uint32_t>& vv : chroma_offset_l1) {
        fprintf(outfp, " {");
        for (const uint32_t& v : vv) {
          fprintf(outfp, " %i", v);
        }
        fprintf(outfp, " }");
      }
      fprintf(outfp, " }");
    }
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
