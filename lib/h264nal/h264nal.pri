# annoying, but since qt wants their own .pri we cannot use the cmake stuff


SOURCES += \
    $$PWD/src/h264_common.h h264_common.cc
    $$PWD/src/h264_sps_parser.h h264_sps_parser.cc
    $$PWD/src/h264_hrd_parameters_parser.h h264_hrd_parameters_parser.cc
    $$PWD/src/h264_vui_parameters_parser.h h264_vui_parameters_parser.cc
    $$PWD/src/h264_pps_parser.h h264_pps_parser.cc
    $$PWD/src/h264_ref_pic_list_modification_parser.h
    $$PWD/src/h264_ref_pic_list_modification_parser.cc
    $$PWD/src/h264_pred_weight_table_parser.h h264_pred_weight_table_parser.cc
    $$PWD/src/h264_dec_ref_pic_marking_parser.h
    $$PWD/src/h264_dec_ref_pic_marking_parser.cc
    $$PWD/src/h264_slice_header_parser.h h264_slice_header_parser.cc
    $$PWD/src/h264_slice_header_in_scalable_extension_parser.h h264_slice_header_in_scalable_extension_parser.cc
    $$PWD/src/h264_slice_layer_without_partitioning_rbsp_parser.h
    $$PWD/src/h264_slice_layer_without_partitioning_rbsp_parser.cc
    $$PWD/src/h264_slice_layer_extension_rbsp_parser.h
    $$PWD/src/h264_slice_layer_extension_rbsp_parser.cc
    $$PWD/src/h264_subset_sps_parser.h h264_subset_sps_parser.cc
    $$PWD/src/h264_sps_svc_extension_parser.h h264_sps_svc_extension_parser.cc
    $$PWD/src/h264_bitstream_parser_state.h h264_bitstream_parser_state.cc
    $$PWD/src/h264_bitstream_parser.h h264_bitstream_parser.cc
    $$PWD/src/h264_prefix_nal_unit_parser.h h264_prefix_nal_unit_parser.cc
    $$PWD/src/h264_nal_unit_header_svc_extension_parser.h
    $$PWD/src/h264_nal_unit_header_svc_extension_parser.cc
    $$PWD/src/h264_nal_unit_header_parser.h h264_nal_unit_header_parser.cc
    $$PWD/src/h264_nal_unit_payload_parser.h h264_nal_unit_payload_parser.cc
    $$PWD/src/h264_nal_unit_parser.h h264_nal_unit_parser.cc
)

