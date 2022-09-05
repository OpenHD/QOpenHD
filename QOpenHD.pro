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
#include ($$PWD/lib/SortFilterProxyModel/SortFilterProxyModel.pri)
QT +=core

# weird I have no idea what this one is for
QT += qml

# We need to include this one, needs to be explicitly installed via apt-get on Ubuntu
QT += quick
# Same for this one, install via apt-get
# https://doc.qt.io/qt-5/qgeocoordinate.html
# do not confuse this one with the external library from lib/GeographicLib-1.50
# Consti10 18.08.22 - can be removed, since I got rid of it as a dependency. However,
# we might have to reintroduce it for the map feature - if possible, this should be avoided though.
# QT += positioning

QT += concurrent opengl gui

# I had to remove them, they seem to be obsolete
#QT_FOR_CONFIG += location-private
#qtConfig(geoservices_mapboxgl): QT += sql opengl
#qtConfig(geoservices_osm): QT += concurrent

INCLUDEPATH += $$PWD/inc
INCLUDEPATH += $$PWD/lib
INCLUDEPATH += $$PWD/app
# argh
INCLUDEPATH += $$PWD/app/exp
# argh end
# Since mavlink is coming with MAVSDK, we don't need that anymore
#INCLUDEPATH += $$PWD/lib/c_library_v2_openhd
# mavsdk - dirty
# We have the include path 2 times here, aparently release and debug install to different paths
INCLUDEPATH += /usr/local/include/mavsdk
LIBS += -L/usr/local/lib -lmavsdk
INCLUDEPATH += /usr/include/mavsdk

INCLUDEPATH += $$PWD/lib/GeographicLib-1.50/include

# All files for the OSD elements - these are QT QQuickPaintedItem's that are written in c++
SOURCES += \
    app/logging/logmessagesmodel.cpp \
    app/openhd_systems/aohdsystem.cpp \
    app/osd/headingladder.cpp \
    app/osd/horizonladder.cpp \
    app/osd/speedladder.cpp \
    app/osd/altitudeladder.cpp \
    app/osd/drawingcanvas.cpp \
    app/osd/flightpathvector.cpp \
    app/qopenhd.cpp \
    app/telemetry/settings/synchronizedsettings.cpp \
    app/util/WorkaroundMessageBox.cpp \
    app/videostreaming/decodingstatistcs.cpp \
    app/exp/squircle.cpp \
    #app/exp/squirclerenderer.cpp
    app/exp/texturerenderer.cpp \

HEADERS += \
    app/logging/logmessagesmodel.h \
    app/openhd_systems/aohdsystem.h \
    app/openhd_systems/wifiadapter.h \
    app/osd/headingladder.h \
    app/osd/horizonladder.h \
    app/osd/speedladder.h \
    app/osd/altitudeladder.h \
    app/osd/drawingcanvas.h \
    app/osd/flightpathvector.h \
    app/qopenhd.h \
    app/telemetry/mavlink_include.h \
    app/telemetry/openhd_defines.hpp \
    app/telemetry/qopenhdmavlinkhelper.hpp \
    app/telemetry/settings/documentedsetting.hpp \
    app/telemetry/settings/synchronizedsettings.h \
    app/telemetry/telemetryutil.hpp \
    app/util/WorkaroundMessageBox.h \
    app/videostreaming/decodingstatistcs.h \
    app/exp/squircle.h \
    #app/exp/squirclerenderer.h
    app/exp/texturerenderer.h \


# I deleted all the "old" telemetry protocolls other than mavlink
# and moved them into their own respective directories
HEADERS += \
    app/telemetry/OHDConnection.h \
    app/telemetry/mavlinktelemetry.h \
    app/telemetry/settings/mavlinksettingsmodel.h \

SOURCES += \
    app/telemetry/OHDConnection.cpp \
    app/telemetry/mavlinktelemetry.cpp \
    app/telemetry/settings/mavlinksettingsmodel.cpp \


