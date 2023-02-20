# Based on https://www.kdab.com/qt-android-create-zero-copy-android-surfacetexture-qml-item/
# Not completely ideal, since we still render the video with opengl instead of using the HW composer
# but should give usable latency on most android devices

HEADERS += \
    $$PWD/qandroidmediaplayer.h \
    $$PWD/qsurfacetexture.h

SOURCES += \
    $$PWD/qandroidmediaplayer.cpp \
    $$PWD/qsurfacetexture.cpp
    $$PWD/gst_live_player.c

QT += multimedia
QT += multimediawidgets

# Where gstreamer android prebuilt has been dowwnloaded and installed into
DOWNLOADED_GST_FOLDER= /home/consti10/Downloads/gstreamer-1.0-android-universal-1.20.5
GSTREAMER_ARCH_FOLDER = armv7

GSTREAMER_ROOT_ANDROID = $$DOWNLOADED_GST_FOLDER/$$GSTREAMER_ARCH_FOLDER
message(gstreamer root android:)
message($$GSTREAMER_ROOT_ANDROID)


# XXXX
# From stephen qt some tag, who actually took it from https://github.com/mavlink/qgroundcontrol/blob/master/src/VideoReceiver/VideoReceiver.pri
GST_ROOT = $$GSTREAMER_ROOT_ANDROID
exists($$GST_ROOT) {
    message(Doing stehen gstreamer stuff)
    message($$GST_ROOT)
    QMAKE_CXXFLAGS  += -pthread
    CONFIG          += VideoEnabled

    # We want to link these plugins statically
    LIBS += -L$$GST_ROOT/lib/gstreamer-1.0

    SHARED_LIB_FILES = $$files($$GST_ROOT/lib/gstreamer-1.0/*.a)
    for(FILE, SHARED_LIB_FILES) {
        BASENAME = $$basename(FILE)
        BASENAME = $$replace(BASENAME,^lib,)

        LIBS += -l$$replace(BASENAME,\.a,)
    }

    # Rest of GStreamer dependencies
    LIBS += -L$$GST_ROOT/lib \
        -lgstfft-1.0 -lm  \
        -lgstnet-1.0 -lgio-2.0 \
        -lgstaudio-1.0 -lgstcodecparsers-1.0 -lgstbase-1.0 \
        -lgstreamer-1.0 -lgstrtp-1.0 -lgstpbutils-1.0 -lgstrtsp-1.0 -lgsttag-1.0 \
        -lgstvideo-1.0 -lavformat -lavcodec -lavutil -lx264 -lavfilter -lswresample \
        -lgstriff-1.0 -lgstcontroller-1.0 -lgstapp-1.0 \
        -lgstsdp-1.0 -lbz2 -lgobject-2.0 \
        -lgstgl-1.0  -lgraphene-1.0 -lpng16 -ljpeg -lgstphotography-1.0 -lEGL \
        -Wl,--export-dynamic -lgmodule-2.0 -pthread -lglib-2.0 -lorc-0.4 -liconv -lffi -lintl \

    INCLUDEPATH += \
        $$GST_ROOT/include/gstreamer-1.0 \
        $$GST_ROOT/lib/gstreamer-1.0/include \
        $$GST_ROOT/include/glib-2.0 \
        $$GST_ROOT/lib/glib-2.0/include
}
# XXXX

#INCLUDEPATH += $$GSTREAMER_ROOT_ANDROID/include/gstreamer-1.0 $$GSTREAMER_ROOT_ANDROID/include/glib-2.0 $$GSTREAMER_ROOT_ANDROID/lib/glib-2.0/include
#LIBS += -L$$ANDROID_PACKAGE_SOURCE_DIR/libs/$$ANDROID_TARGET_ARCH -lgstreamer-1.0

DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID
