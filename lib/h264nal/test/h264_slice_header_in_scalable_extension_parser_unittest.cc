/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include "h264_slice_header_in_scalable_extension_parser.h"

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "h264_bitstream_parser.h"
#include "h264_bitstream_parser_state.h"
#include "h264_common.h"
#include "h264_dec_ref_pic_marking_parser.h"
#include "h264_pps_parser.h"
#include "h264_pred_weight_table_parser.h"
#include "h264_ref_pic_list_modification_parser.h"
#include "h264_sps_parser.h"
#include "rtc_base/arraysize.h"
#include "rtc_base/bit_buffer.h"

namespace h264nal {

class H264SliceHeaderInScalableExtensionParserTest : public ::testing::Test {
 public:
  H264SliceHeaderInScalableExtensionParserTest() {}
  ~H264SliceHeaderInScalableExtensionParserTest() override {}
};

// SPS, PPS, SubsetSPS, PPS, IDR, slice_layer_extension_rbsp (foreman.svc.264)
// fuzzer::conv: data
const uint8_t buffer_global[] = {
    // SPS
    0x00, 0x00, 0x00, 0x01,
    0x67, 0x42, 0x00, 0x0a, 0xa6, 0x82, 0xc4, 0xe4,
    // PPS (0)
    0x00, 0x00, 0x00, 0x01,
    0x68, 0xce, 0x07, 0x72,
    // SubsetSPS
    0x00, 0x00, 0x00, 0x01,
    0x6f, 0x53, 0x00, 0x0b, 0xac, 0x4d, 0x02, 0xc1,
    0x2c, 0x81, 0x20,
    // PPS (1)
    0x00, 0x00, 0x00, 0x01,
    0x68, 0x53, 0x81, 0xdc, 0x80,
    // slice (IDR)
    0x00, 0x00, 0x00, 0x01,
    0x65, 0xb8, 0x11, 0x7e, 0x20, 0xe2, 0xf8, 0x08,
    0x3e, 0xef, 0xc0, 0x08, 0x4c,
    // slice_layer_extension_rbsp
    0x00, 0x00, 0x00, 0x01,
    0x74, 0xc0, 0x90, 0x0f, 0xb4, 0x04, 0x5f, 0xc0,
    0xc4, 0x42, 0x00, 0x04, 0xe0, 0xcf, 0xc0, 0xf8,
    0x00, 0x1a, 0x64, 0x05, 0x63, 0xfb, 0x13, 0x9f
};

TEST_F(H264SliceHeaderInScalableExtensionParserTest, TestSampleBitstream01) {
  // fuzzer::conv: begin
  // init the BitstreamParserState
  H264BitstreamParserState bitstream_parser_state;

  auto bitstream = H264BitstreamParser::ParseBitstream(
      buffer_global, arraysize(buffer_global), &bitstream_parser_state,
      /* add_checksum */ true);
  // fuzzer::conv: end

  EXPECT_TRUE(bitstream != nullptr);

  // check there are 6 NAL units
  EXPECT_EQ(6, bitstream->nal_units.size());

  // check the 1st NAL unit
  int index = 0;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the 2nd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the 3rd NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SUBSET_SPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the 4th NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::PPS_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the 5th NAL unit
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the 6th NAL unit (slice_header_in_scalable_extension())
  index += 1;
  EXPECT_EQ(0,
            bitstream->nal_units[index]->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, bitstream->nal_units[index]->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::CODED_SLICE_EXTENSION,
            bitstream->nal_units[index]->nal_unit_header->nal_unit_type);

  // check the slice_header_in_scalable_extension contents
  auto& nal_unit_header = bitstream->nal_units[index]->nal_unit_header;
  ASSERT_TRUE(nal_unit_header != nullptr);
  EXPECT_EQ(1, nal_unit_header->svc_extension_flag);
  EXPECT_EQ(0, nal_unit_header->avc_3d_extension_flag);
  auto& nal_unit_header_svc_extension =
      nal_unit_header->nal_unit_header_svc_extension;
  ASSERT_TRUE(nal_unit_header_svc_extension != nullptr);
  EXPECT_EQ(1, nal_unit_header_svc_extension->idr_flag);
  EXPECT_EQ(0, nal_unit_header_svc_extension->priority_id);
  EXPECT_EQ(1, nal_unit_header_svc_extension->no_inter_layer_pred_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->dependency_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->quality_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->temporal_id);
  EXPECT_EQ(0, nal_unit_header_svc_extension->use_ref_base_pic_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->discardable_flag);
  EXPECT_EQ(1, nal_unit_header_svc_extension->output_flag);
  EXPECT_EQ(3, nal_unit_header_svc_extension->reserved_three_2bits);

  auto& nal_unit_payload = bitstream->nal_units[index]->nal_unit_payload;
  ASSERT_TRUE(nal_unit_payload != nullptr);

  auto& slice_layer_extension_rbsp =
      nal_unit_payload->slice_layer_extension_rbsp;
  ASSERT_TRUE(slice_layer_extension_rbsp != nullptr);

  auto& slice_header_in_scalable_extension =
      slice_layer_extension_rbsp->slice_header_in_scalable_extension;
  ASSERT_TRUE(slice_header_in_scalable_extension != nullptr);
  EXPECT_EQ(0, slice_header_in_scalable_extension->first_mb_in_slice);
  EXPECT_EQ(2, slice_header_in_scalable_extension->slice_type);
  EXPECT_EQ(1, slice_header_in_scalable_extension->pic_parameter_set_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->colour_plane_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->frame_num);
  EXPECT_EQ(0, slice_header_in_scalable_extension->field_pic_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->bottom_field_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->idr_pic_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension->pic_order_cnt_lsb);
  EXPECT_EQ(0, slice_header_in_scalable_extension->delta_pic_order_cnt_bottom);
  EXPECT_EQ(0, slice_header_in_scalable_extension->delta_pic_order_cnt.size());
  EXPECT_EQ(0, slice_header_in_scalable_extension->direct_spatial_mv_pred_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->num_ref_idx_active_override_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->num_ref_idx_l0_active_minus1);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->num_ref_idx_l1_active_minus1);
  // ref_pic_list_modification()
  auto& ref_pic_list_modification =
      slice_header_in_scalable_extension->ref_pic_list_modification;
  ASSERT_TRUE(ref_pic_list_modification != nullptr);
  EXPECT_EQ(2, ref_pic_list_modification->slice_type);
  EXPECT_EQ(0, ref_pic_list_modification->ref_pic_list_modification_flag_l0);
  EXPECT_EQ(0, ref_pic_list_modification->modification_of_pic_nums_idc.size());
  EXPECT_EQ(0, ref_pic_list_modification->abs_diff_pic_num_minus1.size());
  EXPECT_EQ(0, ref_pic_list_modification->long_term_pic_num.size());
  EXPECT_EQ(0, ref_pic_list_modification->ref_pic_list_modification_flag_l1);

