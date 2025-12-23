cmake_minimum_required(VERSION 3.10)
project(openhd_mavlink_tool LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(openhd_mavlink_tool openhd_mavlink_tool.cpp)

# The tool only depends on the vendored MAVLink headers.
target_include_directories(openhd_mavlink_tool PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../lib/mavlink-headers
    ${CMAKE_CURRENT_SOURCE_DIR}/../lib/mavlink-headers/mavlink/v2.0
)
