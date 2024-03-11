set(GSTREAMER_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/gstqmlglsinkstream.cpp
    ${CMAKE_CURRENT_LIST_DIR}/gstrtpaudioplayer.cpp
    ${CMAKE_CURRENT_LIST_DIR}/gstrtpreceiver.cpp
)

target_sources(QOpenHDApp PRIVATE ${GSTREAMER_SOURCES})

target_include_directories(QOpenHDApp
    PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}
)

# Link to gstreamer

find_package(PkgConfig REQUIRED)
pkg_search_module(GST REQUIRED
            gstreamer-1.0>=1.4
            gstreamer-app-1.0>=1.4
    )
pkg_search_module(gstreamer REQUIRED IMPORTED_TARGET gstreamer-1.0>=1.4)
pkg_search_module(gstreamer-app REQUIRED IMPORTED_TARGET gstreamer-app-1.0>=1.4)
target_link_libraries(QOpenHDApp PRIVATE PkgConfig::gstreamer PkgConfig::gstreamer-app)
#target_link_libraries(QOpenHDApp PRIVATE gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0 gstreamer-app-1.0)

add_compile_definitions(QOPENHD_ENABLE_GSTREAMER_QMLGLSINK)
add_compile_definitions(QOPENHD_GSTREAMER_SECONDARY_VIDEO)
