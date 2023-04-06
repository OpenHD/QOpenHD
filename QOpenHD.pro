BASEDIR = $$IN_PWD

LANGUAGE = C++
CONFIG += c++17
CONFIG+=sdk_no_version_check
TRANSLATIONS = translations/QOpenHD_en.ts \
               translations/QOpenHD_de.ts \
               translations/QOpenHD_ru.ts \
               translations/QOpenHD_nl.ts \
               translations/QOpenHD_es.ts \
               translations/QOpenHD_fr.ts \
               translations/QOpenHD_zh.ts \
               translations/QOpenHD_it.ts \
               translations/QOpenHD_ro.ts


include(platforms.pri)

include(git.pri)
# this library can be included via either .pri or cmake
# since it is a library "specifically for qt"
include(lib/lqtutils_master/lqtutils.pri)

# No one knows what this block below does, from stephen most likely
CONFIG(debug, debug|release) {
    DESTDIR = $${OUT_PWD}/debug

    CONFIG += debug
    DEFINES += QMLJSDEBUGGER
} else:CONFIG(release, debug|release) {
    DEFINES += QT_NO_DEBUG
    CONFIG += installer
    CONFIG += force_debug_info
    DESTDIR = $${OUT_PWD}/release
    DEFINES += QMLJSDEBUGGER
}

#https://doc.qt.io/qt-6/portingguide.html
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x050F00

# See https://www.qt.io/blog/qml-type-registration-in-qt-5.15
# avoid using qmlRegisterType<>, use macro instead
CONFIG += qmltypes
QML_IMPORT_NAME = OpenHD
QML_IMPORT_MAJOR_VERSION = 1

OBJECTS_DIR  = $${OUT_PWD}/obj
MOC_DIR      = $${OUT_PWD}/moc
UI_DIR       = $${OUT_PWD}/ui
RCC_DIR      = $${OUT_PWD}/rcc

#from https://mavlink.io/en/mavgen_c/
#You can supress the warnings in CMake using ...
#and https://stackoverflow.com/questions/2987062/configuring-the-gcc-compiler-switches-in-qt-qtcreator-and-qmake
#this can not be used in MSVC (windows)
#NOTE: While disabling warnings is often discouraged, in the scope of QOpenHD, those warnings distract more from actual issues than help
#However, if you feel so, re-enable and fix them ;)
QMAKE_CXXFLAGS += -Wno-address-of-packed-member
QMAKE_CXXFLAGS += -Wno-cast-align
QMAKE_CXXFLAGS += -Wno-unused-function
QMAKE_CXXFLAGS += -Wno-unused-variable
QMAKE_CXXFLAGS += -Wno-unused-parameter
QMAKE_CXXFLAGS += -Wno-sign-compare

# These are the QT libraries we always need when building QOpenHD - they are intentially kept as small in number as possible
# (aka all these really should come with pretty much any qt install)
# In general, parts of QOpenHD that need additional libraries should have their code in a subdirectory with a .pri where those
# dependencies are added such that you can easily compile the project even on systems that might lack some of those qt functionalities
# see app/adsb/adsb_lib.pri for an example
QT +=core quick qml gui \
    widgets
QT += opengl

INCLUDEPATH += $$PWD/lib
INCLUDEPATH += $$PWD/app
INCLUDEPATH += $$PWD/app/exp

# QOpenHD telemetry (mavlink, partially based on MAVSDK) features
# REQUIRED - without it QOpenHD will compile, but be pretty much non functional
include(app/telemetry/telemetry.pri)

# This code is platform and library independent, and always compiled.
include(app/videostreaming/vscommon/vscommon.pri)

# Video is quite platform dependent, if you have compile issues, try compiling without any videostreaming enabled first ;)
LinuxBuild {
    # Avcodec decode and display, all sources
    # Replaced gstreamer for now
    # Comment the line below to build without avcodec (you won't have any video decoding capabilities in this case though)
    # However, this can be usefully for figuring out compiler issue(s) on different platform(s)
    # NOTE: QT Creator is quite bad at figuring out changes here, you might need a "full" rebuild or manualy delete
    # the build dir/cache, then rebuild
    include(app/videostreaming/avcodec/avcodec_video.pri)

    # Gstreamer / qmlglsink decode and display, all sources
    # r.n only used for secondary video and for primary video only on platforms we cannot do primary video via QSG / avcodec
    include(app/videostreaming/gstreamer/gst_video.pri)
}

# adsb library
# Only tested on linux so far, but might work on other platforms already / with minimal effort, too
LinuxBuild {
    include(app/adsb/adsb_lib.pri)
}

# All Generic files / files that literally have 0!! dependencies other than qt
SOURCES += \
    app/logging/hudlogmessagesmodel.cpp \
    app/logging/logmessagesmodel.cpp \
    app/util/qopenhd.cpp \
    app/util/WorkaroundMessageBox.cpp \
    app/util/qrenderstats.cpp \
    app/util/restartqopenhdmessagebox.cpp \
    app/main.cpp \

HEADERS += \
    app/logging/hudlogmessagesmodel.h \
    app/logging/loghelper.h \
    app/logging/logmessagesmodel.h \
    app/util/qopenhd.h \
    app/util/WorkaroundMessageBox.h \
    app/util/qrenderstats.h \
    app/util/restartqopenhdmessagebox.h \


