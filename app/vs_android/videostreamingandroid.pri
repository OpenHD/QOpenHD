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
GSTREAMER_ROOT_ANDROID = /home/consti10/Downloads/gstreamer-1.0-android-universal-1.20.5

DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID
