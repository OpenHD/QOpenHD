set(AVCODEC_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/QSGVideoTextureItem.cpp
    ${CMAKE_CURRENT_LIST_DIR}/gl/gl_shaders.cpp
    ${CMAKE_CURRENT_LIST_DIR}/gl/gl_videorenderer.cpp
    ${CMAKE_CURRENT_LIST_DIR}/texturerenderer.cpp
    ${CMAKE_CURRENT_LIST_DIR}/avcodec_decoder.cpp
)

set(AVCODEC_HEADERS
    QSGVideoTextureItem.h
)

target_sources(QOpenHD PRIVATE ${AVCODEC_SOURCES})

target_include_directories(QOpenHD
    PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}
)

target_link_libraries(QOpenHD PRIVATE avcodec avutil avformat)
target_link_libraries(QOpenHD PRIVATE GLESv2 EGL)

add_compile_definitions(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC)
