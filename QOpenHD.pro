!equals(QT_MAJOR_VERSION, 5) | !greaterThan(QT_MINOR_VERSION, 6) {
    error("Unsupported Qt version, 5.12+ is required")
}

BASEDIR = $$IN_PWD

LANGUAGE = C++
CONFIG += c++11
CONFIG+=sdk_no_version_check

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
    !iOSBuild {
        !AndroidBuild {
            !RaspberryPiBuild {
                CONFIG += ltcg
            }
        }
    }
    DESTDIR = $${OUT_PWD}/release
    DEFINES += QMLJSDEBUGGER
}


QT += qml quick concurrent opengl gui

INCLUDEPATH += $$PWD/inc
INCLUDEPATH += $$PWD/lib
INCLUDEPATH += $$PWD/lib/mavlink_generated
INCLUDEPATH += $$PWD/lib/mavlink_generated/common
INCLUDEPATH += $$PWD/lib/mavlink_generated/ardupilotmega

INCLUDEPATH += $$PWD/lib/GeographicLib-1.50/include


SOURCES += \
    src/frskytelemetry.cpp \
    src/localmessage.cpp \
    src/ltmtelemetry.cpp \
    src/main.cpp \
    src/mavlinktelemetry.cpp \
    src/msptelemetry.cpp \
    src/openhd.cpp \
    src/openhdpi.cpp \
    src/openhdrc.cpp \
    src/openhdsettings.cpp \
    src/openhdtelemetry.cpp \
    src/openhdvideostream.cpp \
    src/qopenhdlink.cpp \
    src/util.cpp

RESOURCES += qml/qml.qrc

HEADERS += \
    inc/constants.h \
    inc/frskytelemetry.h \
    inc/localmessage.h \
    inc/localmessage_t.h \
    inc/ltmtelemetry.h \
    inc/mavlinktelemetry.h \
    inc/msptelemetry.h \
    inc/openhd.h \
    inc/openhdpi.h \
    inc/openhdrc.h \
    inc/openhdsettings.h \
    inc/openhdtelemetry.h \
    inc/openhdvideostream.h \
    inc/qopenhdlink.h \
    inc/util.h \
    inc/wifibroadcast.h

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
    icons/AppIcon.appiconset/iPad-app.png \
    icons/AppIcon.appiconset/iPad-app@2x.png \
    icons/AppIcon.appiconset/iPad-notifications.png \
    icons/AppIcon.appiconset/iPad-notifications@2x.png \
    icons/AppIcon.appiconset/iPad-pro@2x.png \
    icons/AppIcon.appiconset/iPad-settings.png \
    icons/AppIcon.appiconset/iPad-settings@2x.png \
    icons/AppIcon.appiconset/iPad-spotlight.png \
    icons/AppIcon.appiconset/iPad-spotlight@2x.png \
    icons/AppIcon.appiconset/iPhone-app@2x.png \
    icons/AppIcon.appiconset/iPhone-app@3x.png \
    icons/AppIcon.appiconset/iPhone-notifications@2x.png \
    icons/AppIcon.appiconset/iPhone-notifications@3x.png \
    icons/AppIcon.appiconset/iPhone-settings@2x.png \
    icons/AppIcon.appiconset/iPhone-settings@3x.png \
    icons/AppIcon.appiconset/iPhone-spotlight@2x.png \
    icons/AppIcon.appiconset/iPhone-spotlight@3x.png \
    icons/AppIcon.appiconset/iTunesArtwork@2x.png \
    qml/qtquickcontrols2.conf \
    qml/ui/qmldir



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

#CONFIG += EnableRC


