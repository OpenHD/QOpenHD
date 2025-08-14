set(H264_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/h264_bitstream_parser.cc
    ${CMAKE_CURRENT_LIST_DIR}/h264_common.cc
    ${CMAKE_CURRENT_LIST_DIR}/pps_parser.cc
    ${CMAKE_CURRENT_LIST_DIR}/sps_parser.cc
    ${CMAKE_CURRENT_LIST_DIR}/bit_buffer.cc
    ${CMAKE_CURRENT_LIST_DIR}/checks.cc
    ${CMAKE_CURRENT_LIST_DIR}/zero_memory.cc
)

target_sources(QOpenHD PRIVATE ${H264_SOURCES})

target_include_directories(QOpenHD
    PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}
)