# all other files, complete mess
SOURCES += \
    app/fcmavlinksystem.cpp \
    app/util/FrequencyMonitor.cpp \
    app/main.cpp \
    app/platform/openhdpi.cpp \
    app/rc/openhdrc.cpp \
    app/util/QmlObjectListModel.cpp \
    app/util/util.cpp \

RESOURCES += qml/qml.qrc \
    qml/qml.qrc

HEADERS += \
    app/fcmavlinksystem.h \
    app/util/FrequencyMonitor.h \
    app/util/sharedqueue.h \
    app/platform/openhdpi.h \
    app/rc/openhdrc.h \
    app/util/QmlObjectListModel.h \
    app/util/util.h \

DISTFILES += \
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
    qml/qtquickcontrols2.conf \
    qml/resources/README.md \
    qml/ui/ConfigPopup/README.md \
    qml/ui/configpopup/legacy/README.md \
    qml/ui/elements/README.md \
    qml/ui/qmldir \
    translations/QOpenHD_it.ts \
    translations/QOpenHD_ro.ts \
    translations/QOpenHD_zh.ts

# Not sure what stephen did here, I think the GeographicLib is manually included and build with QOpenHD
SOURCES += \
    lib/GeographicLib-1.50/src/Accumulator.cpp \
    lib/GeographicLib-1.50/src/AlbersEqualArea.cpp \
    lib/GeographicLib-1.50/src/AzimuthalEquidistant.cpp \
    lib/GeographicLib-1.50/src/CassiniSoldner.cpp \
    lib/GeographicLib-1.50/src/CircularEngine.cpp \
    lib/GeographicLib-1.50/src/DMS.cpp \
    lib/GeographicLib-1.50/src/Ellipsoid.cpp \
    lib/GeographicLib-1.50/src/EllipticFunction.cpp \
    lib/GeographicLib-1.50/src/GARS.cpp \
    lib/GeographicLib-1.50/src/GeoCoords.cpp \
    lib/GeographicLib-1.50/src/Geocentric.cpp \
    lib/GeographicLib-1.50/src/Geodesic.cpp \
    lib/GeographicLib-1.50/src/GeodesicExact.cpp \
    lib/GeographicLib-1.50/src/GeodesicExactC4.cpp \
    lib/GeographicLib-1.50/src/GeodesicLine.cpp \
    lib/GeographicLib-1.50/src/GeodesicLineExact.cpp \
    lib/GeographicLib-1.50/src/Geohash.cpp \
    lib/GeographicLib-1.50/src/Geoid.cpp \
    lib/GeographicLib-1.50/src/Georef.cpp \
    lib/GeographicLib-1.50/src/Gnomonic.cpp \
    lib/GeographicLib-1.50/src/GravityCircle.cpp \
    lib/GeographicLib-1.50/src/GravityModel.cpp \
    lib/GeographicLib-1.50/src/LambertConformalConic.cpp \
    lib/GeographicLib-1.50/src/LocalCartesian.cpp \
    lib/GeographicLib-1.50/src/MGRS.cpp \
    lib/GeographicLib-1.50/src/MagneticCircle.cpp \
    lib/GeographicLib-1.50/src/MagneticModel.cpp \
    lib/GeographicLib-1.50/src/Math.cpp \
    lib/GeographicLib-1.50/src/NormalGravity.cpp \
    lib/GeographicLib-1.50/src/OSGB.cpp \
    lib/GeographicLib-1.50/src/PolarStereographic.cpp \
    lib/GeographicLib-1.50/src/PolygonArea.cpp \
    lib/GeographicLib-1.50/src/Rhumb.cpp \
    lib/GeographicLib-1.50/src/SphericalEngine.cpp \
    lib/GeographicLib-1.50/src/TransverseMercator.cpp \
    lib/GeographicLib-1.50/src/TransverseMercatorExact.cpp \
    lib/GeographicLib-1.50/src/UTMUPS.cpp \
    lib/GeographicLib-1.50/src/Utility.cpp


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
    CONFIG += EnablePiP
    CONFIG += EnableVideoRender
    #CONFIG += EnableCharts
    #CONFIG += EnableLog //does not work due to filepath not set

    app_launch_images.files = $$PWD/icons/LaunchScreen.png $$files($$PWD/icons/LaunchScreen.storyboard)
    QMAKE_BUNDLE_DATA += app_launch_images

    QMAKE_ASSET_CATALOGS += $$PWD/icons/ios/Assets.xcassets

    EnableVideoRender {
        QT += multimedia

        HEADERS += \
            app/videostreaming/openhdapplevideo.h

        SOURCES += \
            app/videostreaming/openhdapplevideo.cpp
    }

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
    CONFIG += EnableRC
    CONFIG += EnableSpeech
    CONFIG += EnableMainVideo
    CONFIG += EnablePiP
    CONFIG += EnableVideoRender
    #CONFIG += EnableCharts
    #CONFIG += EnableLog //does not work due to filepath not set

    EnableVideoRender {
        QT += multimedia

        HEADERS += \
            inc/openhdapplevideo.h

        SOURCES += \
            src/openhdapplevideo.cpp
    }

    EnableGStreamer {
        DEFINES += GST_GL_HAVE_PLATFORM_CGL=1
        DEFINES += GST_GL_HAVE_WINDOW_COCOA=1
        DEFINES += HAVE_QT_MAC
    }
}

