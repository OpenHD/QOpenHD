#
# MIT License
#
# Copyright (c) 2021 Luca Carlon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

cmake_minimum_required(VERSION 3.5)

project(LQtUtilsTest LANGUAGES CXX)

find_package(Qt6 COMPONENTS Test Gui Qml Quick REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enable_testing()

include_directories(../)
include(${CMAKE_CURRENT_SOURCE_DIR}/../CMakeLists.txt)

add_executable(LQtUtilsTest ../lqtutils/tst_lqtutils.cpp ${lqtutils_src})
add_test(NAME LQtUtilsTest COMMAND LQtUtilsTest)
target_link_libraries(LQtUtilsTest PRIVATE Qt6::Test Qt6::Gui Qt6::Qml Qt6::Quick)

if(MSVC)
  target_compile_options(LQtUtilsTest PRIVATE /W4 /WX)
else()
  target_compile_options(LQtUtilsTest PRIVATE -Wall -Wextra -Wpedantic)
endif()
