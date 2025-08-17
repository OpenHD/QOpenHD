cmake_minimum_required(VERSION 3.16)
project(qmlglsink LANGUAGES C CXX)

# --- Qt6 ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui OpenGL Qml Quick)

# --- GStreamer via pkg-config ---
find_package(PkgConfig REQUIRED)

# On Android in your CI, the GStreamer root is the "aarch64" folder you download/extract.
# (We use CMAKE_SOURCE_DIR because this subdir is added from the QOpenHD top-level.)
if(ANDROID)
  set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/aarch64")
  if(NOT EXISTS "${GSTREAMER_ROOT}/lib/pkgconfig")
    message(FATAL_ERROR "GSTREAMER_ROOT not found at ${GSTREAMER_ROOT}")
  endif()
  # Make sure pkg-config can find the .pc files
  set(ENV{PKG_CONFIG_PATH}
      "${GSTREAMER_ROOT}/lib/pkgconfig:${GSTREAMER_ROOT}/lib/gstreamer-1.0/pkgconfig:$ENV{PKG_CONFIG_PATH}")
endif()

# We only need the core modules to build qmlglsink itself.
# (The runtime set of plugins/codecs you use in pipelines is separate.)
pkg_check_modules(GST REQUIRED IMPORTED_TARGET
  gstreamer-1.0
  gstreamer-video-1.0
  gstreamer-gl-1.0
)

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

# Include GStreamer headers and Qt item headers
target_include_directories(qmlglsink
  PUBLIC
    ${GSTREAMER_ROOT}/include/gstreamer-1.0
    ${GSTREAMER_ROOT}/include/glib-2.0
    ${GSTREAMER_ROOT}/lib/glib-2.0/include
    ${CMAKE_CURRENT_LIST_DIR}/qt6
)

# Link Qt + GStreamer. We use the IMPORTED_TARGETs from pkg-config.
target_link_libraries(qmlglsink
  PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::OpenGL
    Qt6::Qml
    Qt6::Quick
    PkgConfig::gstreamer-1.0
    PkgConfig::gstreamer-video-1.0
    PkgConfig::gstreamer-gl-1.0
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

# Quiet some warnings if you like (your fork had these)
if(UNIX)
  target_compile_options(qmlglsink PRIVATE
    -Wno-unused-parameter
    -Wno-implicit-fallthrough
    -Wno-unused-private-field
  )
endif()
