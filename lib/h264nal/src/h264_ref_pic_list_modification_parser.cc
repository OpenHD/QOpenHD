/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_ref_pic_list_modification_parser.h"

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

// Unpack RBSP and parse ref_pic_list_modification state from the supplied
// buffer.
std::unique_ptr<H264RefPicListModificationParser::RefPicListModificationState>
H264RefPicListModificationParser::ParseRefPicListModification(
    const uint8_t* data, size_t length, uint32_t slice_type) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseRefPicListModification(&bit_buffer, slice_type);
}

std::unique_ptr<H264RefPicListModificationParser::RefPicListModificationState>
H264RefPicListModificationParser::ParseRefPicListModification(
    rtc::BitBuffer* bit_buffer, uint32_t slice_type) noexcept {
  uint32_t golomb_tmp;

  // H264 ref_pic_list_modification() NAL Unit.
  // Section 7.3.3.1 ("Reference picture list modification syntax") of the
  // H.264 standard for a complete description.
  auto ref_pic_list_modification =
      std::make_unique<RefPicListModificationState>();

  // store input values
  ref_pic_list_modification->slice_type = slice_type;

  if ((slice_type != SliceType::I) && (slice_type != SliceType::I_ALL) &&
      (slice_type != SliceType::SI) &&
      (slice_type !=
       SliceType::SI_ALL)) {  // slice_type != I && slice_type != SI
    // ref_pic_list_modification_flag_l0  u(1)
    if (!bit_buffer->ReadBits(
            &(ref_pic_list_modification->ref_pic_list_modification_flag_l0),
            1)) {
      return nullptr;
    }

    if (ref_pic_list_modification->ref_pic_list_modification_flag_l0) {
      do {
        // modification_of_pic_nums_idc[i]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        ref_pic_list_modification->modification_of_pic_nums_idc.push_back(
            golomb_tmp);

        if ((ref_pic_list_modification->modification_of_pic_nums_idc.back() ==
             0) ||
            (ref_pic_list_modification->modification_of_pic_nums_idc.back() ==
             1)) {
          // abs_diff_pic_num_minus1[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          ref_pic_list_modification->abs_diff_pic_num_minus1.push_back(
              golomb_tmp);

        } else if (ref_pic_list_modification->modification_of_pic_nums_idc
                       .back() == 2) {
          // long_term_pic_num[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          ref_pic_list_modification->long_term_pic_num.push_back(golomb_tmp);
        }
      } while (ref_pic_list_modification->modification_of_pic_nums_idc.back() !=
               3);
    }
  }

  if ((slice_type == SliceType::B) ||
      (slice_type == SliceType::B_ALL)) {  // slice_type == B
    // ref_pic_list_modification_flag_l1  u(1)
    if (!bit_buffer->ReadBits(
            &(ref_pic_list_modification->ref_pic_list_modification_flag_l1),
            1)) {
      return nullptr;
    }

    if (ref_pic_list_modification->ref_pic_list_modification_flag_l1) {
      do {
        // modification_of_pic_nums_idc[i]  ue(v)
        if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
          return nullptr;
        }
        ref_pic_list_modification->modification_of_pic_nums_idc.push_back(
            golomb_tmp);

        if ((ref_pic_list_modification->modification_of_pic_nums_idc.back() ==
             0) ||
            (ref_pic_list_modification->modification_of_pic_nums_idc.back() ==
             1)) {
          // abs_diff_pic_num_minus1[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          ref_pic_list_modification->abs_diff_pic_num_minus1.push_back(
              golomb_tmp);

        } else if (ref_pic_list_modification->modification_of_pic_nums_idc
                       .back() == 2) {
          // long_term_pic_num[i]  ue(v)
          if (!bit_buffer->ReadExponentialGolomb(&golomb_tmp)) {
            return nullptr;
          }
          ref_pic_list_modification->long_term_pic_num.push_back(golomb_tmp);
        }
      } while (ref_pic_list_modification->modification_of_pic_nums_idc.back() !=
               3);
    }
  }

  return ref_pic_list_modification;
}

#ifdef FDUMP_DEFINE
void H264RefPicListModificationParser::RefPicListModificationState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "ref_pic_list_modification {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "ref_pic_list_modification_flag_l0: %i",
          ref_pic_list_modification_flag_l0);

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "ref_pic_list_modification_flag_l1: %i",
          ref_pic_list_modification_flag_l1);

  if (modification_of_pic_nums_idc.size() > 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "modification_of_pic_nums_idc {");
    for (const uint32_t& v : modification_of_pic_nums_idc) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  if (abs_diff_pic_num_minus1.size() > 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "abs_diff_pic_num_minus1 {");
    for (const uint32_t& v : abs_diff_pic_num_minus1) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  if (long_term_pic_num.size() > 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "long_term_pic_num {");
    for (const uint32_t& v : long_term_pic_num) {
      fprintf(outfp, " %i", v);
    }
    fprintf(outfp, " }");
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
