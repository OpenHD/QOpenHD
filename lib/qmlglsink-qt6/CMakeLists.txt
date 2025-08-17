cmake_minimum_required(VERSION 3.16)
project(qmlglsink LANGUAGES C CXX)

# --- Qt6 ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui OpenGL Qml Quick)

# --- GStreamer via pkg-config ---
find_package(PkgConfig REQUIRED)

# Make pkg-config see the Android .pc files
if(ANDROID)
  if(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
    set(GSTREAMER_ROOT "$ENV{GSTREAMER_ROOT_ANDROID}")
  else()
    set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/aarch64")
  endif()

  # Use LIBDIR (not PATH) to avoid mixing host pc files
  set(ENV{PKG_CONFIG_DIR} "")
  set(ENV{PKG_CONFIG_SYSROOT_DIR} "")
  set(_pcdirs "")
  foreach(d
      "${GSTREAMER_ROOT}/lib/pkgconfig"
      "${GSTREAMER_ROOT}/lib/aarch64-linux-android/pkgconfig"
      "${GSTREAMER_ROOT}/lib/gstreamer-1.0/pkgconfig")
    if(EXISTS "${d}")
      list(APPEND _pcdirs "${d}")
    endif()
  endforeach()
  if(NOT _pcdirs)
    message(FATAL_ERROR "No GStreamer .pc files under ${GSTREAMER_ROOT}")
  endif()
  string(JOIN ":" _pcpath ${_pcdirs})
  set(ENV{PKG_CONFIG_LIBDIR} "${_pcpath}")
endif()

# Create imported targets – one per package (names become PkgConfig::GSTREAMER*, note the caps)
pkg_check_modules(GSTREAMER       REQUIRED IMPORTED_TARGET gstreamer-1.0)
pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
pkg_check_modules(GSTREAMER_GL    REQUIRED IMPORTED_TARGET gstreamer-gl-1.0)

# --- Library with the Qt6 sources from the fork ---
qt_add_library(qmlglsink STATIC
  qt6/gstplugin.cc
  qt6/gstqml6glsink.cc
  qt6/gstqml6glsink.h
  qt6/gstqsg6glnode.cc
  qt6/gstqsg6glnode.h
  qt6/gstqt6element.cc
  qt6/gstqt6elements.h
  qt6/gstqt6gl.h
  qt6/gstqt6glutility.cc
  qt6/gstqt6glutility.h
  qt6/qt6glitem.cc
  qt6/qt6glitem.h
)

target_compile_features(qmlglsink PUBLIC cxx_std_17)

# Include GStreamer headers and Qt item headers (Android-only for the gst includes)
target_include_directories(qmlglsink
  PUBLIC
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/gstreamer-1.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/glib-2.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/lib/glib-2.0/include>
    ${CMAKE_CURRENT_LIST_DIR}/qt6
)

# Link Qt + GStreamer via the IMPORTED targets created above
target_link_libraries(qmlglsink
  PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::OpenGL
    Qt6::Qml
    Qt6::Quick
    PkgConfig::GSTREAMER
    PkgConfig::GSTREAMER_VIDEO
    PkgConfig::GSTREAMER_GL
)

# Platform switches (match your original fork’s defines)
target_compile_definitions(qmlglsink
  PRIVATE
    HAVE_QT_QPA_HEADER
    QT_QPA_HEADER=<QtGui/qpa/qplatformnativeinterface.h>
  PUBLIC
    QGC_GST_STREAMING
    QGC_CMAKE_GST
)

# Android GL/EGL/NDK libs
if(ANDROID)
  target_link_libraries(qmlglsink PRIVATE EGL GLESv2 android)
  target_compile_definitions(qmlglsink PRIVATE HAVE_QT_ANDROID)
elseif(UNIX AND NOT APPLE)
  target_compile_definitions(qmlglsink PRIVATE HAVE_QT_X11)
endif()

# Quiet some warnings (optional)
if(UNIX)
  target_compile_options(qmlglsink PRIVATE
    -Wno-unused-parameter
    -Wno-implicit-fallthrough
    -Wno-unused-private-field
  )
endif()
