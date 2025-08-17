# app/videostreaming/android/videostreamingandroid.cmake
# Only run this on Android builds
if(NOT ANDROID)
    message(STATUS "Android video streaming: skipped (NOT ANDROID)")
    return()
endif()

message(STATUS "Enabling video streaming support (Android)")

# --- Resolve GStreamer prefix (prefer repo's aarch64, else env override) ---
if(EXISTS "${CMAKE_SOURCE_DIR}/aarch64/include/gstreamer-1.0")
    set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/aarch64")
elseif(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
    set(GSTREAMER_ROOT "$ENV{GSTREAMER_ROOT_ANDROID}")
else()
    message(FATAL_ERROR
        "Could not find GStreamer Android prefix. "
        "Add ${CMAKE_SOURCE_DIR}/aarch64 or set GSTREAMER_ROOT_ANDROID to your prefix.")
endif()
message(STATUS "Android video: using GStreamer prefix: ${GSTREAMER_ROOT}")

# --- Make sure pkg-config sees the prefix's .pc files ---
find_package(PkgConfig REQUIRED)
# Avoid host pollution
set(ENV{PKG_CONFIG_DIR} "")
set(ENV{PKG_CONFIG_SYSROOT_DIR} "")

set(_pcdirs "")
foreach(d
    "${GSTREAMER_ROOT}/lib/pkgconfig"
    "${GSTREAMER_ROOT}/share/pkgconfig"
    "${GSTREAMER_ROOT}/lib/gstreamer-1.0/pkgconfig"
    "${GSTREAMER_ROOT}/lib/aarch64-linux-android/pkgconfig"
    "${GSTREAMER_ROOT}/lib/arm64-v8a/pkgconfig"
)
  if(EXISTS "${d}")
    list(APPEND _pcdirs "${d}")
  endif()
endforeach()
if(NOT _pcdirs)
  message(FATAL_ERROR "No pkg-config directories found under ${GSTREAMER_ROOT}")
endif()
string(JOIN ":" _pcpath ${_pcdirs})
set(ENV{PKG_CONFIG_LIBDIR} "${_pcpath}")
message(STATUS "PKG_CONFIG_LIBDIR=${_pcpath}")

# --- Make the old qmake DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID equivalent ---
option(QOPENHD_ENABLE_VIDEO_VIA_ANDROID "Enable Android low-latency video path" ON)

# --- lowlag_android library ---
set(LOWLAG_SOURCES
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/lowlagdecoder.cpp
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/qandroidmediaplayer.cpp
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/qsurfacetexture.cpp
    ${CMAKE_SOURCE_DIR}/app/videostreaming/gstreamer/gstrtpreceiver.cpp
)
set(LOWLAG_HEADERS
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/lowlagdecoder.h
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/qandroidmediaplayer.h
    ${CMAKE_SOURCE_DIR}/app/videostreaming/android/qsurfacetexture.h
    ${CMAKE_SOURCE_DIR}/app/videostreaming/vscommon/nalu/NALU.hpp
)

# Ensure Qt Multimedia is available in this scope (top-level may not have asked for it)
if(NOT TARGET Qt6::Multimedia AND NOT TARGET Qt5::Multimedia)
  find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Multimedia)
  find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Multimedia)
endif()

add_library(lowlag_android STATIC ${LOWLAG_SOURCES} ${LOWLAG_HEADERS})
set_target_properties(lowlag_android PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    AUTOMOC ON AUTORCC ON AUTOUIC ON
    POSITION_INDEPENDENT_CODE ON
)

target_include_directories(lowlag_android
    PUBLIC
        ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/app
        ${CMAKE_SOURCE_DIR}/app/videostreaming
        ${CMAKE_SOURCE_DIR}/app/videostreaming/vscommon
        ${CMAKE_SOURCE_DIR}/app/videostreaming/gstreamer
        ${CMAKE_SOURCE_DIR}/lib
        ${CMAKE_SOURCE_DIR}/lib/h264
        # GStreamer headers
        ${GSTREAMER_ROOT}/include/gstreamer-1.0
        ${GSTREAMER_ROOT}/include/glib-2.0
        ${GSTREAMER_ROOT}/lib/glib-2.0/include
)

