# SPDX-License-Identifier: MIT
# CMake configuration for V4L2 video decoding pipeline

set(V4L2_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/dma_heap.cpp
    ${CMAKE_CURRENT_LIST_DIR}/dma_buffers_manager.cpp
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_decoder.cpp
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_decoder_detector.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uvgrtp_receiver.cpp
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_pipeline.cpp
    ${CMAKE_CURRENT_LIST_DIR}/V4L2Device.cpp
)

set(V4L2_HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/dma_heap.h
    ${CMAKE_CURRENT_LIST_DIR}/dma_buffers_manager.h
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_decoder.h
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_decoder_detector.h
    ${CMAKE_CURRENT_LIST_DIR}/uvgrtp_receiver.h
    ${CMAKE_CURRENT_LIST_DIR}/v4l2_pipeline.h
    ${CMAKE_CURRENT_LIST_DIR}/V4L2Device.h
)
