cmake_minimum_required(VERSION 3.16)
project(OfflineMapBuilderTests LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Gui Network Sql)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Gui Network Sql)
add_executable(offline-map-builder-test
    builder_test.cpp ../../app/map/offlinemapbuilder.cpp ../../app/map/offlinemaptileprovider.cpp
    ../../app/map/offline-vector.qrc)
target_include_directories(offline-map-builder-test PRIVATE ../../app/map)
target_link_libraries(offline-map-builder-test PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Network Qt${QT_VERSION_MAJOR}::Sql)