if(QOPENHD_ENABLE_VIDEO_VIA_ANDROID)
    target_compile_definitions(lowlag_android PUBLIC QOPENHD_ENABLE_VIDEO_VIA_ANDROID)
    target_compile_definitions(QOpenHD      PRIVATE QOPENHD_ENABLE_VIDEO_VIA_ANDROID)
    message(STATUS "QOPENHD_ENABLE_VIDEO_VIA_ANDROID = ON")
else()
    message(STATUS "QOPENHD_ENABLE_VIDEO_VIA_ANDROID = OFF")
endif()

# Link to Qt that top-level already found
if(QT_VERSION_MAJOR EQUAL 6)
    target_link_libraries(lowlag_android PUBLIC Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::Multimedia)
elseif(QT_VERSION_MAJOR EQUAL 5)
    target_link_libraries(lowlag_android PUBLIC Qt5::Core Qt5::Gui Qt5::Quick Qt5::Qml Qt5::Multimedia)
endif()

# Scenegraph private (if available)
if(TARGET Qt6::QuickPrivate)
    target_link_libraries(lowlag_android PRIVATE Qt6::QuickPrivate)
endif()
# Android NDK libs
target_link_libraries(lowlag_android PRIVATE android mediandk EGL GLESv2)

# --- qmlglsink ---
add_subdirectory(${CMAKE_SOURCE_DIR}/lib/qmlglsink-qt6)

# --- App wiring ---
target_link_libraries(QOpenHD PRIVATE qmlglsink lowlag_android)

# Make sure the app sees GStreamer headers too
target_include_directories(QOpenHD PRIVATE
    ${GSTREAMER_ROOT}/include/gstreamer-1.0
    ${GSTREAMER_ROOT}/include/glib-2.0
    ${GSTREAMER_ROOT}/lib/glib-2.0/include
)

# Library search dirs (helpful on some layouts)
target_link_directories(QOpenHD PRIVATE
    ${GSTREAMER_ROOT}/lib
    ${GSTREAMER_ROOT}/lib64
    ${GSTREAMER_ROOT}/lib/arm64-v8a
    ${GSTREAMER_ROOT}/lib/aarch64-linux-android
)

# --- Link GStreamer (prefer gst-full; fallback to split pc files) ---
# Try gst-full (single static library with registrants)
pkg_check_modules(GSTFULL QUIET IMPORTED_TARGET gstreamer-full-1.0)
if(TARGET PkgConfig::GSTFULL)
    message(STATUS "Linking against gstreamer-full-1.0")
    target_link_libraries(QOpenHD PRIVATE PkgConfig::GSTFULL)
else()
    message(WARNING "gstreamer-full-1.0 not found via pkg-config. Falling back to split packages.")
    # Split packages
    pkg_check_modules(GSTREAMER      REQUIRED IMPORTED_TARGET gstreamer-1.0)
    pkg_check_modules(GSTREAMER_BASE QUIET    IMPORTED_TARGET gstreamer-base-1.0)   # sometimes needed transitively
    pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
    pkg_check_modules(GSTREAMER_GL   QUIET    IMPORTED_TARGET gstreamer-gl-1.0)
    pkg_check_modules(GSTREAMER_APP  REQUIRED IMPORTED_TARGET gstreamer-app-1.0)    # for gst_app_sink_*

    target_link_libraries(QOpenHD PRIVATE
        PkgConfig::GSTREAMER
        $<$<TARGET_EXISTS:PkgConfig::GSTREAMER_BASE>:PkgConfig::GSTREAMER_BASE>
        PkgConfig::GSTREAMER_VIDEO
        $<$<TARGET_EXISTS:PkgConfig::GSTREAMER_GL>:PkgConfig::GSTREAMER_GL>
        PkgConfig::GSTREAMER_APP
    )
endif()
