DEFINES += QOPENHD_ENABLE_GSTREAMER

#DEFINES += QOPENHD_GSTREAMER_PRIMARY_VIDEO
DEFINES += QOPENHD_GSTREAMER_SECONDARY_VIDEO

SOURCES += \
    $$PWD//gstvideostream.cpp

HEADERS += \
    $$PWD//gst_helper.hpp \
    $$PWD//gstvideostream.h

CONFIG += link_pkgconfig
PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0 #gstreamer1.0-plugins-good