LinuxBuild {
    #QT += x11extras
    #CONFIG += EnableGamepads
    #CONFIG += EnableJoysticks
    #CONFIG += EnableRC
    # Note: To compile without gstreamer, uncomment the 3 following - but then obviosly there is no video at all.
    CONFIG += EnableMainVideo
    CONFIG += EnablePiP
    CONFIG += EnableGStreamer
    #CONFIG += EnableCharts
    #CONFIG += EnableLog
    message("LinuxBuild - config")
}

JetsonBuild {
    message("JetsonBuild")
    CONFIG += EnableMainVideo
    CONFIG += EnableJoysticks
    CONFIG += EnableRC
    CONFIG += EnablePiP
    #CONFIG += EnableCharts
    CONFIG += EnableSpeech
    #CONFIG += EnableLog //does not work due to filepath not set
    CONFIG += EnableRC
    CONFIG += EnableJoysticks

    CONFIG += EnableGStreamer

    EnableGStreamer {
        DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
        DEFINES += HAVE_QT_EGLFS=1
    }
}

RaspberryPiBuild {
    # we don't enable video here because hello_video handles it,
    # and we dont enable gamepads or joysticks because those are already
    # handled by another process running on the ground station. We could
    # replace that at some point but for now it isn't necessary.
    message("RaspberryPiBuild - config")
    CONFIG += EnableMainVideo
    CONFIG += EnableJoysticks
    CONFIG += EnableRC
    CONFIG += EnablePiP
    #CONFIG += EnableCharts
    CONFIG += EnableSpeech
    CONFIG += LimitADSBMax
    #CONFIG += EnableLog
    CONFIG += EnableRC
    CONFIG += EnableJoysticks

    CONFIG += EnableVideoRender

    EnableVideoRender {
    }
}

WindowsBuild {
    #CONFIG += EnableGamepads
    #CONFIG += EnableJoysticks
    #CONFIG += EnableRC
    #CONFIG += EnableSpeech
    #CONFIG += EnableMainVideo
    #CONFIG +- EnablePiP
    #CONFIG += EnableGStreamer
    #CONFIG += EnableCharts
    #CONFIG += EnableLog

    DEFINES += GST_GL_HAVE_WINDOW_WIN32=1
    DEFINES += GST_GL_HAVE_PLATFORM_WGL=1
    DEFINES += HAVE_QT_WIN32

    INCLUDEPATH += $$PWD/win/include
}

