/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_prefix_nal_unit_parser.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "h264_common.h"
#include "h264_vui_parameters_parser.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// prefix_nal_unit_svc()
std::unique_ptr<H264PrefixNalUnitSvcParser::PrefixNalUnitSvcState>
H264PrefixNalUnitSvcParser::ParsePrefixNalUnitSvc(
    const uint8_t* data, size_t length, uint32_t nal_ref_idc,
    uint32_t use_ref_base_pic_flag, uint32_t idr_flag) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePrefixNalUnitSvc(&bit_buffer, nal_ref_idc, use_ref_base_pic_flag,
                               idr_flag);
}

std::unique_ptr<H264PrefixNalUnitSvcParser::PrefixNalUnitSvcState>
H264PrefixNalUnitSvcParser::ParsePrefixNalUnitSvc(
    rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc,
    uint32_t use_ref_base_pic_flag, uint32_t idr_flag) noexcept {
  // H264 Prefix NAL unit SVC (prefix_nal_unit_svc()) parser.
  // Section G.7.3.2.12.1 ("Prefix NAL unit SVC syntax") of the H.264
  // standard for a complete description.
  auto prefix_nal_unit_svc = std::make_unique<PrefixNalUnitSvcState>();

  // input parameters
  prefix_nal_unit_svc->nal_ref_idc = nal_ref_idc;
  prefix_nal_unit_svc->use_ref_base_pic_flag = use_ref_base_pic_flag;
  prefix_nal_unit_svc->idr_flag = idr_flag;

  if (prefix_nal_unit_svc->nal_ref_idc != 0) {
    // store_ref_base_pic_flag  u(1)
    if (!bit_buffer->ReadBits(&prefix_nal_unit_svc->store_ref_base_pic_flag,
                              1)) {
      return nullptr;
    }

    if ((prefix_nal_unit_svc->use_ref_base_pic_flag ||
         prefix_nal_unit_svc->store_ref_base_pic_flag) &&
        !prefix_nal_unit_svc->idr_flag) {
      // dec_ref_base_pic_marking()
#ifdef FPRINT_ERRORS
      fprintf(stderr, "error: dec_ref_base_pic_marking undefined\n");
#endif  // FPRINT_ERRORS
      return nullptr;
    }

    // additional_prefix_nal_unit_extension_flag  u(1)
    if (!bit_buffer->ReadBits(
            &prefix_nal_unit_svc->additional_prefix_nal_unit_extension_flag,
            1)) {
      return nullptr;
    }

    if (prefix_nal_unit_svc->additional_prefix_nal_unit_extension_flag == 1) {
      while (more_rbsp_data(bit_buffer)) {
        // additional_prefix_nal_unit_extension_data_flag  u(1)
        if (!bit_buffer->ReadBits(
                &prefix_nal_unit_svc
                     ->additional_prefix_nal_unit_extension_data_flag,
                1)) {
          return nullptr;
        }
      }
      rbsp_trailing_bits(bit_buffer);

    } else if (more_rbsp_data(bit_buffer)) {
      while (more_rbsp_data(bit_buffer)) {
        // additional_prefix_nal_unit_extension_data_flag  u(1)
        if (!bit_buffer->ReadBits(
                &prefix_nal_unit_svc
                     ->additional_prefix_nal_unit_extension_data_flag,
                1)) {
          return nullptr;
        }
      }
      rbsp_trailing_bits(bit_buffer);
    }
  }

  return prefix_nal_unit_svc;
}

// prefix_nal_unit_rbsp()
std::unique_ptr<H264PrefixNalUnitRbspParser::PrefixNalUnitRbspState>
H264PrefixNalUnitRbspParser::ParsePrefixNalUnitRbsp(
    const uint8_t* data, size_t length, uint32_t svc_extension_flag,
    uint32_t nal_ref_idc, uint32_t use_ref_base_pic_flag,
    uint32_t idr_flag) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());
  return ParsePrefixNalUnitRbsp(&bit_buffer, svc_extension_flag, nal_ref_idc,
                                use_ref_base_pic_flag, idr_flag);
}

std::unique_ptr<H264PrefixNalUnitRbspParser::PrefixNalUnitRbspState>
H264PrefixNalUnitRbspParser::ParsePrefixNalUnitRbsp(
    rtc::BitBuffer* bit_buffer, uint32_t svc_extension_flag,
    uint32_t nal_ref_idc, uint32_t use_ref_base_pic_flag,
    uint32_t idr_flag) noexcept {
  // H264 Prefix NAL unit RBSP syntax (prefix_nal_unit_rbsp()) parser.
  // Section 7.3.2.12 ("Prefix NAL unit RBSP syntax") of the H.264
  // standard for a complete description.
  auto prefix_nal_unit_rbsp = std::make_unique<PrefixNalUnitRbspState>();

  // input parameters
  prefix_nal_unit_rbsp->svc_extension_flag = svc_extension_flag;
  prefix_nal_unit_rbsp->nal_ref_idc = nal_ref_idc;
  prefix_nal_unit_rbsp->use_ref_base_pic_flag = use_ref_base_pic_flag;
  prefix_nal_unit_rbsp->idr_flag = idr_flag;

  if (prefix_nal_unit_rbsp->svc_extension_flag == 1) {
    // prefix_nal_unit_svc()
    prefix_nal_unit_rbsp->prefix_nal_unit_svc =
        H264PrefixNalUnitSvcParser::ParsePrefixNalUnitSvc(
            bit_buffer, prefix_nal_unit_rbsp->nal_ref_idc,
            prefix_nal_unit_rbsp->use_ref_base_pic_flag,
            prefix_nal_unit_rbsp->idr_flag);
    if (prefix_nal_unit_rbsp->prefix_nal_unit_svc == nullptr) {
      return nullptr;
    }
  }

  return prefix_nal_unit_rbsp;
}

#ifdef FDUMP_DEFINE
void H264PrefixNalUnitSvcParser::PrefixNalUnitSvcState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "prefix_nal_unit_svc {");
  indent_level = indent_level_incr(indent_level);

  if (nal_ref_idc != 0) {
    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "store_ref_base_pic_flag: %i", store_ref_base_pic_flag);

    if ((use_ref_base_pic_flag || store_ref_base_pic_flag) && !idr_flag) {
      // dec_ref_base_pic_marking()
    }

    fdump_indent_level(outfp, indent_level);
    fprintf(outfp, "additional_prefix_nal_unit_extension_data_flag: %i",
            additional_prefix_nal_unit_extension_data_flag);
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}

void H264PrefixNalUnitRbspParser::PrefixNalUnitRbspState::fdump(
    FILE* outfp, int indent_level) const {
  fprintf(outfp, "prefix_nal_unit_rbsp {");
  indent_level = indent_level_incr(indent_level);

  if (svc_extension_flag) {
    if (prefix_nal_unit_svc) {
      fdump_indent_level(outfp, indent_level);
      prefix_nal_unit_svc->fdump(outfp, indent_level);
    }
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}

#endif  // FDUMP_DEFINE

}  // namespace h264nal
