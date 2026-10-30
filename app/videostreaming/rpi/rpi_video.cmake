# Qt 6 ground display: retain the NXP independent Wayland presenter.
find_package(Qt6 REQUIRED COMPONENTS OpenGL)
find_package(Qt6 REQUIRED COMPONENTS ShaderTools)
qt_add_shaders(QOpenHDApp pi6_shaders
    PREFIX "/qt6-shaders" BASE "${CMAKE_CURRENT_SOURCE_DIR}/app/videostreaming/rpi/shaders"
    FILES app/videostreaming/rpi/shaders/map-mask.frag
          app/videostreaming/rpi/shaders/color-wheel.vert
          app/videostreaming/rpi/shaders/color-wheel.frag)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PI_VIDEO REQUIRED IMPORTED_TARGET
    wayland-client libdrm egl libavcodec libavutil libswscale)
find_program(WAYLAND_SCANNER wayland-scanner REQUIRED NO_CMAKE_FIND_ROOT_PATH)
set(protocol_dir "${CMAKE_CURRENT_BINARY_DIR}/nxp-protocols")
file(MAKE_DIRECTORY "${protocol_dir}")
foreach(protocol IN ITEMS linux-dmabuf viewporter presentation-time)
    if(protocol STREQUAL "linux-dmabuf")
        set(xml "${CMAKE_SYSROOT}/usr/share/wayland-protocols/unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml")
    elseif(protocol STREQUAL "viewporter")
        set(xml "${CMAKE_SYSROOT}/usr/share/wayland-protocols/stable/viewporter/viewporter.xml")
    else()
        set(xml "${CMAKE_SYSROOT}/usr/share/wayland-protocols/stable/presentation-time/presentation-time.xml")
    endif()
    add_custom_command(OUTPUT "${protocol_dir}/${protocol}-client-protocol.h" "${protocol_dir}/${protocol}-protocol.c"
        COMMAND "${WAYLAND_SCANNER}" client-header "${xml}" "${protocol_dir}/${protocol}-client-protocol.h"
        COMMAND "${WAYLAND_SCANNER}" private-code "${xml}" "${protocol_dir}/${protocol}-protocol.c"
        DEPENDS "${xml}" VERBATIM)
    target_sources(QOpenHDApp PRIVATE "${protocol_dir}/${protocol}-protocol.c" "${protocol_dir}/${protocol}-client-protocol.h")
endforeach()
target_sources(QOpenHDApp PRIVATE
    lib/lqtutils_master/lqtutils_ui.cpp
    lib/lqtutils_master/lqtutils_freq.cpp
    app/videostreaming/rpi/PiDecoder.cpp
    app/videostreaming/nxp/UdpVideo.cpp
    app/videostreaming/nxp/WaylandVideo.cpp
    app/videostreaming/nxp/NxpVideoController.cpp
    app/videostreaming/nxp/NxpVideoItem.cpp)
target_include_directories(QOpenHDApp PRIVATE "${protocol_dir}")
target_compile_definitions(QOpenHDApp PRIVATE QOPENHD_ENABLE_NXP_VIDEO QOPENHD_ENABLE_RPI_VIDEO IS_PLATFORM_RPI __desktoplinux__)
target_link_libraries(QOpenHDApp PRIVATE Qt6::GuiPrivate Qt6::OpenGL PkgConfig::PI_VIDEO pthread)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(boot_dir "${CMAKE_CURRENT_BINARY_DIR}/nxp-boot-video")
execute_process(COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tools/nxp-prepare-boot-video.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/qml/boot-video.mp4" "${boot_dir}" COMMAND_ERROR_IS_FATAL ANY)
target_sources(QOpenHDApp PRIVATE "${boot_dir}/boot-video.qrc")
set_target_properties(QOpenHDApp PROPERTIES OUTPUT_NAME QOpenHD)
