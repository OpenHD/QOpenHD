cmake_minimum_required(VERSION 3.16)

# You can rename the project/target if you like.
project(LowLagAndroid LANGUAGES CXX)

# --- Sources / headers ---
set(LOWLAG_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/lowlagdecoder.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/qandroidmediaplayer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/qsurfacetexture.cpp
)

set(LOWLAG_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/lowlagdecoder.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/qandroidmediaplayer.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/android/qsurfacetexture.h
)

# --- Qt detection (Qt 6 preferred, falls back to Qt 5) ---
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Multimedia)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Multimedia)

# Optional modules present in your qmake file.
# Qt 5 has AndroidExtras and MultimediaWidgets; Qt 6 does not.
if(QT_VERSION_MAJOR EQUAL 5)
    find_package(Qt5 QUIET COMPONENTS AndroidExtras MultimediaWidgets)
endif()

# --- Library target ---
add_library(lowlag_android STATIC
    ${LOWLAG_SOURCES}
    ${LOWLAG_HEADERS}
)

# If these files have Q_OBJECT, you may want this (or set it globally in your root CMake):
set_target_properties(lowlag_android PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
)

target_include_directories(lowlag_android
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# Mirror: DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID
target_compile_definitions(lowlag_android
    PUBLIC
        QOPENHD_ENABLE_VIDEO_VIA_ANDROID
)

# Mirror: QT += multimedia (and widgets on Qt5), androidextras on Qt5
target_link_libraries(lowlag_android
    PUBLIC
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Multimedia
)

if(QT_VERSION_MAJOR EQUAL 5)
    if(TARGET Qt5::AndroidExtras)
        target_link_libraries(lowlag_android PUBLIC Qt5::AndroidExtras)
    endif()
    if(TARGET Qt5::MultimediaWidgets)
        target_link_libraries(lowlag_android PUBLIC Qt5::MultimediaWidgets)
    endif()
endif()

# Mirror: LIBS += -lmediandk -landroid (Android only)
if(ANDROID)
    # These are provided by the NDK toolchain on Android builds.
    target_link_libraries(lowlag_android PRIVATE android mediandk)
endif()
