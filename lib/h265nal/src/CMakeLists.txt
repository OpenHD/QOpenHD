# add executable
#add_executable(main main.cc)

# link executable to webrtc library
# Since the webrtc library has public include directories
# we will use those link directories when building `main`
#target_link_libraries(main LINK_PUBLIC webrtc)

option(H265NAL_SMALL_FOOTPRINT, "xmall footprint build")

if(H265NAL_SMALL_FOOTPRINT)
  message(STATUS "src: small footprint selected")
  add_compile_definitions(SMALL_FOOTPRINT)
else()
  message(STATUS "src: normal footprint selected")
  add_compile_definitions(FDUMP_DEFINE)
  add_compile_definitions(RTP_DEFINE)
  add_compile_definitions(FPRINT_ERRORS)
endif()

if(H265NAL_SMALL_FOOTPRINT)
  add_library(h265nal
      h265_common.h h265_common.cc
      h265_utils.h h265_utils.cc
      h265_profile_tier_level_parser.h h265_profile_tier_level_parser.cc
      h265_sub_layer_hrd_parameters_parser.h h265_sub_layer_hrd_parameters_parser.cc
      h265_hrd_parameters_parser.h h265_hrd_parameters_parser.cc
      h265_vps_parser.h h265_vps_parser.cc
      h265_vui_parameters_parser.h h265_vui_parameters_parser.cc
      h265_pred_weight_table_parser.h h265_pred_weight_table_parser.cc
      h265_st_ref_pic_set_parser.h h265_st_ref_pic_set_parser.cc
      h265_sps_multilayer_extension_parser.h h265_sps_multilayer_extension_parser.cc
      h265_sps_3d_extension_parser.h h265_sps_3d_extension_parser.cc
      h265_sps_range_extension_parser.h h265_sps_range_extension_parser.cc
      h265_sps_scc_extension_parser.h h265_sps_scc_extension_parser.cc
      h265_scaling_list_data_parser.h h265_scaling_list_data_parser.cc
      h265_sps_parser.h h265_sps_parser.cc
      h265_pps_scc_extension_parser.h h265_pps_scc_extension_parser.cc
      h265_pps_parser.h h265_pps_parser.cc
      h265_aud_parser.h h265_aud_parser.cc
      h265_slice_parser.h h265_slice_parser.cc
      h265_bitstream_parser_state.h h265_bitstream_parser_state.cc
      h265_bitstream_parser.h h265_bitstream_parser.cc
      h265_nal_unit_header_parser.h h265_nal_unit_header_parser.cc
      h265_nal_unit_payload_parser.h h265_nal_unit_payload_parser.cc
      h265_nal_unit_parser.h h265_nal_unit_parser.cc
)
else()
  add_library(h265nal
      h265_common.h h265_common.cc
      h265_utils.h h265_utils.cc
      h265_profile_tier_level_parser.h h265_profile_tier_level_parser.cc
      h265_sub_layer_hrd_parameters_parser.h h265_sub_layer_hrd_parameters_parser.cc
      h265_hrd_parameters_parser.h h265_hrd_parameters_parser.cc
      h265_vps_parser.h h265_vps_parser.cc
      h265_vui_parameters_parser.h h265_vui_parameters_parser.cc
      h265_pred_weight_table_parser.h h265_pred_weight_table_parser.cc
      h265_st_ref_pic_set_parser.h h265_st_ref_pic_set_parser.cc
      h265_sps_multilayer_extension_parser.h h265_sps_multilayer_extension_parser.cc
      h265_sps_3d_extension_parser.h h265_sps_3d_extension_parser.cc
      h265_sps_range_extension_parser.h h265_sps_range_extension_parser.cc
      h265_sps_scc_extension_parser.h h265_sps_scc_extension_parser.cc
      h265_scaling_list_data_parser.h h265_scaling_list_data_parser.cc
      h265_sps_parser.h h265_sps_parser.cc
      h265_pps_scc_extension_parser.h h265_pps_scc_extension_parser.cc
      h265_pps_parser.h h265_pps_parser.cc
      h265_aud_parser.h h265_aud_parser.cc
      h265_rtp_ap_parser.h h265_rtp_ap_parser.cc
      h265_rtp_fu_parser.h h265_rtp_fu_parser.cc
      h265_rtp_single_parser.h h265_rtp_single_parser.cc
      h265_rtp_parser.h h265_rtp_parser.cc
      h265_slice_parser.h h265_slice_parser.cc
      h265_bitstream_parser_state.h h265_bitstream_parser_state.cc
      h265_bitstream_parser.h h265_bitstream_parser.cc
      h265_nal_unit_header_parser.h h265_nal_unit_header_parser.cc
      h265_nal_unit_payload_parser.h h265_nal_unit_payload_parser.cc
      h265_nal_unit_parser.h h265_nal_unit_parser.cc
)
endif()
target_include_directories(h265nal PUBLIC ../webrtc)
target_link_libraries(h265nal PUBLIC webrtc)

# https://cmake.org/cmake/help/latest/guide/tutorial/index.html#adding-a-version-number-and-configured-header-file
configure_file(config.h.in config.h)

# this allows the 'config.h' file to be used throughout the program
target_include_directories(h265nal PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")
