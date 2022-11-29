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
QMAKE_CXXFLAGS += -Wno-address-of-packed-member
QMAKE_CXXFLAGS += -Wno-cast-align

#QT += qml quick concurrent opengl gui
#QT += positioning location

#Not sure what exactly is going on here, but maybe this lib made it into qt official ?!!
#since there is https://doc.qt.io/qt-5/qsortfilterproxymodel.html#details
# Consti10: Dependency removed
#include ($$PWD/lib/SortFilterProxyModel/SortFilterProxyModel.pri)
# Comes with pretty much any install
QT +=core

# We need this for our qml files, available pretty much anywhere
QT += qml

# We need to include this one, needs to be explicitly installed via apt-get on Ubuntu
QT += quick
QT += concurrent opengl gui

INCLUDEPATH += $$PWD/lib
INCLUDEPATH += $$PWD/app
INCLUDEPATH += $$PWD/app/exp

# Since mavlink is coming with MAVSDK, we don't need that anymore
#INCLUDEPATH += $$PWD/lib/c_library_v2_openhd
# mavsdk - dirty
# We have the include path 2 times here, aparently release and debug install to different paths
INCLUDEPATH += /usr/local/include/mavsdk
LIBS += -L/usr/local/lib -lmavsdk
INCLUDEPATH += /usr/include/mavsdk


# Avcodec decode and display, all sources
# Replaced gstreamer for now
# Comment the line below to build without avcodec (you won't have any video decoding capabilities in this case though)
# However, this can be usefully for figuring out compiler issue(s) on different platform(s)
# NOTE: QT Creator is quite bad at figuring out changes here, you might need a "full" rebuild or manualy delete
# the build dir/cache, then rebuild
# NOTE: You manually have to uncomment 3 lines in qml/main.qml too for now (if you choose to uncomment below)
include(app/exp/avcodec_video.pri)


# All Generic files. NOTE: During development, when you create new files, QT Creater will add them to the
# "first SOURCES / HEADERS it can find in the .pro, which is here". This is why (as an example) geographic lib,
# which is a library, comes after the generic files here.
SOURCES += \
    app/logging/hudlogmessagesmodel.cpp \
    app/logging/logmessagesmodel.cpp \
    app/telemetry/models/aohdsystem.cpp \
    app/qopenhd.cpp \
    app/telemetry/models/rcchannelsmodel.cpp \
    app/telemetry/settings/improvedintsetting.cpp \
    app/telemetry/settings/improvedstringsetting.cpp \
    app/telemetry/settings/synchronizedsettings.cpp \
    app/util/WorkaroundMessageBox.cpp \
    app/util/qrenderstats.cpp \
    app/videostreaming/decodingstatistcs.cpp \

HEADERS += \
    app/common_consti/EmulatedPacketDrop.hpp \
    app/logging/hudlogmessagesmodel.h \
    app/logging/loghelper.h \
    app/logging/logmessagesmodel.h \
    app/telemetry/mavsdk_include.h \
    app/telemetry/models/aohdsystem.h \
    app/telemetry/models/rcchannelsmodel.h \
    app/telemetry/models/wifiadapter.h \
    app/qopenhd.h \
    app/telemetry/openhd_defines.hpp \
    app/telemetry/qopenhdmavlinkhelper.hpp \
    app/telemetry/settings/improvedintsetting.h \
    app/telemetry/settings/improvedstringsetting.h \
    app/telemetry/settings/synchronizedsettings.h \
    app/telemetry/telemetryutil.hpp \
    app/util/WorkaroundMessageBox.h \
    app/util/qrenderstats.h \
    app/videostreaming/decodingstatistcs.h \


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
    app/util/QmlObjectListModel.cpp \

RESOURCES += qml/qml.qrc \
    qml/qml.qrc

HEADERS += \
    app/telemetry/models/fcmavlinksystem.h \
    app/util/FrequencyMonitor.h \
    app/util/sharedqueue.h \
    app/util/QmlObjectListModel.h \

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
    app/adsb/README.md \
    app/logging/README.txt \
    app/openhd_systems/README.md \
    app/osd_extra/Readme.txt \
    app/platform/README.md \
    app/telemetry/README.md \
    app/telemetry/settings/README.md \
    app/util/README.md \
    app/videostreaming/README.md \
    app/videostreaming/legacy/README.md \
    extra_build_qmake.sh \
    inc/osd/Readme.md \
    lib/h264nal/h264nal.pri \
    qml/qtquickcontrols2.conf \
    qml/resources/README.md \
    qml/ui/ConfigPopup/README.md \
    qml/ui/elements/README.md \
    qml/ui/qmldir \
    tools/usefull_commands.md \
    translations/QOpenHD_it.ts \
    translations/QOpenHD_ro.ts \
    translations/QOpenHD_zh.ts


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

    EnableGStreamer {
        DEFINES += GST_GL_HAVE_WINDOW_EAGL=1
        DEFINES += GST_GL_HAVE_PLATFORM_EAGL=1
        DEFINES += HAVE_QT_IOS
    }
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
    CONFIG += EnableMainVideo
    #CONFIG += EnableCharts
    #CONFIG += EnableLog //does not work due to filepath not set

    EnableGStreamer {
        DEFINES += GST_GL_HAVE_PLATFORM_CGL=1
        DEFINES += GST_GL_HAVE_WINDOW_COCOA=1
        DEFINES += HAVE_QT_MAC
    }
}

LinuxBuild {
    CONFIG += EnableMainVideo
    message("LinuxBuild - config")
}

JetsonBuild {
    message("JetsonBuild")
    CONFIG += EnableMainVideo
    CONFIG += EnableSpeech

    CONFIG += EnableGStreamer

    EnableGStreamer {
        DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
        DEFINES += HAVE_QT_EGLFS=1
    }
}


