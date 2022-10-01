/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_dec_ref_pic_marking_parser.h"

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

// Unpack RBSP and parse dec_ref_pic_marking state from the supplied buffer.
std::unique_ptr<H264DecRefPicMarkingParser::DecRefPicMarkingState>
H264DecRefPicMarkingParser::ParseDecRefPicMarking(
    const uint8_t* data, size_t length, uint32_t nal_unit_type) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseDecRefPicMarking(&bit_buffer, nal_unit_type);
}

std::unique_ptr<H264DecRefPicMarkingParser::DecRefPicMarkingState>
H264DecRefPicMarkingParser::ParseDecRefPicMarking(
    rtc::BitBuffer* bit_buffer, uint32_t nal_unit_type) noexcept {
  uint32_t golomb_tmp;

  // H264 dec_ref_pic_marking() NAL Unit.
  // Section 7.3.3.3 ("Decoded reference picture marking syntax") of the
  // H.264 standard for a complete description.
  auto dec_ref_pic_marking = std::make_unique<DecRefPicMarkingState>();

  // store input values
  dec_ref_pic_marking->nal_unit_type = nal_unit_type;

  // Equation (7-1)
  uint32_t IdrPicFlag = ((nal_unit_type == 5) ? 1 : 0);

  if (IdrPicFlag) {
    // no_output_of_prior_pics_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(dec_ref_pic_marking->no_output_of_prior_pics_flag), 1)) {
      return nullptr;
    }

    // long_term_reference_flag  u(1)
    if (!bit_buffer->ReadBits(&(dec_ref_pic_marking->long_term_reference_flag),
                              1)) {
      return nullptr;
    }

  } else {
    // adaptive_ref_pic_marking_mode_flag  u(1)
    if (!bit_buffer->ReadBits(
            &(dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag), 1)) {
      return nullptr;
    }

    if (dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag) {
      do {
        // memory_management_control_operation[i]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        dec_ref_pic_marking->memory_management_control_operation.push_back(
            golomb_tmp);

        if ((dec_ref_pic_marking->memory_management_control_operation.back() ==
             1) ||
            (dec_ref_pic_marking->memory_management_control_operation.back() ==
             3)) {
          // difference_of_pic_nums_minus1[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          dec_ref_pic_marking->difference_of_pic_nums_minus1.push_back(
              golomb_tmp);
        }

        if (dec_ref_pic_marking->memory_management_control_operation.back() ==
            2) {
          // long_term_pic_num[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          dec_ref_pic_marking->long_term_pic_num.push_back(golomb_tmp);
        }

        if ((dec_ref_pic_marking->memory_management_control_operation.back() ==
             3) ||
            (dec_ref_pic_marking->memory_management_control_operation.back() ==
             6)) {
          // long_term_frame_idx[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          dec_ref_pic_marking->long_term_frame_idx.push_back(golomb_tmp);
        }

        if (dec_ref_pic_marking->memory_management_control_operation.back() ==
            4) {
          // max_long_term_frame_idx_plus1[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          dec_ref_pic_marking->max_long_term_frame_idx_plus1.push_back(
              golomb_tmp);
        }
      } while (
          dec_ref_pic_marking->memory_management_control_operation.back() != 0);
    }
  }

  return dec_ref_pic_marking;
}

#ifdef FDUMP_DEFINE
void H264DecRefPicMarkingParser::DecRefPicMarkingState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "dec_ref_pic_marking {");
  indent_level = indent_level_incr(indent_level);

  if (nal_unit_type == 5) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "no_output_of_prior_pics_flag: %i",
            no_output_of_prior_pics_flag);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "long_term_reference_flag: %i", long_term_reference_flag);

  } else {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "adaptive_ref_pic_marking_mode_flag: %i",
            adaptive_ref_pic_marking_mode_flag);

    if (adaptive_ref_pic_marking_mode_flag) {
      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "memory_management_control_operation {");
      for (const uint32_t& v : memory_management_control_operation) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "difference_of_pic_nums_minus1 {");
      for (const uint32_t& v : difference_of_pic_nums_minus1) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "long_term_pic_num {");
      for (const uint32_t& v : long_term_pic_num) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "long_term_frame_idx {");
      for (const uint32_t& v : long_term_frame_idx) {
        fprintf(outfp, " %i", v);
      }
      fprintf(outfp, " }");

      fdump_indent_level(outfp, indent_level);
      fprintf(outfp, "max_long_term_frame_idx_plus1 {");
      for (const uint32_t& v : max_long_term_frame_idx_plus1) {
        fprintf(outfp, " %i", v);
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
