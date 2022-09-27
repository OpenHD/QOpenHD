/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h265_st_ref_pic_set_parser.h"

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

// Unpack RBSP and parse st_ref_pic_set state from the supplied buffer.
std::unique_ptr<H265StRefPicSetParser::StRefPicSetState>
H265StRefPicSetParser::ParseStRefPicSet(
    const uint8_t* data, size_t length, uint32_t stRpsIdx,
    uint32_t num_short_term_ref_pic_sets,
    const std::vector<std::unique_ptr<struct StRefPicSetState>>*
        st_ref_pic_set_state_vector,
    uint32_t max_num_pics) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseStRefPicSet(&bit_buffer, stRpsIdx, num_short_term_ref_pic_sets,
                          st_ref_pic_set_state_vector, max_num_pics);
}

void H265StRefPicSetParser::StRefPicSetState::DeriveValues(
    const std::vector<std::unique_ptr<struct StRefPicSetState>>*
        st_ref_pic_set_state_vector,
    const uint32_t RefRpsIdx) noexcept {
#define HEVC_MAX_REFS 16
  int ref_delta_poc_s0[HEVC_MAX_REFS] = {0};
  int ref_delta_poc_s1[HEVC_MAX_REFS] = {0};
  int delta_poc_s0[HEVC_MAX_REFS] = {0};
  int delta_poc_s1[HEVC_MAX_REFS] = {0};
  uint8_t used_by_curr_pic_s0[HEVC_MAX_REFS] = {0};
  uint8_t used_by_curr_pic_s1[HEVC_MAX_REFS] = {0};

  const auto& ref = (*st_ref_pic_set_state_vector)[RefRpsIdx];

  // Equation 7-60
  int32_t delta_rps = (1 - 2 * delta_rps_sign) * (abs_delta_rps_minus1 + 1);
  uint32_t ref_num_delta_pocs = ref->num_negative_pics + ref->num_positive_pics;

  int32_t d_poc = 0;
  for (uint32_t i = 0; i < ref->num_negative_pics; i++) {
    d_poc -= ref->delta_poc_s0_minus1[i] + 1;
    ref_delta_poc_s0[i] = d_poc;
  }
  d_poc = 0;
  for (uint32_t i = 0; i < ref->num_positive_pics; i++) {
    d_poc += ref->delta_poc_s1_minus1[i] + 1;
    ref_delta_poc_s1[i] = d_poc;
  }

  uint32_t i = 0;
  if (ref->num_positive_pics > 0) {
    for (int32_t j = ref->num_positive_pics - 1; j >= 0; j--) {
      d_poc = ref_delta_poc_s1[j] + delta_rps;
      if (d_poc < 0 && use_delta_flag[ref->num_negative_pics + j]) {
        delta_poc_s0[i] = d_poc;
        used_by_curr_pic_s0[i++] =
            used_by_curr_pic_flag[ref->num_negative_pics + j];
      }
    }
  }
  if (delta_rps < 0 && use_delta_flag[ref_num_delta_pocs]) {
    delta_poc_s0[i] = delta_rps;
    used_by_curr_pic_s0[i++] = used_by_curr_pic_flag[ref_num_delta_pocs];
  }
  for (int32_t j = 0; j < static_cast<int32_t>(ref->num_negative_pics); j++) {
    d_poc = ref_delta_poc_s0[j] + delta_rps;
    if (d_poc < 0 && use_delta_flag[j]) {
      delta_poc_s0[i] = d_poc;
      used_by_curr_pic_s0[i++] = used_by_curr_pic_flag[j];
    }
  }

  num_negative_pics = i;
  for (i = 0; i < num_negative_pics; i++) {
    delta_poc_s0_minus1.push_back(
        -(delta_poc_s0[i] - (i == 0 ? 0 : delta_poc_s0[i - 1])) - 1);
    used_by_curr_pic_s0_flag.push_back(used_by_curr_pic_s0[i]);
  }

  i = 0;
  if (ref->num_negative_pics > 0) {
    for (int32_t j = ref->num_negative_pics - 1; j >= 0; j--) {
      d_poc = ref_delta_poc_s0[j] + delta_rps;
      if (d_poc > 0 && use_delta_flag[j]) {
        delta_poc_s1[i] = d_poc;
        used_by_curr_pic_s1[i++] = used_by_curr_pic_flag[j];
      }
    }
  }
  if (delta_rps > 0 && use_delta_flag[ref_num_delta_pocs]) {
    delta_poc_s1[i] = delta_rps;
    used_by_curr_pic_s1[i++] = used_by_curr_pic_flag[ref_num_delta_pocs];
  }
  for (int32_t j = 0; j < static_cast<int32_t>(ref->num_positive_pics); j++) {
    d_poc = ref_delta_poc_s1[j] + delta_rps;
    if (d_poc > 0 && use_delta_flag[ref->num_negative_pics + j]) {
      delta_poc_s1[i] = d_poc;
      used_by_curr_pic_s1[i++] =
          used_by_curr_pic_flag[ref->num_negative_pics + j];
    }
  }

  num_positive_pics = i;
  for (i = 0; i < num_positive_pics; i++) {
    delta_poc_s1_minus1.push_back(delta_poc_s1[i] -
                                  (i == 0 ? 0 : delta_poc_s1[i - 1]) - 1);
    used_by_curr_pic_s1_flag.push_back(used_by_curr_pic_s1[i]);
  }
}