AndroidBuild {
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableRC
    CONFIG += EnableSpeech
    CONFIG += EnableMainVideo
    CONFIG += EnablePiP
    CONFIG += EnableVideoRender
    #CONFIG += EnableCharts
    #CONFIG += EnableLog

    EnableGStreamer {
        OTHER_FILES += \
            $$PWD/android/src/org/openhd/OpenHDActivity.java

        DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
        DEFINES += GST_GL_HAVE_WINDOW_ANDROID=1
        DEFINES += HAVE_QT_ANDROID
    }

    EnableVideoRender {
        LIBS += -lmediandk
        LIBS += -landroid
        QT += multimedia

        HEADERS += \
            inc/openhdandroidrender.h \
            inc/openhdandroidvideo.h \
            inc/androidsurfacetexture.h


        SOURCES += \
            src/openhdandroidrender.cpp \
            src/openhdandroidvideo.cpp \
            src/androidsurfacetexture.cpp

        OTHER_FILES += \
            $$PWD/android/src/org/openhd/OpenHDActivity.java \
            $$PWD/android/src/org/openhd/SurfaceTextureListener.java
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


EnableLog {
    message("EnableLog")
    DEFINES += ENABLE_LOG
}

EnableCharts {
    message("EnableCharts")
    DEFINES += ENABLE_CHARTS
    QT += charts
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
        app/videostreaming/gstvideostream.cpp

    HEADERS += \
        app/videostreaming/QOpenHDVideoHelper.hpp \
        app/videostreaming/gst_helper.hpp \
        app/videostreaming/gstvideostream.h

    #include ($$PWD/lib/VideoStreaming/VideoStreaming.pri)

    CONFIG += link_pkgconfig
    PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0

    #include(qmlglsink.pri)
    #include(lib/gst-plugins-good/ext/qt/qtplugin.pro)
    #QT += qitem
    #QT += widgets
    #QT += gui-private

}

EnableVideoRender {
    message("EnableVideoRender")

    DEFINES += ENABLE_VIDEO_RENDER

    HEADERS += \
        app/videostreaming/openhdvideo.h \
        app/videostreaming/openhdrender.h

    SOURCES += \
        app/videostreaming/openhdvideo.cpp \
        app/videostreaming/openhdrender.cpp \
        $$PWD/lib/h264/h264_bitstream_parser.cc \
        $$PWD/lib/h264/h264_common.cc \
        $$PWD/lib/h264/pps_parser.cc \
        $$PWD/lib/h264/sps_parser.cc \
        $$PWD/lib/h264/bit_buffer.cc \
        $$PWD/lib/h264/checks.cc \
        $$PWD/lib/h264/zero_memory.cc

    INCLUDEPATH += $$PWD/lib/h264/
}

EnablePiP {
    message("EnablePiP")
    DEFINES += ENABLE_PIP
}


EnableRC {
    message("EnableRC")
    DEFINES += ENABLE_RC

    EnableGamepads {
        message("EnableGamepads")
        DEFINES += ENABLE_GAMEPADS
        QT += gamepad
    }

    EnableJoysticks {
        message("EnableJoysticks")
        DEFINES += ENABLE_JOYSTICKS
        include ($$PWD/QJoysticks/QJoysticks.pri)
    }
}


installer {
    MacBuild {
        DESTDIR_COPY_RESOURCE_LIST = $$DESTDIR/$${TARGET}.app/Contents/MacOS
        EnableGStreamer {
            QMAKE_POST_LINK += $${BASEDIR}/tools/prepare_gstreamer_framework.sh $${DESTDIR}/gstwork $${DESTDIR}/$${TARGET}.app $${TARGET}
            QMAKE_POST_LINK += && cd $${DESTDIR}
        }

        EnableVideoRender {
            QMAKE_POST_LINK += cd $${DESTDIR}
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

