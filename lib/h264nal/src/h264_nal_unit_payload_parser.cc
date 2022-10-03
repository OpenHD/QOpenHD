/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_nal_unit_payload_parser.h"

#include <stdio.h>

#include <cstdint>
#include <memory>
#include <vector>

#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_pps_parser.h"
#include "h264_prefix_nal_unit_parser.h"
#include "h264_slice_layer_extension_rbsp_parser.h"
#include "h264_slice_layer_without_partitioning_rbsp_parser.h"
#include "h264_sps_parser.h"
#include "h264_subset_sps_parser.h"

namespace h264nal {

// General note: this is based off the 2012 version of the H.264 standard.
// You can find it on this page:
// http://www.itu.int/rec/T-REC-H.264

// Unpack RBSP and parse NAL Unit payload state from the supplied buffer.
std::unique_ptr<H264NalUnitPayloadParser::NalUnitPayloadState>
H264NalUnitPayloadParser::ParseNalUnitPayload(
    const uint8_t* data, size_t length,
    H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  std::vector<uint8_t> unpacked_buffer = UnescapeRbsp(data, length);
  rtc::BitBuffer bit_buffer(unpacked_buffer.data(), unpacked_buffer.size());

  return ParseNalUnitPayload(&bit_buffer, nal_unit_header,
                             bitstream_parser_state);
}

std::unique_ptr<H264NalUnitPayloadParser::NalUnitPayloadState>
H264NalUnitPayloadParser::ParseNalUnitPayload(
    rtc::BitBuffer* bit_buffer, uint32_t nal_ref_idc, uint32_t nal_unit_type,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  H264NalUnitHeaderParser::NalUnitHeaderState nal_unit_header;
  nal_unit_header.forbidden_zero_bit = 0;
  nal_unit_header.nal_ref_idc = nal_ref_idc;
  nal_unit_header.nal_unit_type = nal_unit_type;
  nal_unit_header.svc_extension_flag = 0;
  nal_unit_header.avc_3d_extension_flag = 0;
  return ParseNalUnitPayload(bit_buffer, nal_unit_header,
                             bitstream_parser_state);
}

std::unique_ptr<H264NalUnitPayloadParser::NalUnitPayloadState>
H264NalUnitPayloadParser::ParseNalUnitPayload(
    rtc::BitBuffer* bit_buffer,
    H264NalUnitHeaderParser::NalUnitHeaderState& nal_unit_header,
    struct H264BitstreamParserState* bitstream_parser_state) noexcept {
  // H264 NAL Unit Payload (nal_unit()) parser.
  // Section 7.3.1 ("NAL unit syntax") of the H.264
  // standard for a complete description.
  auto nal_unit_payload = std::make_unique<NalUnitPayloadState>();

  // payload (Table 7-1, Section 7.4.1)
  switch (nal_unit_header.nal_unit_type) {
    case CODED_SLICE_OF_NON_IDR_PICTURE_NUT: {
      // slice_layer_without_partitioning_rbsp()
      nal_unit_payload->slice_layer_without_partitioning_rbsp =
          H264SliceLayerWithoutPartitioningRbspParser::
              ParseSliceLayerWithoutPartitioningRbsp(
                  bit_buffer, nal_unit_header.nal_ref_idc,
                  nal_unit_header.nal_unit_type, bitstream_parser_state);
      break;
    }
    case CODED_SLICE_DATA_PARTITION_A_NUT:
    case CODED_SLICE_DATA_PARTITION_B_NUT:
    case CODED_SLICE_DATA_PARTITION_C_NUT:
      // unimplemented
      break;
    case CODED_SLICE_OF_IDR_PICTURE_NUT: {
      // slice_layer_without_partitioning_rbsp()
      nal_unit_payload->slice_layer_without_partitioning_rbsp =
          H264SliceLayerWithoutPartitioningRbspParser::
              ParseSliceLayerWithoutPartitioningRbsp(
                  bit_buffer, nal_unit_header.nal_ref_idc,
                  nal_unit_header.nal_unit_type, bitstream_parser_state);
      break;
    }
    case SEI_NUT:
      // unimplemented
      break;
    case SPS_NUT: {
      // seq_parameter_set_rbsp()
      nal_unit_payload->sps = H264SpsParser::ParseSps(bit_buffer);
      if (nal_unit_payload->sps != nullptr) {
        uint32_t sps_id = nal_unit_payload->sps->sps_data->seq_parameter_set_id;
        bitstream_parser_state->sps[sps_id] = nal_unit_payload->sps;
      }
      break;
    }
    case PPS_NUT: {
      // pic_parameter_set_rbsp()
      // TODO(chemag): Fix this
      // This is a big pita in the h264 standard. The dependency on
      // this field (`chroma_format_idc`, defined in the SPS) forces the
      // parser to pass the full SPS map to the PPS parser: This would
      // allow the PPS parser to first read the `seq_parameter_set_id`
      // field, and then uses it with the SPS map to get the right
      // `chroma_format_idc` value tp use.
      // Unfortunately the SPS map is part of the BitstreamParserState,
      // which itself depends on the PPS. This creates a circular
      // dependency.
      // A better solution would be to pass the SPS map to the PPS
      // parser. This increases significantly the complexity of the
      // parser, and the usage of the `chroma_format_idc` field
      // For now, let's use the most common value, which corresponds
      // to 4:2:0 subsampling.
      uint32_t chroma_format_idc = 1;
      nal_unit_payload->pps =
          H264PpsParser::ParsePps(bit_buffer, chroma_format_idc);
      if (nal_unit_payload->pps != nullptr) {
        uint32_t pps_id = nal_unit_payload->pps->pic_parameter_set_id;
        bitstream_parser_state->pps[pps_id] = nal_unit_payload->pps;
      }
      break;
    }
    case AUD_NUT:
    case EOSEQ_NUT:
    case EOSTREAM_NUT:
    case FILLER_DATA_NUT:
    case SPS_EXTENSION_NUT:
      // unimplemented
      break;
    case PREFIX_NUT: {
      // prefix_nal_unit_rbsp()
      if (nal_unit_header.svc_extension_flag &&
          nal_unit_header.nal_unit_header_svc_extension != nullptr) {
        uint32_t use_ref_base_pic_flag =
            nal_unit_header.nal_unit_header_svc_extension
                ->use_ref_base_pic_flag;
        uint32_t idr_flag =
            nal_unit_header.nal_unit_header_svc_extension->idr_flag;
        nal_unit_payload->prefix_nal_unit =
            H264PrefixNalUnitRbspParser::ParsePrefixNalUnitRbsp(
                bit_buffer, nal_unit_header.svc_extension_flag,
                nal_unit_header.nal_ref_idc, use_ref_base_pic_flag, idr_flag);
      }
      break;
    }
    case SUBSET_SPS_NUT: {
      // subset_seq_parameter_set_rbsp()
      nal_unit_payload->subset_sps =
          H264SubsetSpsParser::ParseSubsetSps(bit_buffer);
      // add subset_sps to bitstream_parser_state->subset_sps
      if (nal_unit_payload->subset_sps != nullptr) {
        uint32_t subset_sps_id =
            nal_unit_payload->subset_sps->seq_parameter_set_data
                ->seq_parameter_set_id;
        bitstream_parser_state->subset_sps[subset_sps_id] =
            nal_unit_payload->subset_sps;
      }
      break;
    }
    case RSV16_NUT:
    case RSV17_NUT:
    case RSV18_NUT:
      // reserved
      break;
    case CODED_SLICE_OF_AUXILIARY_CODED_PICTURE_NUT:
      // unimplemented
      break;
    case CODED_SLICE_EXTENSION:
      // slice_layer_extension_rbsp()
      nal_unit_payload->slice_layer_extension_rbsp =
          H264SliceLayerExtensionRbspParser::ParseSliceLayerExtensionRbsp(
              bit_buffer, nal_unit_header, bitstream_parser_state);
      break;
    case RSV21_NUT:
    case RSV22_NUT:
    case RSV23_NUT:
      // reserved
      break;
    case UNSPECIFIED_NUT:
    case UNSPEC24_NUT:
    case UNSPEC25_NUT:
    case UNSPEC26_NUT:
    case UNSPEC27_NUT:
    case UNSPEC28_NUT:
    case UNSPEC29_NUT:
    case UNSPEC30_NUT:
    case UNSPEC31_NUT:
    default:
      // unspecified
      break;
  }

