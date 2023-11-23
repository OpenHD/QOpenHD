INCLUDEPATH += $$PWD

LIBS += -lavcodec -lavutil -lavformat
# TODO dirty
LIBS += -lGLESv2 -lEGL

# just using the something something webrtc from stephen was the easiest solution.
#include(../../lib/h264/h264.pri)

SOURCES += \
    $$PWD/QSGVideoTextureItem.cpp \
    $$PWD/gl/gl_shaders.cpp \
    $$PWD/gl/gl_videorenderer.cpp \
    $$PWD/texturerenderer.cpp \
    $$PWD/avcodec_decoder.cpp \

HEADERS += \
    $$PWD/QSGVideoTextureItem.h \
    $$PWD/gl/gl_shaders.h \
    $$PWD/gl/gl_videorenderer.h \
    $$PWD/texturerenderer.h \
    $$PWD/avcodec_decoder.h \



# experimental
#INCLUDEPATH += /usr/local/include/uvgrtp
#LIBS += -L/usr/local/lib -luvgrtp

# dirty way to check if we are on rpi and therefore should use the external decode service
CONFIG += link_pkgconfig
packagesExist(mmal) {
   DEFINES += IS_PLATFORM_RPI
}
packagesExist(mali) {
   DEFINES += IS_PLATFORM_ROCK
}

# can be used in c++, also set to be exposed in qml
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