  EXPECT_EQ(0, slice_header_in_scalable_extension->base_pred_weight_table_flag);
  EXPECT_EQ(nullptr, slice_header_in_scalable_extension->pred_weight_table);

  // dec_ref_pic_marking()
  auto& dec_ref_pic_marking =
      slice_header_in_scalable_extension->dec_ref_pic_marking;
  ASSERT_TRUE(dec_ref_pic_marking != nullptr);
  EXPECT_EQ(20, dec_ref_pic_marking->nal_unit_type);
  EXPECT_EQ(0, dec_ref_pic_marking->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_reference_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag);
  EXPECT_EQ(0, dec_ref_pic_marking->memory_management_control_operation.size());
  EXPECT_EQ(0, dec_ref_pic_marking->difference_of_pic_nums_minus1.size());
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_pic_num.size());
  EXPECT_EQ(0, dec_ref_pic_marking->long_term_frame_idx.size());
  EXPECT_EQ(0, dec_ref_pic_marking->max_long_term_frame_idx_plus1.size());

  EXPECT_EQ(0, slice_header_in_scalable_extension->store_ref_base_pic_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->cabac_init_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_qp_delta);
  EXPECT_EQ(10,
            slice_header_in_scalable_extension->disable_deblocking_filter_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_alpha_c0_offset_div2);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_beta_offset_div2);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_group_change_cycle);
  EXPECT_EQ(0, slice_header_in_scalable_extension->ref_layer_dq_id);
  EXPECT_EQ(0, slice_header_in_scalable_extension
                   ->disable_inter_layer_deblocking_filter_idc);
  EXPECT_EQ(0, slice_header_in_scalable_extension
                   ->inter_layer_slice_alpha_c0_offset_div2);
  EXPECT_EQ(
      49,
      slice_header_in_scalable_extension->inter_layer_slice_beta_offset_div2);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->constrained_intra_resampling_flag);
  EXPECT_EQ(
      0,
      slice_header_in_scalable_extension->ref_layer_chroma_phase_x_plus1_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->ref_layer_chroma_phase_y_plus1);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_left_offset);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scaled_ref_layer_top_offset);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_right_offset);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->scaled_ref_layer_bottom_offset);
  EXPECT_EQ(0, slice_header_in_scalable_extension->slice_skip_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->num_mbs_in_slice_minus1);
  EXPECT_EQ(1, slice_header_in_scalable_extension->adaptive_base_mode_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->default_base_mode_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->adaptive_motion_prediction_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->default_motion_prediction_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->adaptive_residual_prediction_flag);
  EXPECT_EQ(
      0, slice_header_in_scalable_extension->default_residual_prediction_flag);
  EXPECT_EQ(0,
            slice_header_in_scalable_extension->tcoeff_level_prediction_flag);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scan_idx_start);
  EXPECT_EQ(0, slice_header_in_scalable_extension->scan_idx_end);
}

