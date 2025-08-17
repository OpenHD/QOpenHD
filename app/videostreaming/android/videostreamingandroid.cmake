cmake_minimum_required(VERSION 3.16)
project(LowLagAndroid LANGUAGES CXX)

# --- Sources / headers ---
set(LOWLAG_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/lowlagdecoder.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/qandroidmediaplayer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/qsurfacetexture.cpp
)

set(LOWLAG_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/lowlagdecoder.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/qandroidmediaplayer.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/android/qsurfacetexture.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/vscommon/nalu/NALU.hpp
)

# --- Qt detection (Qt 6 preferred, fallback to Qt 5) ---
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui Quick Qml Multimedia)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Quick Qml Multimedia)

if(QT_VERSION_MAJOR EQUAL 5)
    find_package(Qt5 QUIET COMPONENTS AndroidExtras MultimediaWidgets)
endif()

# Resolve GStreamer prefix for Android builds (env override supported)
if(ANDROID)
    if(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
        set(GSTREAMER_ROOT "$ENV{GSTREAMER_ROOT_ANDROID}")
    else()
        set(GSTREAMER_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/aarch64")
    endif()
endif()

add_library(lowlag_android STATIC
    ${LOWLAG_SOURCES}
    ${LOWLAG_HEADERS}
)

set_target_properties(lowlag_android PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
    POSITION_INDEPENDENT_CODE ON
)

# Includes
target_include_directories(lowlag_android
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/app
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/vscommon
        $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/gstreamer-1.0>
        $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/glib-2.0>
        $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/lib/glib-2.0/include>
        ${CMAKE_CURRENT_SOURCE_DIR}/lib
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/h264
)

target_compile_definitions(lowlag_android
    PUBLIC
        QOPENHD_ENABLE_VIDEO_VIA_ANDROID
)

target_link_libraries(lowlag_android
    PUBLIC
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Gui
        Qt${QT_VERSION_MAJOR}::Quick
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Multimedia
)

# Qt 5 extras if available
if(QT_VERSION_MAJOR EQUAL 5)
    if(TARGET Qt5::AndroidExtras)
        target_link_libraries(lowlag_android PUBLIC Qt5::AndroidExtras)
    endif()
    if(TARGET Qt5::MultimediaWidgets)
        target_link_libraries(lowlag_android PUBLIC Qt5::MultimediaWidgets)
    endif()
endif()

# Qt 6: pull in private usage requirements for scenegraph private headers
if(QT_VERSION_MAJOR EQUAL 6 AND TARGET Qt6::QuickPrivate)
    target_link_libraries(lowlag_android PRIVATE Qt6::QuickPrivate)
endif()

# Android system libs (GL/EGL/NDK)
if(ANDROID)
    target_link_libraries(lowlag_android PRIVATE android mediandk EGL GLESv2)
endif()

option(QGC_ENABLE_VIDEOSTREAMING "Enable video streaming" ON)

# Only wire up qmlglsink and GStreamer include paths when on Android and streaming is enabled
if(QGC_ENABLE_VIDEOSTREAMING AND ANDROID)
    message(STATUS "Enabling video streaming support (Android)")

    # Build qmlglsink from the forked folder (its CMake handles pkg-config env)
    add_subdirectory(${CMAKE_SOURCE_DIR}/lib/qmlglsink-qt6)

    # Make sure the app links both qmlglsink and the decoder
    target_link_libraries(QOpenHD PRIVATE qmlglsink lowlag_android)

    # Ensure the app sees the same GStreamer headers (if it includes any gst headers)
    target_include_directories(QOpenHD PRIVATE
        ${GSTREAMER_ROOT}/include/gstreamer-1.0
        ${GSTREAMER_ROOT}/include/glib-2.0
        ${GSTREAMER_ROOT}/lib/glib-2.0/include
    )
endif()