  return nal_unit_payload;
}

#ifdef FDUMP_DEFINE
void H264NalUnitPayloadParser::NalUnitPayloadState::fdump(
    FILE* outfp, int indent_level, uint32_t nal_unit_type) const {
  fprintf(outfp, "nal_unit_payload {");
  indent_level = indent_level_incr(indent_level);

  fdump_indent_level(outfp, indent_level);
  switch (nal_unit_type) {
    case CODED_SLICE_OF_NON_IDR_PICTURE_NUT:
      if (slice_layer_without_partitioning_rbsp) {
        slice_layer_without_partitioning_rbsp->fdump(outfp, indent_level);
      }
      break;
    case CODED_SLICE_DATA_PARTITION_A_NUT:
    case CODED_SLICE_DATA_PARTITION_B_NUT:
    case CODED_SLICE_DATA_PARTITION_C_NUT:
      // unimplemented
      break;
    case CODED_SLICE_OF_IDR_PICTURE_NUT:
      if (slice_layer_without_partitioning_rbsp) {
        slice_layer_without_partitioning_rbsp->fdump(outfp, indent_level);
      }
      break;
    case SEI_NUT:
      // unimplemented
      break;
    case SPS_NUT:
      if (sps) {
        sps->fdump(outfp, indent_level);
      }
      break;
    case PPS_NUT:
      if (pps) {
        pps->fdump(outfp, indent_level);
      }
      break;
    case AUD_NUT:
    case EOSEQ_NUT:
    case EOSTREAM_NUT:
    case FILLER_DATA_NUT:
    case SPS_EXTENSION_NUT:
      // unimplemented
      break;
    case PREFIX_NUT:
      if (prefix_nal_unit) {
        prefix_nal_unit->fdump(outfp, indent_level);
      }
      break;
    case SUBSET_SPS_NUT:
      if (subset_sps) {
        subset_sps->fdump(outfp, indent_level);
      }
      break;
    case RSV16_NUT:
    case RSV17_NUT:
    case RSV18_NUT:
      // reserved
      break;
    case CODED_SLICE_OF_AUXILIARY_CODED_PICTURE_NUT:
      // unimplemented
      break;
    case CODED_SLICE_EXTENSION:
      if (slice_layer_extension_rbsp) {
        slice_layer_extension_rbsp->fdump(outfp, indent_level);
      }
      break;
    case RSV21_NUT:
    case RSV22_NUT:
    case RSV23_NUT:
      // reserved
      break;
    case UNSPECIFIED_NUT:
    case UNSPEC24_NUT:
    case UNSPEC25_NUT:
    case UNSPEC26_NUT:
    case UNSPEC27_NUT:
    case UNSPEC28_NUT:
    case UNSPEC29_NUT:
    case UNSPEC30_NUT:
    case UNSPEC31_NUT:
    default:
      // unspecified
      break;
  }

  indent_level = indent_level_decr(indent_level);
  fdump_indent_level(outfp, indent_level);
  fprintf(outfp, "}");
}
#endif  // FDUMP_DEFINE

}  // namespace h264nal
