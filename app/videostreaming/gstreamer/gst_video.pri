DEFINES += QOPENHD_ENABLE_GSTREAMER_QMLGLSINK

#DEFINES += QOPENHD_GSTREAMER_PRIMARY_VIDEO
DEFINES += QOPENHD_GSTREAMER_SECONDARY_VIDEO

SOURCES += \
    $$PWD/gstqmlglsinkstream.cpp \
    $$PWD/gstrtpreceiver.cpp

HEADERS += \
    $$PWD/gst_helper.hpp \
    $$PWD/gstqmlglsinkstream.h \
    $$PWD/gstrtpreceiver.h

android{
    message("gst android")

    #DOWNLOADED_GST_FOLDER= /home/consti10/Downloads/gstreamer-1.0-android-universal-1.20.5
    DOWNLOADED_GST_FOLDER= $$PWD/../../../lib/gstreamer_prebuilts/gstreamer-1.0-android-universal-1.20.5
    GSTREAMER_ARCH_FOLDER = armv7

    GSTREAMER_ROOT_ANDROID = $$DOWNLOADED_GST_FOLDER/$$GSTREAMER_ARCH_FOLDER
    message(gstreamer root android:)
    message($$GSTREAMER_ROOT_ANDROID)


    # XXXX
    GST_ROOT = $$GSTREAMER_ROOT_ANDROID
    exists($$GST_ROOT) {
        message(Doing QGC gstreamer stuff)
        message($$GST_ROOT)
        QMAKE_CXXFLAGS  += -pthread
        CONFIG          += VideoEnabled

        LIBS += -L$$GST_ROOT/lib/gstreamer-1.0 \
            -lgstvideo-1.0 \
            -lgstcoreelements \
            -lgstplayback \
            -lgstudp \
            -lgstrtp \
            -lgstrtsp \
            -lgstx264 \
            -lgstlibav \
            -lgstsdpelem \
            -lgstvideoparsersbad \
            -lgstrtpmanager \
            -lgstisomp4 \
            -lgstmatroska \
            -lgstmpegtsdemux \
            -lgstandroidmedia \
            -lgstopengl \
            -lgsttcp \
            -lgstapp


        # Rest of GStreamer dependencies
        LIBS += -L$$GST_ROOT/lib \
            -lgraphene-1.0 -ljpeg -lpng16 \
            -lgstfft-1.0 -lm  \
            -lgstnet-1.0 -lgio-2.0 \
            -lgstphotography-1.0 -lgstgl-1.0 -lEGL \
            -lgstaudio-1.0 -lgstcodecparsers-1.0 -lgstbase-1.0 \
            -lgstreamer-1.0 -lgstrtp-1.0 -lgstpbutils-1.0 -lgstrtsp-1.0 -lgsttag-1.0 \
            -lgstvideo-1.0 -lavformat -lavcodec -lavutil -lx264 -lavfilter -lswresample \
            -lgstriff-1.0 -lgstcontroller-1.0 -lgstapp-1.0 \
            -lgstsdp-1.0 -lbz2 -lgobject-2.0 -lgstmpegts-1.0 \
            -Wl,--export-dynamic -lgmodule-2.0 -pthread -lglib-2.0 -lorc-0.4 -liconv -lffi -lintl \

        INCLUDEPATH += \
            $$GST_ROOT/include/gstreamer-1.0 \
            $$GST_ROOT/lib/gstreamer-1.0/include \
            $$GST_ROOT/include/glib-2.0 \
            $$GST_ROOT/lib/glib-2.0/include
    }else{
        message(Gstreamer prebuilt directory does not exist)
    }
    # XXXX
}else{
    message(gst linux)
    CONFIG += link_pkgconfig
    PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0 gstreamer-app-1.0 #gstreamer1.0-plugins-good
}
