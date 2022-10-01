# CMakeLists files in this project can
# refer to the root source directory of the project as ${MAIN_SOURCE_DIR} and
# to the root binary directory of the project as ${MAIN_BINARY_DIR}.
cmake_minimum_required(VERSION 3.0)

# https://cmake.org/cmake/help/v3.0/command/project.html
project(h265nal VERSION 0.35)

# std::make_ptr requires C++14
set(CMAKE_CXX_STANDARD 14)

# set up clang-tidy
set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-format-style='google'")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

enable_testing()

# Recurse into source code subdirectories.
add_subdirectory(src)
add_subdirectory(webrtc)
add_subdirectory(tools)
add_subdirectory(test)
add_subdirectory(fuzz)
