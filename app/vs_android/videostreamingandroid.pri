# Based on https://www.kdab.com/qt-android-create-zero-copy-android-surfacetexture-qml-item/
# Not completely ideal, since we still render the video with opengl instead of using the HW composer
# but should give usable latency on most android devices

HEADERS += \
    $$PWD/qandroidmediaplayer.h \
    $$PWD/qsurfacetexture.h

SOURCES += \
    $$PWD/qandroidmediaplayer.cpp \
    $$PWD/qsurfacetexture.cpp

QT += multimedia
QT += multimediawidgets

DOWNLOADED_GST_FOLDER= /home/consti10/Downloads/gstreamer-1.0-android-universal-1.20.5
GSTREAMER_ARCH_FOLDER = armv7

GSTREAMER_ROOT_ANDROID = $$DOWNLOADED_GST_FOLDER/$$GSTREAMER_ARCH_FOLDER
message(gstreamer root android)
message($$GSTREAMER_ROOT_ANDROID)

INCLUDEPATH += $$GSTREAMER_ROOT_ANDROID/include/gstreamer-1.0 $$GSTREAMER_ROOT_ANDROID/include/glib-2.0 $$GSTREAMER_ROOT_ANDROID/lib/glib-2.0/include
#LIBS += -L$$ANDROID_PACKAGE_SOURCE_DIR/libs/$$ANDROID_TARGET_ARCH -lgstreamer-1.0


DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID
