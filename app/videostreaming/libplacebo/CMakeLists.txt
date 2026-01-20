# SPDX-License-Identifier: MIT
# CMake configuration for libplacebo video rendering

set(LIBPLACEBO_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/placebo_renderer.cpp
    ${CMAKE_CURRENT_LIST_DIR}/placebo_frame_queue.cpp
    ${CMAKE_CURRENT_LIST_DIR}/placebo_video_item.cpp
    ${CMAKE_CURRENT_LIST_DIR}/placebo_video_item.h
)

set(LIBPLACEBO_HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/placebo_renderer.h
    ${CMAKE_CURRENT_LIST_DIR}/placebo_frame_queue.h
    ${CMAKE_CURRENT_LIST_DIR}/placebo_video_item.h
)
