cmake_minimum_required(VERSION 3.16)
project(qmlglsink LANGUAGES C CXX)

# --- Qt6 ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui OpenGL Qml Quick)

# --- GStreamer via pkg-config ---
find_package(PkgConfig REQUIRED)

# We'll fill this with the imported targets to link in the end.
set(_GST_IMPORTED_TARGETS)

# Make pkg-config see the Android .pc files (and provide a fallback if none exist)
if(ANDROID)
  if(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
    set(GSTREAMER_ROOT "$ENV{GSTREAMER_ROOT_ANDROID}")
  else()
    set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/aarch64")
  endif()

  # Collect potential pkg-config dirs under the Android prefix
  set(_pcdirs "")
  foreach(d
      "${GSTREAMER_ROOT}/lib/pkgconfig"
      "${GSTREAMER_ROOT}/lib/aarch64-linux-android/pkgconfig"
      "${GSTREAMER_ROOT}/lib/gstreamer-1.0/pkgconfig")
    if(EXISTS "${d}")
      list(APPEND _pcdirs "${d}")
    endif()
  endforeach()
  file(GLOB _pcdirs_glob "${GSTREAMER_ROOT}/lib/*-android*/pkgconfig")
  list(APPEND _pcdirs ${_pcdirs_glob})
  if(EXISTS "${GSTREAMER_ROOT}/share/pkgconfig")
    list(APPEND _pcdirs "${GSTREAMER_ROOT}/share/pkgconfig")
  endif()
  list(REMOVE_DUPLICATES _pcdirs)

  if(_pcdirs)
    # Use LIBDIR (not PATH) so we don't mix host pc files
    set(ENV{PKG_CONFIG_DIR} "")
    set(ENV{PKG_CONFIG_SYSROOT_DIR} "")
    string(JOIN ":" _pcpath ${_pcdirs})
    set(ENV{PKG_CONFIG_LIBDIR} "${_pcpath}")

    # Create imported targets – one per package (names become PkgConfig::GSTREAMER*)
    pkg_check_modules(GSTREAMER       REQUIRED IMPORTED_TARGET gstreamer-1.0)
    pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
    pkg_check_modules(GSTREAMER_GL    REQUIRED IMPORTED_TARGET gstreamer-gl-1.0)

    set(_GST_IMPORTED_TARGETS
      PkgConfig::GSTREAMER
      PkgConfig::GSTREAMER_VIDEO
      PkgConfig::GSTREAMER_GL)
  else()
    message(WARNING
      "No GStreamer .pc files under ${GSTREAMER_ROOT}; "
      "falling back to manual libraries/includes")

    # Manual includes from your Android prefix
    set(_GST_INC
      "${GSTREAMER_ROOT}/include/gstreamer-1.0"
      "${GSTREAMER_ROOT}/include/glib-2.0"
      "${GSTREAMER_ROOT}/lib/glib-2.0/include")

    # Locate the needed libs directly
    find_library(_LIB_GSTREAMER       NAMES gstreamer-1.0       HINTS "${GSTREAMER_ROOT}/lib")
    find_library(_LIB_GSTREAMER_VIDEO NAMES gstreamer-video-1.0 HINTS "${GSTREAMER_ROOT}/lib")
    find_library(_LIB_GSTREAMER_GL    NAMES gstreamer-gl-1.0    HINTS "${GSTREAMER_ROOT}/lib")
    find_library(_LIB_GOBJECT         NAMES gobject-2.0         HINTS "${GSTREAMER_ROOT}/lib")
    find_library(_LIB_GLIB            NAMES glib-2.0            HINTS "${GSTREAMER_ROOT}/lib")

    foreach(_req _LIB_GSTREAMER _LIB_GSTREAMER_VIDEO _LIB_GSTREAMER_GL _LIB_GOBJECT _LIB_GLIB)
      if(NOT ${_req})
        message(FATAL_ERROR "Missing ${_req} in ${GSTREAMER_ROOT}/lib")
      endif()
    endforeach()

    # Mimic pkg-config imported targets so the rest of the file stays unchanged
    add_library(PkgConfig::GSTREAMER       INTERFACE IMPORTED)
    add_library(PkgConfig::GSTREAMER_VIDEO INTERFACE IMPORTED)
    add_library(PkgConfig::GSTREAMER_GL    INTERFACE IMPORTED)

    set_target_properties(PkgConfig::GSTREAMER
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")
    set_target_properties(PkgConfig::GSTREAMER_VIDEO
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")
    set_target_properties(PkgConfig::GSTREAMER_GL
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")

    target_link_libraries(PkgConfig::GSTREAMER
      INTERFACE "${_LIB_GSTREAMER}" "${_LIB_GOBJECT}" "${_LIB_GLIB}")
    target_link_libraries(PkgConfig::GSTREAMER_VIDEO
      INTERFACE "${_LIB_GSTREAMER_VIDEO}" "${_LIB_GOBJECT}" "${_LIB_GLIB}")
    target_link_libraries(PkgConfig::GSTREAMER_GL
      INTERFACE "${_LIB_GSTREAMER_GL}" "${_LIB_GOBJECT}" "${_LIB_GLIB}")

    set(_GST_IMPORTED_TARGETS
      PkgConfig::GSTREAMER
      PkgConfig::GSTREAMER_VIDEO
      PkgConfig::GSTREAMER_GL)
  endif()
else()
  # Non-Android: rely on system pkg-config as usual
  pkg_check_modules(GSTREAMER       REQUIRED IMPORTED_TARGET gstreamer-1.0)
  pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
  pkg_check_modules(GSTREAMER_GL    REQUIRED IMPORTED_TARGET gstreamer-gl-1.0)
  set(_GST_IMPORTED_TARGETS
    PkgConfig::GSTREAMER
    PkgConfig::GSTREAMER_VIDEO
    PkgConfig::GSTREAMER_GL)
endif()

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

# Include GStreamer headers (Android-only; desktop uses pkg-config includes)
target_include_directories(qmlglsink
  PUBLIC
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/gstreamer-1.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/glib-2.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/lib/glib-2.0/include>
    ${CMAKE_CURRENT_LIST_DIR}/qt6
)

# Link Qt + GStreamer via imported targets (pkg-config or manual fallback)
target_link_libraries(qmlglsink
  PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::OpenGL
    Qt6::Qml
    Qt6::Quick
    ${_GST_IMPORTED_TARGETS}
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
