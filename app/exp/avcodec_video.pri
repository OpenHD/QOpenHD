INCLUDEPATH += $$PWD

SOURCES += \
    $$PWD/QSGVideoTextureItem.cpp \
    $$PWD/gl/gl_shaders.cpp \
    $$PWD/gl/gl_videorenderer.cpp \
    $$PWD/rtp/ParseRTP.cpp \
    $$PWD/rtp/rtpreceiver.cpp \
    $$PWD/texturerenderer.cpp \
    $$PWD/avcodec_decoder.cpp \
	



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
