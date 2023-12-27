INCLUDEPATH += $$PWD

# just using the something something webrtc from stephen was the easiest solution.
include(../../../lib/h264/h264.pri)

windows {
    SOURCES += \
        $$PWD/decodingstatistcs.cpp \

    HEADERS += \
        $$PWD/decodingstatistcs.h \
        $$PWD/QOpenHDVideoHelper.hpp \

} else {

    SOURCES += \
        $$PWD/rtp/ParseRTP.cpp \
        $$PWD/rtp/rtpreceiver.cpp \
        $$PWD/udp/UDPReceiver.cpp \
        $$PWD/decodingstatistcs.cpp \

    HEADERS += \
        $$PWD/nalu/KeyFrameFinder.hpp \
        $$PWD/nalu/NALUnitType.hpp \
        $$PWD/rtp/ParseRTP.h \
        $$PWD/rtp/RTP.hpp \
        $$PWD/rtp/rtpreceiver.h \
        $$PWD/udp/UDPReceiver.h \
        $$PWD/decodingstatistcs.h \
        $$PWD/QOpenHDVideoHelper.hpp \
}

HEADERS += \
    $$PWD/ExternalDecodeService.hpp \
    $$PWD/custom/rawreceiver.h

SOURCES += \
    $$PWD/custom/rawreceiver.cpp