#if 0
TEST_F(H264SliceHeaderInScalableExtensionParserTest, TestSampleNalUnit) {

  // fuzzer::conv: data
  const uint8_t buffer[] = {
       0x65, 0x05, 0xae, 0x04, 0x5f, 0xc3, 0xe0, 0x00,
       0xee, 0xfc, 0xf0, 0x34, 0x10, 0xf4, 0x99, 0xcf,
       0xc7, 0x33, 0x20, 0x8d, 0xcf, 0x31, 0x0e, 0x86,
       0x0d, 0xf3, 0x38, 0x9a, 0x7d, 0x54, 0x3e, 0x93
  };
  // fuzzer::conv: begin
  H264BitstreamParserState bitstream_parser_state;
  auto nal_unit = H264NalUnitParser::ParseNalUnit(buffer, arraysize(buffer),
                                                  &bitstream_parser_state,
                                                  /* add checksum */ true);
  // fuzzer::conv: end

  EXPECT_TRUE(nal_unit != nullptr);

  // check the parsed length
  EXPECT_EQ(1, nal_unit->parsed_length);

  // check the checksum
  EXPECT_THAT(std::vector<char>(nal_unit->checksum->GetChecksum(),
                                nal_unit->checksum->GetChecksum() +
                                    nal_unit->checksum->GetLength()),
              ::testing::ElementsAreArray({0x98, 0xff, 0xff, 0xff}));

  // test the checksum's ascii dumper
  char checksum_printable[64] = {};
  nal_unit->checksum->fdump(checksum_printable, 64);
  EXPECT_STREQ(checksum_printable, "98ffffff");

  // check the header
  EXPECT_EQ(0, nal_unit->nal_unit_header->forbidden_zero_bit);
  EXPECT_EQ(3, nal_unit->nal_unit_header->nal_ref_idc);
  EXPECT_EQ(NalUnitType::SPS_NUT, nal_unit->nal_unit_header->nal_unit_type);
}


