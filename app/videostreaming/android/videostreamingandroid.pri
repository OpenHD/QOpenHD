# Android low-latency decoder (ASurfaceTexture-based)
# Reference: https://www.kdab.com/qt-android-create-zero-copy-android-surfacetexture-qml-item/

HEADERS += \
    $$PWD/lowlagdecoder.h \
    $$PWD/qandroidmediaplayer.h \
    $$PWD/qsurfacetexture.h

SOURCES += \
    $$PWD/lowlagdecoder.cpp \
    $$PWD/qandroidmediaplayer.cpp \
    $$PWD/qsurfacetexture.cpp

# Link required Android system libraries
LIBS += -lmediandk \
        -landroid \
        -llog \
        -lOpenSLES \
        -lGLESv2 \
        -lc

QT += androidextras \
      multimedia \
      multimediawidgets

# Make sure ASurfaceTexture API is enabled
DEFINES += QOPENHD_ENABLE_VIDEO_VIA_ANDROID
DEFINES += __ANDROID_API__=26

# Include path for surface_texture.h (if not already present via NDK setup)
INCLUDEPATH += $$NDK_ROOT/sysroot/usr/include/android
