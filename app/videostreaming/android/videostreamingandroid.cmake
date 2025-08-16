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

# Includes:
# - project root (your code uses relative paths)
# - GStreamer headers (1.0 + glib-2.0)
# - glibconfig.h usually lives under lib/glib-2.0/include for prebuilt SDKs
target_include_directories(lowlag_android
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/vscommon
        ${CMAKE_CURRENT_SOURCE_DIR}/aarch64/include/gstreamer-1.0
        ${CMAKE_CURRENT_SOURCE_DIR}/aarch64/include/glib-2.0
        ${CMAKE_CURRENT_SOURCE_DIR}/aarch64/lib/glib-2.0/include
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/h264
)

target_compile_definitions(lowlag_android
    PUBLIC
        QOPENHD_ENABLE_VIDEO_VIA_ANDROID
)

# Qt libs (PUBLIC so consumers of this static lib inherit headers/defines)
target_link_libraries(lowlag_android
    PUBLIC
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Gui
        Qt${QT_VERSION_MAJOR}::Quick
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Multimedia
)

# Qt 5-only extras (if present)
if(QT_VERSION_MAJOR EQUAL 5)
    if(TARGET Qt5::AndroidExtras)
        target_link_libraries(lowlag_android PUBLIC Qt5::AndroidExtras)
    endif()
    if(TARGET Qt5::MultimediaWidgets)
        target_link_libraries(lowlag_android PUBLIC Qt5::MultimediaWidgets)
    endif()
endif()

# Qt 6 uses a private header for QSGSimpleMaterial; add QuickPrivate to includes/link
if(QT_VERSION_MAJOR EQUAL 6)
    target_link_libraries(lowlag_android PRIVATE Qt6::QuickPrivate)
endif()

# Android system libs needed for JNI + MediaCodec + GL calls
if(ANDROID)
    target_link_libraries(lowlag_android
        PRIVATE
            android
            mediandk
            EGL
            GLESv2
    )
endif()