std::unique_ptr<H265StRefPicSetParser::StRefPicSetState>
H265StRefPicSetParser::ParseStRefPicSet(
    rtc::BitBuffer* bit_buffer, uint32_t stRpsIdx,
    uint32_t num_short_term_ref_pic_sets,
    const std::vector<std::unique_ptr<struct StRefPicSetState>>*
        st_ref_pic_set_state_vector,
    uint32_t max_num_pics) noexcept {
  uint32_t bits_tmp;
  uint32_t golomb_tmp;

  if (num_short_term_ref_pic_sets >
      h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX) {
#ifdef FPRINT_ERRORS
    fprintf(stderr,
            "error: num_short_term_ref_pic_sets == %" PRIu32
            " > h265limits::NUM_SHORT_TERM_REF_PIC_SETS_MAX\n",
            num_short_term_ref_pic_sets);
#endif  // FPRINT_ERRORS
    return nullptr;
  }

  // H265 st_ref_pic_set() NAL Unit.
  // Section 7.3.7 ("Short-term reference picture set syntax parameter set
  // syntax") of the H.265 standard for a complete description.
  auto st_ref_pic_set = std::make_unique<StRefPicSetState>();

  st_ref_pic_set->stRpsIdx = stRpsIdx;
  st_ref_pic_set->num_short_term_ref_pic_sets = num_short_term_ref_pic_sets;

  if (stRpsIdx != 0) {
    // inter_ref_pic_set_prediction_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(st_ref_pic_set->inter_ref_pic_set_prediction_flag), 1)) {
      return nullptr;
    }
  }

  if (st_ref_pic_set->inter_ref_pic_set_prediction_flag) {
    if (stRpsIdx == st_ref_pic_set->num_short_term_ref_pic_sets) {
      // delta_idx_minus1  ue(v)
      if (!bit_buffer->ReadExponentialGolomb(
              &(st_ref_pic_set->delta_idx_minus1))) {
        return nullptr;
      }
    }

    // delta_rps_sign  u(1)
    if (!bit_buffer->ReadBits(&(st_ref_pic_set->delta_rps_sign), 1)) {
      return nullptr;
    }

    // Section 7.4.8: "The value of delta_idx_minus1 shall be in the range
    // of 0 to stRpsIdx - 1, inclusive."
    if (st_ref_pic_set->delta_idx_minus1 > (st_ref_pic_set->stRpsIdx - 1)) {
      // invalid delta_idx_minus1 value
      return nullptr;
    }

    // abs_delta_rps_minus1  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(st_ref_pic_set->abs_delta_rps_minus1))) {
      return nullptr;
    }

    // Equation 7-59
    const uint32_t RefRpsIdx =
        st_ref_pic_set->stRpsIdx - (st_ref_pic_set->delta_idx_minus1 + 1);

    // Equation 7-71
    const auto& ref = (*st_ref_pic_set_state_vector)[RefRpsIdx];
    uint32_t NumDeltaPocs_RefRpsIdx =
        ref->num_negative_pics + ref->num_positive_pics;

    // Section F.7.4.8: DeltaPoCs shall be in range 0 to MaxDpbSize-1,
    // inclusive
    if (NumDeltaPocs_RefRpsIdx >= h265limits::HEVC_MAX_DPB_SIZE) {
      return nullptr;
    }

    for (uint32_t j = 0; j <= NumDeltaPocs_RefRpsIdx; j++) {
      // used_by_curr_pic_flag[j]  u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      st_ref_pic_set->used_by_curr_pic_flag.push_back(bits_tmp);

      if (!st_ref_pic_set->used_by_curr_pic_flag.back()) {
        // use_delta_flag[j]  u(1)
        if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
          return nullptr;
        }
      } else {
        // default use_delta_flag value (page 103)
        bits_tmp = 1;
      }
      st_ref_pic_set->use_delta_flag.push_back(bits_tmp);
    }

    st_ref_pic_set->DeriveValues(st_ref_pic_set_state_vector, RefRpsIdx);

  } else {
    // num_negative_pics  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(st_ref_pic_set->num_negative_pics))) {
      return nullptr;
    }
    // Section 7.4.8
    // "When nuh_layer_id of the current picture is equal to 0, the value
    // of num_negative_pics shall be in the range of 0 to
    // sps_max_dec_pic_buffering_minus1[sps_max_sub_layers_minus1],
    // inclusive."
    if (st_ref_pic_set->num_negative_pics > max_num_pics) {
      // invalid num_negative_pics
      return nullptr;
    }

    // num_positive_pics  ue(v)
    if (!bit_buffer->ReadExponentialGolomb(
            &(st_ref_pic_set->num_positive_pics))) {
      return nullptr;
    }
    // Section 7.4.8
    // "When nuh_layer_id of the current picture is equal to 0, the value
    // of num_positive_pics shall be in the range of 0 to
    // sps_max_dec_pic_buffering_minus1[sps_max_sub_layers_minus1] -
    // num_negative_pics, inclusive."

    if (st_ref_pic_set->num_positive_pics >
        (max_num_pics - st_ref_pic_set->num_negative_pics)) {
      // invalid num_positive_pics
      return nullptr;
    }

    for (uint32_t i = 0; i < st_ref_pic_set->num_negative_pics; i++) {
      // delta_poc_s0_minus1[i] ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      st_ref_pic_set->delta_poc_s0_minus1.push_back(golomb_tmp);

      // used_by_curr_pic_s0_flag[i] u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      st_ref_pic_set->used_by_curr_pic_s0_flag.push_back(bits_tmp);
    }

    for (uint32_t i = 0; i < st_ref_pic_set->num_positive_pics; i++) {
      // delta_poc_s1_minus1[i] ue(v)
      if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
        return nullptr;
      }
      st_ref_pic_set->delta_poc_s1_minus1.push_back(golomb_tmp);

      // used_by_curr_pic_s1_flag[i] u(1)
      if (!bit_buffer->ReadBits(&bits_tmp, 1)) {
        return nullptr;
      }
      st_ref_pic_set->used_by_curr_pic_s1_flag.push_back(bits_tmp);
    }
  }

  return st_ref_pic_set;
}

