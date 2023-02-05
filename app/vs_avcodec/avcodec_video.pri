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
    $$PWD/readerwriterqueue/atomicops.h \
    $$PWD/readerwriterqueue/readerwritercircularbuffer.h \
    $$PWD/readerwriterqueue/readerwriterqueue.h \

# Search for mmal at compile time, when found, we can do the "best" path video to display on rpi -
# note that you then have to use a /boot/config.txt with fkms for mmal to work (default in OpenHD image,
# but not in raspbian)
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

# experimental
#INCLUDEPATH += /usr/local/include/uvgrtp
#LIBS += -L/usr/local/lib -luvgrtp

mmal {
    message(MMAL renderer selected)

    DEFINES += HAVE_MMAL

    SOURCES += \
         $$PWD/mmal/rpimmaldisplay.cpp \
         $$PWD/mmal/rpimmaldecoder.cpp \
         $$PWD/mmal/rpimmaldecodedisplay.cpp \

    HEADERS += \
         $$PWD/mmal/rpimmaldisplay.h \
         $$PWD/mmal/rpimmaldecoder.h \
         $$PWD/mmal/rpimmaldecodedisplay.h \
}
# can be used in c++, also set to be exposed in qml
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_AVCODEC


# experimental, use uvgRTP instead of a custom rtp receive impl
#LIBS += -luvgrtp