# Geographic lib updated to c-2.0, so much cleaner
SOURCES += $$PWD/lib/geographiclib-c-2.0/src/geodesic.c
HEADERS += $$PWD/lib/geographiclib-c-2.0/src/geodesic.h

# All files for the OSD elements - these are QT QQuickPaintedItem's that are written in c++
SOURCES += \
    app/osd/headingladder.cpp \
    app/osd/horizonladder.cpp \
    app/osd/speedladder.cpp \
    app/osd/altitudeladder.cpp \
    app/osd/drawingcanvas.cpp \
    app/osd/flightpathvector.cpp \
    app/osd/aoagauge.cpp \
    app/osd/performancehorizonladder.cpp \

HEADERS += \
    app/osd/headingladder.h \
    app/osd/horizonladder.h \
    app/osd/speedladder.h \
    app/osd/altitudeladder.h \
    app/osd/drawingcanvas.h \
    app/osd/flightpathvector.h \
    app/osd/debug_overdraw.hpp \
    app/osd/aoagauge.h \
    app/osd/performancehorizonladder.h \


RESOURCES += qml/qml.qrc


DISTFILES += \
    README.md \
    android/AndroidManifest.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew \
    android/gradlew.bat \
    android/res/drawable-hdpi/splashscreen.png \
    android/res/drawable-ldpi/splashscreen.png \
    android/res/drawable-mdpi/splashscreen.png \
    android/res/drawable-xhdpi/splashscreen.png \
    android/res/drawable-xxhdpi/splashscreen.png \
    android/res/drawable-xxxhdpi/splashscreen.png \
    android/res/values/libs.xml \
    android/res/values/styles.xml \
    android/src/OpenHDActivity.java \
    android/src/SurfaceTextureListener.java \
    android/src/org/freedesktop/gstreamer/androidmedia/GstAhcCallback.java \
    android/src/org/freedesktop/gstreamer/androidmedia/GstAhsCallback.java \
    android/src/org/freedesktop/gstreamer/androidmedia/GstAmcOnFrameAvailableListener.java \
    android/src/org/openhd/LiveVideoPlayerWrapper.java \
    app/adsb/adsb_lib.pri \
    app/logging/README.txt \
    app/openhd_systems/README.md \
    app/osd_extra/Readme.txt \
    app/platform/README.md \
    app/telemetry/telemetry.pri \
    app/util/README.md \
    app/videostreaming/README.md \
    app/videostreaming/README.txt \
    app/videostreaming/gst_qmlglsink/gst_video.pri \
    app/videostreaming/vscommon/vscommon.pri \
    app/vs_android/videostreamingandroid.pri \
    extra_build_qmake.sh \
    lib/h264nal/h264nal.pri \
    qml/qtquickcontrols2.conf \
    qml/ui/qmldir \


iOSBuild {
    QMAKE_INFO_PLIST    = ios/Info.plist
    QMAKE_TARGET_BUNDLE_PREFIX = com.infincia
    QMAKE_BUNDLE = qopenhd
    QMAKE_DEVELOPMENT_TEAM = G738Z89QKM
    ICON                = $${BASEDIR}/icons/macos.icns
    DISTFILES        += ios/Info.plist \
                        icons/LaunchScreen.png \
                        icons/LaunchScreen.storyboard
    LIBS += -framework VideoToolbox -framework AudioToolbox -framework CoreAudio -framework CoreVideo -framework CoreMedia
    CONFIG -= bitcode
    #CONFIG += EnableGamepads
    CONFIG += EnableSpeech
    CONFIG += EnableMainVideo
    #CONFIG += EnableLog //does not work due to filepath not set

    app_launch_images.files = $$PWD/icons/LaunchScreen.png $$files($$PWD/icons/LaunchScreen.storyboard)
    QMAKE_BUNDLE_DATA += app_launch_images

    QMAKE_ASSET_CATALOGS += $$PWD/icons/ios/Assets.xcassets

    HEADERS += \
        src/platform/appleplatform.h

    SOURCES += \
        src/platform/appleplatform.mm
}

MacBuild {
    QMAKE_INFO_PLIST = mac/Info.plist
    ICON = $${BASEDIR}/icons/macos.icns
    DISTFILES += mac/Info.plist
    LIBS += -framework ApplicationServices
    LIBS += -framework VideoToolbox -framework CoreVideo -framework CoreMedia
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
}

LinuxBuild {
    CONFIG += EnableSpeech
    message("LinuxBuild - config")
}

JetsonBuild {
    message("JetsonBuild")
    CONFIG += EnableSpeech
}


WindowsBuild {
    DEFINES += GST_GL_HAVE_WINDOW_WIN32=1
    DEFINES += GST_GL_HAVE_PLATFORM_WGL=1
    DEFINES += HAVE_QT_WIN32

    INCLUDEPATH += $$PWD/win/include
}

AndroidBuild {
    message("AndroidBuild")
    CONFIG += EnableJoysticks
    # Text to speech crashes on android for some weird reason
    #CONFIG += EnableSpeech
    QT += androidextras

    #include(app/videostreaming/gstreamer/gst_video.pri)
    #include(app/videostreaming/android/videostreamingandroid.pri)
}

EnableSpeech {
    message("EnableSpeech")
    DEFINES += ENABLE_SPEECH
    QT += texttospeech
}


android{
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}
