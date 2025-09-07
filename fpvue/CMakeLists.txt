cmake_minimum_required(VERSION 2.8)

#set(CMAKE_C_COMPILER "/usr/bin/gcc")

project(fpvue)

set(CMAKE_CXX_STANDARD 17)

add_compile_options("-Wno-address-of-packed-member")
add_compile_options("-Wno-address-of-packed-member")

SET(CMAKE_ASM_FLAGS "${CFLAGS} -x assembler-with-cpp")

set(SOURCE_FILES drm.c
                                rtp.c
        main.cpp
        copy_util.h
        SchedulingHelper.hpp
        gstrtpreceiver.cpp
        gstrtpreceiver.h
        allwinnerv4l2display.cpp
        allwinnerv4l2display.h
        display_host.cpp
        #
        assembly/memcpymove-v7l.S
        parse_x20_util.h
)

add_executable(${PROJECT_NAME} ${SOURCE_FILES})

find_library(ROCKCHIP_MPP_LIB rockchip_mpp)
if(ROCKCHIP_MPP_LIB)
  message(STATUS "Building with Rockchip MPP")
  target_link_libraries(${PROJECT_NAME} ${ROCKCHIP_MPP_LIB})
else()
  message(STATUS "Rockchip MPP not found: building without Rockchip support")
endif()

target_link_libraries(${PROJECT_NAME} pthread m ) #-lstringlib

# experiment gstreamer
find_package(PkgConfig REQUIRED)
pkg_search_module(GST REQUIRED
        gstreamer-1.0>=1.4
        gstreamer-app-1.0>=1.4
)
pkg_search_module(gstreamer REQUIRED IMPORTED_TARGET gstreamer-1.0>=1.4)
pkg_search_module(gstreamer-app REQUIRED IMPORTED_TARGET gstreamer-app-1.0>=1.4)
target_link_libraries(${PROJECT_NAME} PkgConfig::gstreamer PkgConfig::gstreamer-app)

pkg_check_modules(LIBDRM REQUIRED libdrm)
message(STATUS "LIBDRM_LINK_LIBRARIES=${LIBDRM_LINK_LIBRARIES}")
include_directories(${LIBDRM_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} ${LIBDRM_LIBRARIES})

add_executable(display_host display_host_main.cpp display_host.cpp drm.c)
target_link_libraries(display_host pthread m ${LIBDRM_LIBRARIES})


if(CMAKE_BUILD_TYPE MATCHES "Debug")
  set(
    CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} -Werror -fsanitize=undefined -fsanitize=address"
  )
  set(
    CMAKE_CXX_FLAGS
    "${CMAKE_CXX_FLAGS} -fsanitize=undefined -fsanitize=address"
  )
  target_link_options(${PROJECT_NAME}
    BEFORE PUBLIC -fsanitize=undefined PUBLIC -fsanitize=address
  )
  target_link_options(display_host
    BEFORE PUBLIC -fsanitize=undefined PUBLIC -fsanitize=address
  )
endif()

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME} display_host
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
