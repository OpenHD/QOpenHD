INCLUDEPATH += $$PWD
INCLUDEPATH += C:/ffmpeg/include

LIBS += -LC:/ffmpeg/lib -lavcodec -lavutil -lavformat
# TODO dirty
!win32: LIBS += -lGLESv2 -lEGL
unix:!android {
    LIBS += -ldrm
    PKGCONFIG += libdrm
}
win32 {
    INCLUDEPATH += $$PWD/../../../build-libs-windows/ffmpeg/include
    LIBS += -L$$PWD/../../../build-libs-windows/ffmpeg/lib -lavcodec -lavutil -lavformat

    angle_x86 = $$PWD/../../../build-libs-windows/angle-x86
    angle_x64 = $$PWD/../../../build-libs-windows/angle-x64
    exists($$angle_x86/include) {
        INCLUDEPATH += $$angle_x86/include
        LIBS += -L$$angle_x86/bin -lGLESv2 -lEGL
    } else: exists($$angle_x64/include) {
        INCLUDEPATH += $$angle_x64/include
        LIBS += -L$$angle_x64/bin -lGLESv2 -lEGL
    } else {
        INCLUDEPATH += $$[QT_INSTALL_HEADERS]/QtANGLE
        LIBS += -L$$[QT_INSTALL_LIBS] -llibGLESv2 -llibEGL
    }

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

unix:!android {
    SOURCES += $$PWD/drm_kms/kms_renderer.cpp
    HEADERS += $$PWD/drm_kms/kms_renderer.h
}


# experimental
#INCLUDEPATH += /usr/local/include/uvgrtp
#LIBS += -L/usr/local/lib -luvgrtp

# dirty way to check if we are on rpi and therefore should use the external decode service
CONFIG += link_pkgconfig
packagesExist(mmal) {
   DEFINES += IS_PLATFORM_RPI
}

exists(/usr/local/share/openhd/platform/rock/) {
    message(This is a Rock)
    DEFINES += IS_PLATFORM_ROCK
} else {
    message(This is not a Rock)
}

exists(/usr/local/share/openhd/platform/nxp/) {
    message(This is an NXP device)
    DEFINES += IS_PLATFORM_NXP
} else {
    message(This is not an NXP device)
}

# can be used in c++, also set to be exposed in qml
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
