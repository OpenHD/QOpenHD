cmake_minimum_required(VERSION 3.16)
project(qmlglsink LANGUAGES C CXX)

# --- Qt6 ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui OpenGL Qml Quick)

# --- GStreamer via pkg-config ---
find_package(PkgConfig REQUIRED)

# On Android, point pkg-config at the Android GStreamer prefix so IMPORTED targets are created.
# Prefer an env var (GSTREAMER_ROOT_ANDROID) but keep your original fallback.
if(ANDROID)
  # Allow override from CI
  if(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
    set(GSTREAMER_ROOT "$ENV{GSTREAMER_ROOT_ANDROID}")
  else()
    # Your original default
    set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/aarch64")
  endif()

  # Collect possible pkg-config dirs (different layouts exist)
  set(_GST_PC_DIRS)
  foreach(d
      "${GSTREAMER_ROOT}/lib/pkgconfig"
      "${GSTREAMER_ROOT}/lib/aarch64-linux-android/pkgconfig"
      "${GSTREAMER_ROOT}/lib/gstreamer-1.0/pkgconfig")
    if(EXISTS "${d}")
      list(APPEND _GST_PC_DIRS "${d}")
    endif()
  endforeach()

  if(_GST_PC_DIRS STREQUAL "")
    message(FATAL_ERROR
      "No pkg-config directories found under ${GSTREAMER_ROOT}. "
      "Set GSTREAMER_ROOT_ANDROID to your Android GStreamer prefix.")
  endif()

  # Make pkg-config use ONLY the Android pc files (don’t mix host)
  set(ENV{PKG_CONFIG_DIR} "")
  set(ENV{PKG_CONFIG_SYSROOT_DIR} "")
  string(JOIN ":" _GST_PC_PATH ${_GST_PC_DIRS})
  set(ENV{PKG_CONFIG_LIBDIR} "${_GST_PC_PATH}")
endif()

# We only need the core modules to build qmlglsink itself.
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

# Include GStreamer headers and Qt item headers (keep your original include style)
target_include_directories(qmlglsink
  PUBLIC
    ${GSTREAMER_ROOT}/include/gstreamer-1.0
    ${GSTREAMER_ROOT}/include/glib-2.0
    ${GSTREAMER_ROOT}/lib/glib-2.0/include
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

# Quiet some warnings (optional)
if(UNIX)
  target_compile_options(qmlglsink PRIVATE
    -Wno-unused-parameter
    -Wno-implicit-fallthrough
    -Wno-unused-private-field
  )
endif()
