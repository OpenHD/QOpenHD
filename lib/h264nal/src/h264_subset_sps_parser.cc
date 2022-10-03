/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_subset_sps_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"
#include "h264_vui_parameters_parser.h"

namespace {
typedef std::shared_ptr<h264nal::H264SubsetSpsParser::SubsetSpsState>
    SharedPtrSubsetSps;
}  // namespace

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse SPS state from the supplied buffer.
std::shared_ptr<H264SubsetSpsParser::SubsetSpsState>
H264SubsetSpsParser::ParseSubsetSps(const uint8_t* data,
                                    size_t length) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParseSubsetSps(&bit_buffer);
}

std::shared_ptr<H264SubsetSpsParser::SubsetSpsState>
H264SubsetSpsParser::ParseSubsetSps(rtc::BitBuffer* bit_buffer) noexcept {
  // H264 SPS Nal Unit (subset_seq_parameter_set_rbsp()) parser.
  // Section 7.3.2.1.3 ("Subset sequence parameter set data syntax") of the
  // H.264 standard for a complete description.
  auto subset_sps = std::make_shared<SubsetSpsState>();

  // seq_parameter_set_data()
  subset_sps->seq_parameter_set_data =
      H264SpsDataParser::ParseSpsData(bit_buffer);
  if (subset_sps->seq_parameter_set_data == nullptr) {
    return nullptr;
  }

  if (subset_sps->seq_parameter_set_data->profile_idc == 83 ||
      subset_sps->seq_parameter_set_data->profile_idc == 86) {
    uint32_t ChromaArrayType =
        subset_sps->seq_parameter_set_data->getChromaArrayType();
    // seq_parameter_set_svc_extension()  // specified in Annex G
    subset_sps->seq_parameter_set_svc_extension =
        H264SpsSvcExtensionParser::ParseSpsSvcExtension(bit_buffer,
                                                        ChromaArrayType);
    if (subset_sps->seq_parameter_set_svc_extension == nullptr) {
      return nullptr;
    }

    // svc_vui_parameters_present_flag  u(1)
    if (!bit_buffer->ReadBits(&subset_sps->svc_vui_parameters_present_flag,
                              1)) {
      return nullptr;
    }

    if (subset_sps->svc_vui_parameters_present_flag == 1) {
      // svc_vui_parameters_extension() // specified in Annex G
    }

  } else if (subset_sps->seq_parameter_set_data->profile_idc == 118 ||
             subset_sps->seq_parameter_set_data->profile_idc == 128 ||
             subset_sps->seq_parameter_set_data->profile_idc == 134) {
    // bit_equal_to_one  u(1)
    if (!bit_buffer->ReadBits(&subset_sps->bit_equal_to_one, 1)) {
      return nullptr;
    }

    // seq_parameter_set_mvc_extension() // specified in Annex H

    // mvc_vui_parameters_present_flag  u(1)
    if (!bit_buffer->ReadBits(&subset_sps->mvc_vui_parameters_present_flag,
                              1)) {
      return nullptr;
    }

    if (subset_sps->mvc_vui_parameters_present_flag == 1) {
      // mvc_vui_parameters_extension()  // specified in Annex H
    }

  } else if (subset_sps->seq_parameter_set_data->profile_idc == 138 ||
             subset_sps->seq_parameter_set_data->profile_idc == 135) {
    // bit_equal_to_one  u(1)
    if (!bit_buffer->ReadBits(&subset_sps->bit_equal_to_one, 1)) {
      return nullptr;
    }

    // seq_parameter_set_mvcd_extension(()  // specified in Annex I

  } else if (subset_sps->seq_parameter_set_data->profile_idc == 139) {
    // bit_equal_to_one  u(1)
    if (!bit_buffer->ReadBits(&subset_sps->bit_equal_to_one, 1)) {
      return nullptr;
    }

    // seq_parameter_set_mvcd_extension()  // specified in Annex I

    // seq_parameter_set_3davc_extension()  // specified in Annex J
  }

  // additional_extension2_flag  u(1)
  if (!bit_buffer->ReadBits(&subset_sps->additional_extension2_flag, 1)) {
    return nullptr;
  }

  if (subset_sps->additional_extension2_flag == 1) {
    while (more_rbsp_data(bit_buffer)) {
      // additional_extension2_data_flag  u(1)
      if (!bit_buffer->ReadBits(&subset_sps->additional_extension2_data_flag,
                                1)) {
        return nullptr;
      }
    }
  }

  rbsp_trailing_bits(bit_buffer);

  return subset_sps;
}

#ifdef FDUMP_DEFINE
void H264SubsetSpsParser::SubsetSpsState::fdump(FILE* outfp,
                                                int indent_level) const {
  fprintf(outfp, "subset_sps {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  seq_parameter_set_data->fdump(outfp, indent_level);

  if (seq_parameter_set_data->profile_idc == 83 ||
      seq_parameter_set_data->profile_idc == 86) {
    fdump_indent_level(outfp, indent_level);
    seq_parameter_set_svc_extension->fdump(outfp, indent_level);

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "svc_vui_parameters_present_flag: %i",
            svc_vui_parameters_present_flag);

    if (svc_vui_parameters_present_flag == 1) {
      // svc_vui_parameters_extension() // specified in Annex G
    }

  } else if (seq_parameter_set_data->profile_idc == 118 ||
             seq_parameter_set_data->profile_idc == 128 ||
             seq_parameter_set_data->profile_idc == 134) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "bit_equal_to_one: %i", bit_equal_to_one);

    // seq_parameter_set_mvc_extension() // specified in Annex H

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "mvc_vui_parameters_present_flag: %i",
            mvc_vui_parameters_present_flag);

    if (mvc_vui_parameters_present_flag == 1) {
      // mvc_vui_parameters_extension()  // specified in Annex H
    }

  } else if (seq_parameter_set_data->profile_idc == 138 ||
             seq_parameter_set_data->profile_idc == 135) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "bit_equal_to_one: %i", bit_equal_to_one);

    // seq_parameter_set_mvcd_extension(()  // specified in Annex I

  } else if (seq_parameter_set_data->profile_idc == 139) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "bit_equal_to_one: %i", bit_equal_to_one);

    // seq_parameter_set_mvcd_extension()  // specified in Annex I

    // seq_parameter_set_3davc_extension()  // specified in Annex J
  }

  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "additional_extension2_flag: %i", additional_extension2_flag);

  if (additional_extension2_flag == 1) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "additional_extension2_data_flag: %i",
            additional_extension2_data_flag);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