iOSBuild {
    QMAKE_INFO_PLIST    = ios/Info.plist
    ICON                = $${BASEDIR}/icons/macos.icns
    DISTFILES        += ios/Info.plist \
                        icons/LaunchScreen.png \
                        icons/LaunchScreen.storyboard
    LIBS += -framework VideoToolbox -framework AudioToolbox -framework CoreAudio -framework CoreVideo -framework CoreMedia
    CONFIG -= bitcode
    #CONFIG += EnableGamepads
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    CONFIG += EnablePiP
    CONFIG += EnableLink

    #QMAKE_POST_LINK += /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
    #QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
    app_launch_images.files = $$PWD/icons/LaunchScreen.png $$files($$PWD/icons/LaunchScreen.storyboard)
    QMAKE_BUNDLE_DATA += app_launch_images

    ios_icon.files = $$files($$PWD/icons/AppIcon.appiconset/*.png)
    QMAKE_BUNDLE_DATA += ios_icon

    DEFINES += GST_GL_HAVE_WINDOW_EAGL=1
    DEFINES += GST_GL_HAVE_PLATFORM_EAGL=1
    DEFINES += HAVE_QT_IOS
}

MacBuild {
    QMAKE_INFO_PLIST = mac/Info.plist
    ICON = $${BASEDIR}/icons/macos.icns
    DISTFILES += mac/Info.plist
    LIBS += -framework ApplicationServices
    LIBS += -framework VideoToolbox -framework CoreVideo -framework CoreMedia
    CONFIG += EnableRC
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    CONFIG += EnablePiP
    CONFIG += EnableLink

    DEFINES += GST_GL_HAVE_WINDOW_COCOA=1
    DEFINES += GST_GL_HAVE_PLATFORM_CGL=1
    DEFINES += HAVE_QT_MAC
}

LinuxBuild {
    QT += x11extras
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableVideo
    CONFIG += EnablePiP
    CONFIG += EnableLink

    message("LinuxBuild - config")
}

RaspberryPiBuild {
    # we don't enable video here because hello_video handles it,
    # and we dont enable gamepads or joysticks because those are already
    # handled by another process running on the ground station. We could
    # replace that at some point but for now it isn't necessary.
    message("RaspberryPiBuild - config")
    #CONFIG += EnableVideo
    #CONFIG +- EnablePiP
    CONFIG += EnableLink

    DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
    DEFINES += HAVE_QT_EGLFS=1
}

WindowsBuild {
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    #CONFIG +- EnablePiP
    CONFIG += EnableLink

    DEFINES += GST_GL_HAVE_WINDOW_WIN32=1
    DEFINES += GST_GL_HAVE_PLATFORM_WGL=1
    DEFINES += HAVE_QT_WIN32

    INCLUDEPATH += $$PWD/win/include
}

AndroidBuild {
    #CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    CONFIG += EnablePiP
    CONFIG += EnableLink

    QT += androidextras

    OTHER_FILES += \
        $$PWD/android/src/org/openhd/OpenHDActivity.java

    DEFINES += GST_GL_HAVE_PLATFORM_EGL=1
    DEFINES += GST_GL_HAVE_WINDOW_ANDROID=1
    DEFINES += HAVE_QT_ANDROID
}

EnableSpeech {
    message("EnableSpeech")
    DEFINES += ENABLE_SPEECH
    QT += texttospeech
}

EnableVideo {
    message("EnableVideo")
    DEFINES += ENABLE_VIDEO
}

EnablePiP {
    message("EnablePiP")
    DEFINES += ENABLE_PIP
}

EnableLink {
    message("EnableLink")
    DEFINES += ENABLE_LINK
    HEADERS += lib/json.hpp
}

include ($$PWD/lib/VideoStreaming/VideoStreaming.pri)

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
        QMAKE_POST_LINK += $${BASEDIR}/tools/prepare_gstreamer_framework.sh $${DESTDIR}/gstwork $${DESTDIR}/$${TARGET}.app $${TARGET}
        QMAKE_POST_LINK += && cd $${DESTDIR}
        QMAKE_POST_LINK += && $$dirname(QMAKE_QMAKE)/macdeployqt $${TARGET}.app -appstore-compliant -qmldir=$${BASEDIR}/qml

        QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
        QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist

        QMAKE_POST_LINK += && codesign --force --verify --sign \"${DEV_CERT}\" --keychain ${HOME}/Library/Keychains/login.keychain $${TARGET}.app --deep


        QMAKE_POST_LINK += && hdiutil create $${TARGET}.dmg -volname $${TARGET} -fs HFS+ -srcfolder $${DESTDIR}/$${TARGET}.app
        QMAKE_POST_LINK += && hdiutil convert $${TARGET}.dmg -format UDZO -o "$${TARGET}-$${QOPENHD_VERSION}.dmg"

    }
    WindowsBuild {
        OTHER_FILES += tools/qopenhd_installer.nsi
        QMAKE_POST_LINK += c:\Qt\5.13.1\msvc2017\bin\windeployqt.exe --qmldir $${PWD}/qml \"$${DESTDIR_WIN}\\QOpenHD.exe\"

        #QMAKE_POST_LINK += && $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp140.dll\"  \"$$DESTDIR_WIN\"
        #QMAKE_POST_LINK += && $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr140.dll\"  \"$$DESTDIR_WIN\"
        #QMAKE_POST_LINK += && $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcruntime140.dll\"  \"$$DESTDIR_WIN\"

        QMAKE_POST_LINK += $$escape_expand(\\n) cd $$BASEDIR_WIN && $$quote("\"C:\\Program Files \(x86\)\\NSIS\\makensis.exe\"" /DINSTALLER_ICON="\"$${PWD}\icons\openhd.ico\"" /DHEADER_BITMAP="\"$${PWD}\icons\LaunchScreen.png\"" /DAPPNAME="\"QOpenHD\"" /DEXENAME="\"$${TARGET}\"" /DORGNAME="\"Open.HD\"" /DDESTDIR=$${DESTDIR} /NOCD "\"/XOutFile $${DESTDIR_WIN}\\QOpenHD-$${QOPENHD_VERSION}.exe\"" "$$PWD/tools/qopenhd_installer.nsi")

    }
    AndroidBuild {
        QMAKE_POST_LINK += mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && make install INSTALL_ROOT=$${DESTDIR}/android-build/
        #QMAKE_POST_LINK += && androiddeployqt --input $${DESTDIR}/android-libQOpenHD.so-deployment-settings.json --output $${DESTDIR}/android-build --deployment bundled --gradle --sign $${HOME}/.android/android_release.keystore dagar --storepass $$(ANDROID_STOREPASS)
        #QMAKE_POST_LINK += && cp $${DESTDIR}/android-build/build/outputs/apk/android-build-release-signed.apk $${DESTDIR}/package/QOpenHD-$$QOPENHD_VERSION.apk
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





