cmake_minimum_required(VERSION 3.16)
project(qmlglsink LANGUAGES C CXX)

# --- Qt6 ---
find_package(Qt6 REQUIRED COMPONENTS Core Gui OpenGL Qml Quick)

# --- pkg-config (used when .pc files are present) ---
find_package(PkgConfig REQUIRED)

# Will collect imported targets for linking at the end
set(_GST_IMPORTED_TARGETS)

# -------- Robust Android prefix detection (prefers repo's aarch64) --------
if(ANDROID)
  set(_candidate_roots "")

  # 1) Prefer the repo's aarch64 prefix (your own build)
  if(EXISTS "${CMAKE_SOURCE_DIR}/aarch64/include/gstreamer-1.0")
    list(APPEND _candidate_roots "${CMAKE_SOURCE_DIR}/aarch64")
  endif()

  # 2) Then env override
  if(DEFINED ENV{GSTREAMER_ROOT_ANDROID} AND NOT "$ENV{GSTREAMER_ROOT_ANDROID}" STREQUAL "")
    list(APPEND _candidate_roots "$ENV{GSTREAMER_ROOT_ANDROID}")
  endif()

  # Pick the first candidate that has headers and a lib dir
  set(GSTREAMER_ROOT "")
  foreach(_root IN LISTS _candidate_roots)
    if(EXISTS "${_root}/include/gstreamer-1.0" AND
       (EXISTS "${_root}/lib" OR EXISTS "${_root}/lib64" OR EXISTS "${_root}/lib/arm64-v8a"))
      set(GSTREAMER_ROOT "${_root}")
      break()
    endif()
  endforeach()

  if(NOT GSTREAMER_ROOT)
    message(FATAL_ERROR
      "Could not locate a usable GStreamer Android prefix.\n"
      "Tried: ${_candidate_roots}\n"
      "Hint: ensure either ${CMAKE_SOURCE_DIR}/aarch64 or GSTREAMER_ROOT_ANDROID points to a prefix with include/ and lib/."
    )
  endif()

  message(STATUS "Using GStreamer Android prefix: ${GSTREAMER_ROOT}")

  # Candidate pkg-config directories
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
    # Use LIBDIR so we don't mix host pc files
    set(ENV{PKG_CONFIG_DIR} "")
    set(ENV{PKG_CONFIG_SYSROOT_DIR} "")
    string(JOIN ":" _pcpath ${_pcdirs})
    set(ENV{PKG_CONFIG_LIBDIR} "${_pcpath}")

    # Create imported targets – one per package (names: PkgConfig::GSTREAMER*)
    pkg_check_modules(GSTREAMER       REQUIRED IMPORTED_TARGET gstreamer-1.0)
    pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
    pkg_check_modules(GSTREAMER_GL    REQUIRED IMPORTED_TARGET gstreamer-gl-1.0)

    set(_GST_IMPORTED_TARGETS
      PkgConfig::GSTREAMER
      PkgConfig::GSTREAMER_VIDEO
      PkgConfig::GSTREAMER_GL)
  else()
    message(WARNING
      "No GStreamer .pc files under ${GSTREAMER_ROOT}; falling back to manual libraries/includes")

    # Common library roots used by Android packages
    set(_GST_LIB_SEARCH_DIRS
      "${GSTREAMER_ROOT}/lib"
      "${GSTREAMER_ROOT}/lib64"
      "${GSTREAMER_ROOT}/lib/arm64-v8a"
      "${GSTREAMER_ROOT}/arm64-v8a/lib"
      "${GSTREAMER_ROOT}/lib/aarch64-linux-android"
    )
    file(GLOB _more1 "${GSTREAMER_ROOT}/lib/*-android*/")
    file(GLOB _more2 "${GSTREAMER_ROOT}/*arm64*/lib")
    list(APPEND _GST_LIB_SEARCH_DIRS ${_more1} ${_more2})
    list(REMOVE_DUPLICATES _GST_LIB_SEARCH_DIRS)

    # Headers
    set(_GST_INC
      "${GSTREAMER_ROOT}/include/gstreamer-1.0"
      "${GSTREAMER_ROOT}/include/glib-2.0"
      "${GSTREAMER_ROOT}/lib/glib-2.0/include")

    macro(_find_gstlib OUT_VAR)
      find_library(${OUT_VAR}
        NAMES ${ARGN}
        HINTS ${_GST_LIB_SEARCH_DIRS}
      )
    endmacro()

    # Core libs (accept legacy gstreamer_android name too)
    _find_gstlib(_LIB_GSTREAMER       gstreamer-1.0 gstreamer_android)
    _find_gstlib(_LIB_GSTREAMER_VIDEO gstreamer-video-1.0)
    _find_gstlib(_LIB_GSTREAMER_GL    gstreamer-gl-1.0)
    _find_gstlib(_LIB_GOBJECT         gobject-2.0)
    _find_gstlib(_LIB_GLIB            glib-2.0)
    _find_gstlib(_LIB_GSTBASE         gstreamer-base-1.0) # optional but common

    set(_missing "")
    foreach(_req _LIB_GSTREAMER _LIB_GSTREAMER_VIDEO _LIB_GSTREAMER_GL _LIB_GOBJECT _LIB_GLIB)
      if(NOT ${_req})
        list(APPEND _missing "${_req}")
      endif()
    endforeach()
    if(_missing)
      message(FATAL_ERROR
        "Missing required GStreamer libs: ${_missing}\n"
        "Searched: ${_GST_LIB_SEARCH_DIRS}")
    endif()

    # Mimic pkg-config imported targets
    add_library(PkgConfig::GSTREAMER       INTERFACE IMPORTED)
    add_library(PkgConfig::GSTREAMER_VIDEO INTERFACE IMPORTED)
    add_library(PkgConfig::GSTREAMER_GL    INTERFACE IMPORTED)

    set_target_properties(PkgConfig::GSTREAMER
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")
    set_target_properties(PkgConfig::GSTREAMER_VIDEO
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")
    set_target_properties(PkgConfig::GSTREAMER_GL
      PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_GST_INC}")

    set(_GST_CORE_LINK "${_LIB_GSTREAMER}" "${_LIB_GOBJECT}" "${_LIB_GLIB}")
    if(_LIB_GSTBASE)
      list(APPEND _GST_CORE_LINK "${_LIB_GSTBASE}")
    endif()

    target_link_libraries(PkgConfig::GSTREAMER       INTERFACE ${_GST_CORE_LINK})
    target_link_libraries(PkgConfig::GSTREAMER_VIDEO INTERFACE "${_LIB_GSTREAMER_VIDEO}" "${_LIB_GOBJECT}" "${_LIB_GLIB}")
    target_link_libraries(PkgConfig::GSTREAMER_GL    INTERFACE "${_LIB_GSTREAMER_GL}"    "${_LIB_GOBJECT}" "${_LIB_GLIB}")

    set(_GST_IMPORTED_TARGETS
      PkgConfig::GSTREAMER
      PkgConfig::GSTREAMER_VIDEO
      PkgConfig::GSTREAMER_GL)
  endif()

else()
  # Non-Android
  pkg_check_modules(GSTREAMER       REQUIRED IMPORTED_TARGET gstreamer-1.0)
  pkg_check_modules(GSTREAMER_VIDEO REQUIRED IMPORTED_TARGET gstreamer-video-1.0)
  pkg_check_modules(GSTREAMER_GL    REQUIRED IMPORTED_TARGET gstreamer-gl-1.0)
  set(_GST_IMPORTED_TARGETS
    PkgConfig::GSTREAMER
    PkgConfig::GSTREAMER_VIDEO
    PkgConfig::GSTREAMER_GL)
endif()

# --- qmlglsink library sources ---
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

# Make sure QPA headers (QtGui/qpa/...) are visible for Qt 6
# Many Qt 6 builds put them under a versioned include dir like:
#   <qt>/include/QtGui/6.x.y/QtGui/qpa/...
# Linking GuiPrivate adds those private include dirs automatically.
if(QT_VERSION_MAJOR EQUAL 6 AND TARGET Qt6::GuiPrivate)
    target_link_libraries(qmlglsink PRIVATE Qt6::GuiPrivate)
endif()

# Extra safety: if for some reason GuiPrivate isn't available, try to
# discover the versioned qpa dir and add it explicitly.
if(QT_VERSION_MAJOR EQUAL 6 AND NOT TARGET Qt6::GuiPrivate)
    get_target_property(_qt_gui_includes Qt6::Gui INTERFACE_INCLUDE_DIRECTORIES)
    set(_qpa_dirs "")
    foreach(d IN LISTS _qt_gui_includes)
        # Unversioned layout: <d>/QtGui/qpa/qplatformnativeinterface.h
        if(EXISTS "${d}/QtGui/qpa/qplatformnativeinterface.h")
            list(APPEND _qpa_dirs "${d}/QtGui")
        endif()
        # Versioned layout: <d>/QtGui/*/QtGui/qpa/qplatformnativeinterface.h
        file(GLOB _ver_candidates "${d}/QtGui/*/QtGui/qpa/qplatformnativeinterface.h")
        foreach(c IN LISTS _ver_candidates)
            get_filename_component(_qpa_dir "${c}" DIRECTORY)       # .../QtGui/qpa
            get_filename_component(_qpa_dir "${_qpa_dir}" DIRECTORY) # .../QtGui
            list(APPEND _qpa_dirs "${_qpa_dir}")
        endforeach()
    endforeach()
    list(REMOVE_DUPLICATES _qpa_dirs)
    if(_qpa_dirs)
        target_include_directories(qmlglsink PRIVATE ${_qpa_dirs})
    else()
        message(WARNING "qmlglsink: could not locate QtGui/qpa include dir; build may fail.")
    endif()
endif()


target_compile_features(qmlglsink PUBLIC cxx_std_17)

# --- QPA header fix ---
# The source includes <qpa/qplatformnativeinterface.h>. That lives under QtGui/qpa.
# Add .../include/QtGui to the include path if we can detect it.
get_target_property(_qt_gui_includes Qt6::Gui INTERFACE_INCLUDE_DIRECTORIES)
set(_qt_qpa_dir "")
foreach(_d IN LISTS _qt_gui_includes)
  if(EXISTS "${_d}/QtGui/qpa/qplatformnativeinterface.h")
    set(_qt_qpa_dir "${_d}/QtGui")
    break()
  endif()
endforeach()
if(_qt_qpa_dir)
  target_include_directories(qmlglsink PRIVATE "${_qt_qpa_dir}")
else()
  message(WARNING "Could not find QtGui/qpa in Qt6::Gui includes; using macro include as fallback")
  target_compile_definitions(qmlglsink PRIVATE HAVE_QT_QPA_HEADER QT_QPA_HEADER=<QtGui/qpa/qplatformnativeinterface.h>)
endif()

# Include GStreamer headers explicitly on Android (desktop gets includes via pkg-config)
target_include_directories(qmlglsink
  PUBLIC
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/gstreamer-1.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/include/glib-2.0>
    $<$<BOOL:${ANDROID}>:${GSTREAMER_ROOT}/lib/glib-2.0/include>
    ${CMAKE_CURRENT_LIST_DIR}/qt6
)

# Link Qt + GStreamer
target_link_libraries(qmlglsink
  PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::OpenGL
    Qt6::Qml
    Qt6::Quick
    ${_GST_IMPORTED_TARGETS}
)

# Platform switches (match your original defines)
target_compile_definitions(qmlglsink
  PUBLIC
    QGC_GST_STREAMING
    QGC_CMAKE_GST
)

# Android GL/EGL/NDK extras
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