TEST_F(H264SliceHeaderInScalableExtensionParserTest, TestSampleSliceIDR601) {
  // fuzzer::conv: data
  const uint8_t buffer[] = {
      0x88, 0x82, 0x06, 0x78, 0x8c, 0x50, 0x00, 0x1c,
      0xab, 0x8e, 0x00, 0x02, 0xfb, 0x31, 0xc0, 0x00,
      0x5f, 0x66, 0xfb, 0xef, 0xbe
  };

  // fuzzer::conv: begin
  // get some mock state
  H264BitstreamParserState bitstream_parser_state;
  auto sps = std::make_shared<H264SpsParser::SpsState>();
  sps->sps_data = std::make_unique<H264SpsDataParser::SpsDataState>();
  sps->sps_data->log2_max_frame_num_minus4 = 1;
  sps->sps_data->frame_mbs_only_flag = 1;
  sps->sps_data->pic_order_cnt_type = 2;
  sps->sps_data->delta_pic_order_always_zero_flag = 0;
  sps->sps_data->pic_width_in_mbs_minus1 = 0;
  sps->sps_data->pic_height_in_map_units_minus1 = 0;
  bitstream_parser_state.sps[0] = sps;
  auto pps = std::make_shared<H264PpsParser::PpsState>();
  pps->bottom_field_pic_order_in_frame_present_flag = 0;
  pps->redundant_pic_cnt_present_flag = 0;
  pps->weighted_pred_flag = 0;
  pps->weighted_bipred_idc = 0;
  pps->entropy_coding_mode_flag = 0;
  pps->deblocking_filter_control_present_flag = 1;
  pps->num_slice_groups_minus1 = 0;
  pps->slice_group_map_type = 0;
  pps->slice_group_change_rate_minus1 = 0;
  ;
  bitstream_parser_state.pps[0] = pps;

  H264NalUnitHeaderParser::NalUnitHeaderState nal_unit_header;
  nal_unit_header.nal_ref_idc = 3;
  nal_unit_header.nal_unit_type = NalUnitType::CODED_SLICE_OF_IDR_PICTURE_NUT;
  auto shise = H264SliceHeaderInScalableExtensionParser::ParseSliceHeaderInScalableExtension(
      buffer, arraysize(buffer), nal_unit_header,
      &bitstream_parser_state);
  // fuzzer::conv: end

  EXPECT_TRUE(shise != nullptr);

  EXPECT_EQ(0, shise->first_mb_in_slice);
  EXPECT_EQ(7, shise->slice_type);
  EXPECT_EQ(0, shise->pic_parameter_set_id);
  EXPECT_EQ(0, shise->frame_num);
  EXPECT_EQ(0, shise->field_pic_flag);
  EXPECT_EQ(0, shise->bottom_field_flag);
  EXPECT_EQ(0, shise->idr_pic_id);
  EXPECT_EQ(0, shise->pic_order_cnt_lsb);
  EXPECT_EQ(0, shise->delta_pic_order_cnt_bottom);
  EXPECT_EQ(0, shise->delta_pic_order_cnt.size());
  EXPECT_EQ(0, shise->redundant_pic_cnt);
  EXPECT_EQ(0, shise->direct_spatial_mv_pred_flag);
  EXPECT_EQ(0, shise->num_ref_idx_active_override_flag);
  EXPECT_EQ(0, shise->num_ref_idx_l0_active_minus1);
  EXPECT_EQ(0, shise->num_ref_idx_l1_active_minus1);

  EXPECT_NE(nullptr, shise->ref_pic_list_modification);
  EXPECT_EQ(0, shise->ref_pic_list_modification
                   ->ref_pic_list_modification_flag_l0);
  EXPECT_EQ(0, shise->ref_pic_list_modification
                   ->ref_pic_list_modification_flag_l1);
  EXPECT_EQ(0, shise->ref_pic_list_modification
                   ->modification_of_pic_nums_idc.size());
  EXPECT_EQ(
      0,
      shise->ref_pic_list_modification->abs_diff_pic_num_minus1.size());
  EXPECT_EQ(0,
            shise->ref_pic_list_modification->long_term_pic_num.size());

  EXPECT_EQ(nullptr, shise->pred_weight_table);

  EXPECT_NE(nullptr, shise->dec_ref_pic_marking);
  EXPECT_EQ(0, shise->dec_ref_pic_marking->no_output_of_prior_pics_flag);
  EXPECT_EQ(0, shise->dec_ref_pic_marking->long_term_reference_flag);
  EXPECT_EQ(
      0, shise->dec_ref_pic_marking->adaptive_ref_pic_marking_mode_flag);
  EXPECT_EQ(0, shise->dec_ref_pic_marking
                   ->memory_management_control_operation.size());
  EXPECT_EQ(
      0,
      shise->dec_ref_pic_marking->difference_of_pic_nums_minus1.size());
  EXPECT_EQ(0, shise->dec_ref_pic_marking->long_term_pic_num.size());
  EXPECT_EQ(0, shise->dec_ref_pic_marking->long_term_frame_idx.size());
  EXPECT_EQ(
      0,
      shise->dec_ref_pic_marking->max_long_term_frame_idx_plus1.size());

  EXPECT_EQ(0, shise->cabac_init_idc);
  EXPECT_EQ(-12, shise->slice_qp_delta);
  EXPECT_EQ(0, shise->disable_deblocking_filter_idc);
  EXPECT_EQ(0, shise->slice_alpha_c0_offset_div2);
  EXPECT_EQ(0, shise->slice_beta_offset_div2);
  EXPECT_EQ(0, shise->slice_group_change_cycle);
}
#endif

}  // namespace h264nal
