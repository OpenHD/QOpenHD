# FIXME: will be fixed after converting qmlglsink into .pro#static lib
QMAKE_CXXFLAGS_WARN_ON =

LinuxBuild {
    #DEFINES += HAVE_QT_X11 HAVE_QT_EGLFS HAVE_QT_WAYLAND
    DEFINES += HAVE_QT_EGLFS HAVE_QT_WAYLAND
} else:MacBuild {
    DEFINES += HAVE_QT_MAC
} else:iOSBuild {
    DEFINES += HAVE_QT_IOS
} else:WindowsBuild {
    DEFINES += HAVE_QT_WIN32 HAVE_QT_QPA_HEADER
    LIBS += opengl32.lib user32.lib
} else:AndroidBuild {
    DEFINES += HAVE_QT_ANDROID
}

SOURCES += \
    lib/gst-plugins-good/ext/qt/gstplugin.cc \
    lib/gst-plugins-good/ext/qt/gstqtglutility.cc \
    lib/gst-plugins-good/ext/qt/gstqsgtexture.cc \
    lib/gst-plugins-good/ext/qt/gstqtsink.cc \
    lib/gst-plugins-good/ext/qt/gstqtsrc.cc \
    lib/gst-plugins-good/ext/qt/qtwindow.cc \
    lib/gst-plugins-good/ext/qt/qtitem.cc

HEADERS += \
    lib/gst-plugins-good/ext/qt/gstqsgtexture.h \
    lib/gst-plugins-good/ext/qt/gstqtgl.h \
    lib/gst-plugins-good/ext/qt/gstqtglutility.h \
    lib/gst-plugins-good/ext/qt/gstqtsink.h \
    lib/gst-plugins-good/ext/qt/gstqtsrc.h \
    lib/gst-plugins-good/ext/qt/qtwindow.h \
    lib/gst-plugins-good/ext/qt/qtitem.h
