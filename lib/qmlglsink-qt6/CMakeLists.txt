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
    add_library(PkgConfig::GSTREAMER_GL    INTERFACE IMPO
