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
QMAKE_CXXFLAGS += -Wno-address-of-packed-member
QMAKE_CXXFLAGS += -Wno-cast-align

# These are the QT libraries we always need when building QOpenHD - they are intentially kept as small in number as possible
# (aka all these really should come with pretty much any qt install)
# In general, parts of QOpenHD that need additional libraries should have their code in a subdirectory with a .pri where those
# dependencies are added such that you can easily compile the project even on systems that might lack some of those qt functionalities
# see app/adsb/adsb_lib.pri for an example
QT +=core quick qml gui
QT += opengl

INCLUDEPATH += $$PWD/lib
INCLUDEPATH += $$PWD/app
INCLUDEPATH += $$PWD/app/exp

CONFIG += QOPENHD_LINK_MAVSDK_SHARED
QOPENHD_LINK_MAVSDK_SHARED {
    message(mavsdk shared)
    INCLUDEPATH += /usr/local/include/mavsdk
    INCLUDEPATH += /usr/include/mavsdk
    LIBS += -L/usr/local/lib -lmavsdk
} else {
    message(mavsdk static)
}

# NOTE: mavlink we get from MAVSDK
# MAVSDK needs to be built and installed externally
# We have the include path 2 times here, aparently release and debug install to different paths
# The following lines are for linux only
#INCLUDEPATH += /usr/local/include/mavsdk
#LIBS += -L/usr/local/lib -lmavsdk
#INCLUDEPATH += /usr/include/mavsdk
# The following lines are for windows
#INCLUDEPATH += C:\MAVSDK\
#INCLUDEPATH += C:\MAVSDK\include
#LIBS += -LC:\MAVSDK\lib

# For linking MAVSDK statically
#unix:!macx: LIBS += -L$$PWD/mavsdk/lib/ -lmavsdk
#INCLUDEPATH += $$PWD/mavsdk/include
#DEPENDPATH += $$PWD/mavsdk/include
#unix:!macx: PRE_TARGETDEPS += $$PWD/mavsdk/lib/libmavsdk.a



# Avcodec decode and display, all sources
# Replaced gstreamer for now
# Comment the line below to build without avcodec (you won't have any video decoding capabilities in this case though)
# However, this can be usefully for figuring out compiler issue(s) on different platform(s)
# NOTE: QT Creator is quite bad at figuring out changes here, you might need a "full" rebuild or manualy delete
# the build dir/cache, then rebuild
include(app/vs_avcodec/avcodec_video.pri)

# Gstreamer / qmlglsink decode and display, all sources
# r.n only used for secondary video and for primary video only on platforms we cannot do primary video via QSG / avcodec
include(app/vs_gst_qmlglsink/gst_video.pri)

# adsb library
include(app/adsb/adsb_lib.pri)

# All Generic files. NOTE: During development, when you create new files, QT Creater will add them to the
# "first SOURCES / HEADERS it can find in the .pro, which is here". This is why (as an example) geographic lib,
# which is a library, comes after the generic files here.
SOURCES += \
    app/logging/hudlogmessagesmodel.cpp \
    app/logging/logmessagesmodel.cpp \
    app/telemetry/models/aohdsystem.cpp \
    app/qopenhd.cpp \
    app/telemetry/models/camerastreammodel.cpp \
    app/telemetry/models/rcchannelsmodel.cpp \
    app/telemetry/models/wificard.cpp \
    app/telemetry/settings/improvedintsetting.cpp \
    app/telemetry/settings/improvedstringsetting.cpp \
    app/telemetry/settings/synchronizedsettings.cpp \
    app/util/QmlObjectListModel.cpp \
    app/util/WorkaroundMessageBox.cpp \
    app/util/qrenderstats.cpp \
    app/vs_util/decodingstatistcs.cpp

HEADERS += \
    app/logging/hudlogmessagesmodel.h \
    app/logging/loghelper.h \
    app/logging/logmessagesmodel.h \
    app/telemetry/mavsdk_include.h \
    app/telemetry/models/aohdsystem.h \
    app/telemetry/models/camerastreammodel.h \
    app/telemetry/models/rcchannelsmodel.h \
    app/qopenhd.h \
    app/telemetry/models/wificard.h \
    app/telemetry/openhd_defines.hpp \
    app/telemetry/qopenhdmavlinkhelper.hpp \
    app/telemetry/settings/improvedintsetting.h \
    app/telemetry/settings/improvedstringsetting.h \
    app/telemetry/settings/synchronizedsettings.h \
    app/telemetry/telemetryutil.hpp \
    app/util/QmlObjectListModel.h \
    app/util/WorkaroundMessageBox.h \
    app/util/qrenderstats.h \
    app/vs_util/decodingstatistcs.h


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

HEADERS += \
    app/osd/headingladder.h \
    app/osd/horizonladder.h \
    app/osd/speedladder.h \
    app/osd/altitudeladder.h \
    app/osd/drawingcanvas.h \
    app/osd/flightpathvector.h \
    app/osd/debug_overdraw.hpp \
    app/osd/aoagauge.h \

# I deleted all the "old" telemetry protocolls other than mavlink
# and moved them into their own respective directories
HEADERS += \
    app/telemetry/MavlinkTelemetry.h \
    app/telemetry/settings/mavlinksettingsmodel.h \

SOURCES += \
    app/telemetry/MavlinkTelemetry.cpp \
    app/telemetry/settings/mavlinksettingsmodel.cpp \


# all other files, complete mess
SOURCES += \
    app/telemetry/models/fcmavlinksystem.cpp \
    app/util/FrequencyMonitor.cpp \
    app/main.cpp \

RESOURCES += qml/qml.qrc

HEADERS += \
    app/telemetry/models/fcmavlinksystem.h \
    app/util/FrequencyMonitor.h \
    app/util/sharedqueue.h \

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
    android/src/org/freedesktop/gstreamer/androidmedia/GstAhcCallback.java \
    android/src/org/freedesktop/gstreamer/androidmedia/GstAhsCallback.java \
    android/src/org/freedesktop/gstreamer/androidmedia/GstAmcOnFrameAvailableListener.java \
    app/adsb/adsb_lib.pri \
    app/logging/README.txt \
    app/openhd_systems/README.md \
    app/osd_extra/Readme.txt \
    app/platform/README.md \
    app/telemetry/README.md \
    app/telemetry/settings/README.md \
    app/util/README.md \
    app/videostreaming/README.md \
    app/videostreaming/gst_qmlglsink/gst_video.pri \
    app/videostreaming/legacy/README.md \
    app/videostreaming_util/README.txt \
    extra_build_qmake.sh \
    inc/osd/Readme.md \
    lib/h264nal/h264nal.pri \
    qml/qtquickcontrols2.conf \
    qml/resources/README.md \
    qml/ui/ConfigPopup/README.md \
    qml/ui/elements/README.md \
    qml/ui/qmldir \
    tools/usefull_commands.md \


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
    #CONFIG += EnableCharts
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
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
}

EnableSpeech {
    message("EnableSpeech")
    DEFINES += ENABLE_SPEECH
    QT += texttospeech
}


contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}

contains(ANDROID_TARGET_ARCH,arm64-v8a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}

ANDROID_ABIS = armeabi-v7a
