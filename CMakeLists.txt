cmake_minimum_required(VERSION 3.26)

project(QOpenHDProject VERSION 0.1 LANGUAGES C CXX)

set(X_QT_VERSION 6.6.3)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Core Quick Gui Widgets)
qt_standard_project_setup(REQUIRES ${X_QT_VERSION})

if(NOT DEFINED QT_ANDROID_ABIS)
  set(QT_ANDROID_ABIS "arm64-v8a" CACHE STRING "Android ABIs to build for")
endif()

set(QOPENHD_SOURCE_FILES_LIST
    app/main.cpp
    # ... all your other sources ...
    app/videostreaming/vscommon/decodingstatistcs.cpp
)

# Define the executable WITHOUT manual finalization
qt_add_executable(QOpenHDApp
    ${QOPENHD_SOURCE_FILES_LIST}
    lib/geographiclib-c-2.0/src/geodesic.c
    qml/qml.qrc
    androidqt6/AndroidManifest.xml
)

# If you have QML modules (likely), register them so Qt treats this as a module-capable target
qt_add_qml_module(QOpenHDApp
    URI QOpenHD
    VERSION 1.0
    QML_FILES
        qml/main.qml
        # add other QML files or use globbing via CMake if needed
)

# Include directories
target_include_directories(QOpenHDApp PUBLIC
    app
    app/common
    app/adsb
    app/logging
    app/osd
    app/util
    app/telemetry
    app/telemetry/util
    app/videostreaming/vscommon
    lib
    lib/geographiclib-c-2.0/src
)

target_link_libraries(QOpenHDApp
    PRIVATE Qt6::Core Qt6::Quick Qt6::Gui Qt6::Widgets
)

# Android packaging source (must be set before deployment)
set_property(TARGET QOpenHDApp APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
             ${CMAKE_CURRENT_SOURCE_DIR}/androidqt6)

include(lib/h264/h264.cmake)
# other optional includes...

# No explicit qt_finalize_executable(); let Qt handle it automatically for Android
