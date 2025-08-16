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
)

# Make sure includes line up with how you #include files
target_include_directories(lowlag_android
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}  
        ${CMAKE_CURRENT_SOURCE_DIR}/aarch64 
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/h264
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming
        ${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/vscommon
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

if(QT_VERSION_MAJOR EQUAL 5)
    if(TARGET Qt5::AndroidExtras)
        target_link_libraries(lowlag_android PUBLIC Qt5::AndroidExtras)
    endif()
    if(TARGET Qt5::MultimediaWidgets)
        target_link_libraries(lowlag_android PUBLIC Qt5::MultimediaWidgets)
    endif()
endif()

if(ANDROID)
    target_link_libraries(lowlag_android PRIVATE android mediandk)
endif()
