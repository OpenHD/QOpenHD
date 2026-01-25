INCLUDEPATH += $$PWD
INCLUDEPATH += C:/ffmpeg/include

LIBS += -LC:/ffmpeg/lib -lavcodec -lavutil -lavformat
# TODO dirty
LIBS += -lGLESv2 -lEGL
LIBS += -ldrm
PKGCONFIG += libdrm

win32 {
    INCLUDEPATH += $$PWD/../../../build-libs-windows/ffmpeg/include
    LIBS += -L$$PWD/../../../build-libs-windows/ffmpeg/lib -lavcodec -lavutil -lavformat

    INCLUDEPATH += $$PWD/../../../build-libs-windows/angle-x64/include
    LIBS += -L$$PWD/../../../build-libs-windows/angle-x64/bin -lGLESv2 -lEGL

    DEFINES += EGL_EGLEXT_PROTOTYPES
    DEFINES += GL_GLEXT_PROTOTYPES
#    LIBS += -lOpengl32
}

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

# Platform detection is handled at runtime via openhd-sysutils.

# can be used in c++, also set to be exposed in qml
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
