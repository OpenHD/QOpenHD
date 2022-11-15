INCLUDEPATH += $$PWD

LIBS += -lavcodec -lavutil -lavformat
# TODO dirty
LIBS += -lGLESv2 -lEGL

# just using the something something webrtc from stephen was the easiest solution.
include(../../lib/h264/h264.pri)

SOURCES += \
    $$PWD/QSGVideoTextureItem.cpp \
    $$PWD/gl/gl_shaders.cpp \
    $$PWD/gl/gl_videorenderer.cpp \
    $$PWD/rtp/ParseRTP.cpp \
    $$PWD/rtp/rtpreceiver.cpp \
    $$PWD/texturerenderer.cpp \
    $$PWD/avcodec_decoder.cpp \
    $$PWD/udp/UDPReceiver.cpp \

HEADERS += \
    $$PWD/QSGVideoTextureItem.h \
    $$PWD/gl/gl_shaders.h \
    $$PWD/gl/gl_videorenderer.h \
    $$PWD/nalu/KeyFrameFinder.hpp \
    $$PWD/nalu/NALUnitType.hpp \
    $$PWD/rtp/ParseRTP.h \
    $$PWD/rtp/RTP.hpp \
    $$PWD/rtp/rtpreceiver.h \
    $$PWD/texturerenderer.h \
    $$PWD/avcodec_decoder.h \
    $$PWD/udp/UDPReceiver.h \

# Search for mmal at compile time, when found, we can do the "best" path video to display on rpi -
# note that you have to use a config with fkms for mmal to work !
CONFIG += link_pkgconfig
packagesExist(mmal) {
   PKGCONFIG += mmal
   CONFIG += mmal

   PKCONFIG += mmal_core
   PKCONFIG += mmal_components
   PKCONFIG += mmal_util
   # crude, looks like the mmal headers pull in those paths / need them
   INCLUDEPATH += /opt/vc/include/
   INCLUDEPATH += /opt/vc/include/interface/mmal
}


mmal {
    message(MMAL renderer selected)

    DEFINES += HAVE_MMAL

    SOURCES += app/exp/mmal/rpimmaldisplay.cpp \
        app/exp/mmal/rpimmaldecoder.cpp \
        app/exp/mmal/rpimmaldecodedisplay.cpp \

    HEADERS += \
        app/exp/mmal/rpimmaldisplay.h \
        app/exp/mmal/rpimmaldecoder.h \
        app/exp/mmal/rpimmaldecodedisplay.h \
}
# can be used in c++, also set to be exposed in qml
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
