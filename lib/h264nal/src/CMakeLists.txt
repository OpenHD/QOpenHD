# add executable
#add_executable(main main.cc)

# link executable to webrtc library
# Since the webrtc library has public include directories
# we will use those link directories when building `main`
#target_link_libraries(main LINK_PUBLIC webrtc)

option(H264NAL_SMALL_FOOTPRINT, "xmall footprint build")

if(H264NAL_SMALL_FOOTPRINT)
  message(STATUS "src: small footprint selected")
  add_compile_definitions(SMALL_FOOTPRINT)
else()
  message(STATUS "src: normal footprint selected")
  add_compile_definitions(FDUMP_DEFINE)
  add_compile_definitions(RTP_DEFINE)
  add_compile_definitions(FPRINT_ERRORS)
endif()

if(H264NAL_SMALL_FOOTPRINT)
  add_library(h264nal
      h264_common.h h264_common.cc
      h264_sps_parser.h h264_sps_parser.cc
      h264_hrd_parameters_parser.h h264_hrd_parameters_parser.cc
      h264_vui_parameters_parser.h h264_vui_parameters_parser.cc
      h264_pps_parser.h h264_pps_parser.cc
      h264_ref_pic_list_modification_parser.h
      h264_ref_pic_list_modification_parser.cc
      h264_pred_weight_table_parser.h h264_pred_weight_table_parser.cc
      h264_dec_ref_pic_marking_parser.h
      h264_dec_ref_pic_marking_parser.cc
      h264_slice_header_parser.h h264_slice_header_parser.cc
      h264_slice_header_in_scalable_extension_parser.h h264_slice_header_in_scalable_extension_parser.cc
      h264_slice_layer_without_partitioning_rbsp_parser.h
      h264_slice_layer_without_partitioning_rbsp_parser.cc
      h264_slice_layer_extension_rbsp_parser.h
      h264_slice_layer_extension_rbsp_parser.cc
      h264_subset_sps_parser.h h264_subset_sps_parser.cc
      h264_sps_svc_extension_parser.h h264_sps_svc_extension_parser.cc
      h264_bitstream_parser_state.h h264_bitstream_parser_state.cc
      h264_bitstream_parser.h h264_bitstream_parser.cc
      h264_prefix_nal_unit_parser.h h264_prefix_nal_unit_parser.cc
      h264_nal_unit_header_svc_extension_parser.h
      h264_nal_unit_header_svc_extension_parser.cc
      h264_nal_unit_header_parser.h h264_nal_unit_header_parser.cc
      h264_nal_unit_payload_parser.h h264_nal_unit_payload_parser.cc
      h264_nal_unit_parser.h h264_nal_unit_parser.cc
)
else()
  add_library(h264nal
      h264_common.h h264_common.cc
      h264_sps_parser.h h264_sps_parser.cc
      h264_hrd_parameters_parser.h h264_hrd_parameters_parser.cc
      h264_vui_parameters_parser.h h264_vui_parameters_parser.cc
      h264_pps_parser.h h264_pps_parser.cc
      h264_ref_pic_list_modification_parser.h
      h264_ref_pic_list_modification_parser.cc
      h264_pred_weight_table_parser.h h264_pred_weight_table_parser.cc
      h264_dec_ref_pic_marking_parser.h
      h264_dec_ref_pic_marking_parser.cc
      h264_rtp_single_parser.h h264_rtp_single_parser.cc
      h264_rtp_parser.h h264_rtp_parser.cc
      h264_rtp_stapa_parser.h h264_rtp_stapa_parser.cc
      h264_rtp_fua_parser.h h264_rtp_fua_parser.cc
      h264_slice_header_parser.h h264_slice_header_parser.cc
      h264_slice_header_in_scalable_extension_parser.h h264_slice_header_in_scalable_extension_parser.cc
      h264_slice_layer_without_partitioning_rbsp_parser.h
      h264_slice_layer_without_partitioning_rbsp_parser.cc
      h264_slice_layer_extension_rbsp_parser.h
      h264_slice_layer_extension_rbsp_parser.cc
      h264_subset_sps_parser.h h264_subset_sps_parser.cc
      h264_sps_svc_extension_parser.h h264_sps_svc_extension_parser.cc
      h264_bitstream_parser_state.h h264_bitstream_parser_state.cc
      h264_bitstream_parser.h h264_bitstream_parser.cc
      h264_prefix_nal_unit_parser.h h264_prefix_nal_unit_parser.cc
      h264_nal_unit_header_svc_extension_parser.h
      h264_nal_unit_header_svc_extension_parser.cc
      h264_nal_unit_header_parser.h h264_nal_unit_header_parser.cc
      h264_nal_unit_payload_parser.h h264_nal_unit_payload_parser.cc
      h264_nal_unit_parser.h h264_nal_unit_parser.cc
)
endif()
target_include_directories(h264nal PUBLIC ../webrtc)
target_link_libraries(h264nal PUBLIC webrtc)

# https://cmake.org/cmake/help/latest/guide/tutorial/index.html#adding-a-version-number-and-configured-header-file
configure_file(config.h.in config.h)

# this allows the 'config.h' file to be used throughout the program
target_include_directories(h264nal PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")