WindowsBuild {
    #CONFIG += EnableGamepads
    #CONFIG += EnableSpeech
    #CONFIG += EnableMainVideo
    #CONFIG += EnableGStreamer
    #CONFIG += EnableCharts
    #CONFIG += EnableLog

    DEFINES += GST_GL_HAVE_WINDOW_WIN32=1
    DEFINES += GST_GL_HAVE_PLATFORM_WGL=1
    DEFINES += HAVE_QT_WIN32

    INCLUDEPATH += $$PWD/win/include
}

AndroidBuild {
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableMainVideo
    #CONFIG += EnableCharts
    #CONFIG += EnableLog

    EnableGStreamer {
        OTHER_FILES += \
            $$PWD/android/src/org/openhd/OpenHDActivity.java

        DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
        DEFINES += GST_GL_HAVE_WINDOW_ANDROID=1
        DEFINES += HAVE_QT_ANDROID
    }
    QT += androidextras

    #Androidx86Build {
    #    ANDROID_EXTRA_LIBS += $$PWD/lib/android/openssl/latest/x86/libcrypto_1_1.so \
    #                          $$PWD/lib/android/openssl/latest/x86/libssl_1_1.so
    #} AndroidARM64Build {
    #    ANDROID_EXTRA_LIBS += $$PWD/lib/android/openssl/latest/arm64/libcrypto_1_1.so \
    #                          $$PWD/lib/android/openssl/latest/arm64/libssl_1_1.so
    #} else {
        ANDROID_EXTRA_LIBS += $$PWD/lib/android/openssl/latest/arm/libcrypto_1_1.so \
                              $$PWD/lib/android/openssl/latest/arm/libssl_1_1.so
    #}
}


EnableSpeech {
    message("EnableSpeech")
    DEFINES += ENABLE_SPEECH
    QT += texttospeech
}

EnableMainVideo {
    message("EnableMainVideo")
    DEFINES += ENABLE_MAIN_VIDEO
}

EnableGStreamer {
    DEFINES += ENABLE_GSTREAMER

    SOURCES += \
        app/videostreaming/gst_qmlglsink/gstvideostream.cpp

    HEADERS += \
        app/videostreaming/gst_qmlglsink/gst_helper.hpp \
        app/videostreaming/gst_qmlglsink/gstvideostream.h

    CONFIG += link_pkgconfig
    PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0

    #include(qmlglsink.pri)
    #include(lib/gst-plugins-good/ext/qt/qtplugin.pro)
    #QT += qitem
    #QT += widgets
    #QT += gui-private
}


installer {
    MacBuild {
        DESTDIR_COPY_RESOURCE_LIST = $$DESTDIR/$${TARGET}.app/Contents/MacOS
        EnableGStreamer {
            QMAKE_POST_LINK += $${BASEDIR}/tools/prepare_gstreamer_framework.sh $${DESTDIR}/gstwork $${DESTDIR}/$${TARGET}.app $${TARGET}
            QMAKE_POST_LINK += && cd $${DESTDIR}
        }

        QMAKE_POST_LINK += && $$dirname(QMAKE_QMAKE)/macdeployqt $${TARGET}.app -appstore-compliant -qmldir=$${BASEDIR}/qml

        QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
        QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist

        IS_TRAVIS = $$(TRAVIS)

        !isEmpty(IS_TRAVIS) {
            QMAKE_POST_LINK += && codesign --force --verify --sign \"${DEV_CERT}\" --keychain ${PWD}/openhd.keychain $${TARGET}.app --deep
        } else {
            QMAKE_POST_LINK += && codesign --force --verify --sign \"${DEV_CERT}\" --keychain ${HOME}/Library/Keychains/login.keychain $${TARGET}.app --deep
        }



        QMAKE_POST_LINK += && hdiutil create $${TARGET}.dmg -volname $${TARGET} -fs HFS+ -srcfolder $${DESTDIR}/$${TARGET}.app
        QMAKE_POST_LINK += && hdiutil convert $${TARGET}.dmg -format UDZO -o "$${TARGET}-$${QOPENHD_VERSION}.dmg"

    }
    WindowsBuild {
        DESTDIR_WIN = $$replace(DESTDIR, "/", "\\")

        OTHER_FILES += tools/qopenhd_installer.nsi
        QMAKE_POST_LINK +=$${PWD}/win_deploy_sdl.cmd \"$$DESTDIR_WIN\" \"$$PWD\QJoysticks\lib\SDL\bin\windows\msvc\x86\" $$escape_expand(\\n)

        QMAKE_POST_LINK += $$escape_expand(\\n) c:\Qt\5.15.2\msvc2019\bin\windeployqt.exe --qmldir $${PWD}/qml \"$${DESTDIR_WIN}\\QOpenHD.exe\"

        QMAKE_POST_LINK += $$escape_expand(\\n) cd $$BASEDIR_WIN && $$quote("\"C:\\Program Files \(x86\)\\NSIS\\makensis.exe\"" /DINSTALLER_ICON="\"$${PWD}\icons\openhd.ico\"" /DHEADER_BITMAP="\"$${PWD}\icons\LaunchScreen.png\"" /DAPPNAME="\"QOpenHD\"" /DEXENAME="\"$${TARGET}\"" /DORGNAME="\"Open.HD\"" /DDESTDIR=$${DESTDIR} /NOCD "\"/XOutFile $${DESTDIR_WIN}\\QOpenHD-$${QOPENHD_VERSION}.exe\"" "$$PWD/tools/qopenhd_installer.nsi")

    }
    AndroidBuild {
        QMAKE_POST_LINK += mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && make install INSTALL_ROOT=$${DESTDIR}/android-build/
    }
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