#ifdef FDUMP_DEFINE
void H265StRefPicSetParser::StRefPicSetState::fdump(FILE* outfp,
                                                    int indent_level) const {
  fprintf(outfp, "st_ref_pic_set {");
  indent_level = indent_level_incr(indent_level);

  if (stRpsIdx != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "inter_ref_pic_set_prediction_flag: %i",
            inter_ref_pic_set_prediction_flag);
  }

  if (inter_ref_pic_set_prediction_flag) {
    if (stRpsIdx == num_short_term_ref_pic_sets) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "delta_idx_minus1: %i", delta_idx_minus1);
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_rps_sign: %i", delta_rps_sign);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "abs_delta_rps_minus1: %i", abs_delta_rps_minus1);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "used_by_curr_pic_flag {");
    for (const uint32_t& v : used_by_curr_pic_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "use_delta_flag {");
    for (const uint32_t& v : use_delta_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

  } else {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_negative_pics: %i", num_negative_pics);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "num_positive_pics: %i", num_positive_pics);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_poc_s0_minus1 {");
    for (const uint32_t& v : delta_poc_s0_minus1) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "used_by_curr_pic_s0_flag {");
    for (const uint32_t& v : used_by_curr_pic_s0_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "delta_poc_s1_minus1 {");
    for (const uint32_t& v : delta_poc_s1_minus1) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "used_by_curr_pic_s1_flag {");
    for (const uint32_t& v : used_by_curr_pic_s1_flag) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h265nal
