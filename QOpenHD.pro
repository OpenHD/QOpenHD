!equals(QT_MAJOR_VERSION, 5) | !greaterThan(QT_MINOR_VERSION, 6) {
    error("Unsupported Qt version, 5.7+ is required")
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
    DEFINES += QGC_INSTALL_RELEASE
}


QT += qml quick multimedia concurrent opengl gui

INCLUDEPATH += $$PWD/inc
INCLUDEPATH += $$PWD/lib/mavlink_generated
INCLUDEPATH += $$PWD/lib/mavlink_generated/common
INCLUDEPATH += $$PWD/lib/mavlink_generated/ardupilotmega

SOURCES += \
    src/localmessage.cpp \
    src/main.cpp \
    src/mavlinktelemetry.cpp \
    src/openhdpi.cpp \
    src/openhdrc.cpp \
    src/openhdsettings.cpp \
    src/openhdtelemetry.cpp \
    src/openhdvideostream.cpp \
    src/util.cpp \
    src/wifibroadcast.cpp

RESOURCES += qml/qml.qrc

HEADERS += \
    inc/constants.h \
    inc/localmessage.h \
    inc/localmessage_t.h \
    inc/mavlinktelemetry.h \
    inc/openhdpi.h \
    inc/openhdrc.h \
    inc/openhdsettings.h \
    inc/openhdtelemetry.h \
    inc/openhdvideostream.h \
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



#CONFIG += EnableRC


iOSBuild {
    QMAKE_INFO_PLIST    = ios/Info.plist
    ICON                = $${BASEDIR}/icons/macos.icns
    DISTFILES        += ios/Info.plist \
                        icons/LaunchScreen.png \
                        icons/LaunchScreen.storyboard
    LIBS += -framework VideoToolbox -framework AudioToolbox -framework CoreAudio
    CONFIG -= bitcode
    CONFIG += EnableGamepads
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    #QMAKE_POST_LINK += /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
    #QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
    app_launch_images.files = $$PWD/icons/LaunchScreen.png $$files($$PWD/icons/LaunchScreen.storyboard)
    QMAKE_BUNDLE_DATA += app_launch_images

    ios_icon.files = $$files($$PWD/icons/AppIcon.appiconset/*.png)
    QMAKE_BUNDLE_DATA += ios_icon
}

MacBuild {
    QMAKE_INFO_PLIST = mac/Info.plist
    ICON = $${BASEDIR}/icons/macos.icns
    DISTFILES += mac/Info.plist
    LIBS += -framework ApplicationServices
    LIBS += -framework VideoToolbox
    CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo

    QMAKE_POST_LINK += /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
    QMAKE_POST_LINK += && /usr/libexec/PlistBuddy -c \"Set :CFBundleVersion $$APPLE_BUILD\" $$DESTDIR/$${TARGET}.app/Contents/Info.plist
}

LinuxBuild {
    CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableVideo
    message("LinuxBuild - config")
}

RaspberryPiBuild {
    # we don't enable video here because hello_video handles it,
    # and we dont enable gamepads or joysticks because those are already
    # handled by another process running on the ground station. We could
    # replace that at some point but for now it isn't necessary.
    message("RaspberryPiBuild - config")
}

WindowsBuild {
    CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
}

AndroidBuild {
    CONFIG += EnableGamepads
    CONFIG += EnableJoysticks
    CONFIG += EnableSpeech
    CONFIG += EnableVideo
    QT += androidextras
}

EnableSpeech {
    message("EnableSpeech")
    DEFINES += ENABLE_SPEECH
    QT += texttospeech
}

EnableVideo {
    message("EnableVideo")
    DEFINES += ENABLE_VIDEO
    include ($$PWD/src/VideoStreaming/VideoStreaming.pri)

    HEADERS += \
        $$BASEDIR/src/VideoStreaming/VideoItem.h \
        $$BASEDIR/src/VideoStreaming/VideoReceiver.h \
        $$BASEDIR/src/VideoStreaming/VideoSurface.h \
        $$BASEDIR/src/VideoStreaming/VideoStreaming.h

    SOURCES += \
        $$BASEDIR/src/VideoStreaming/VideoItem.cc \
        $$BASEDIR/src/VideoStreaming/VideoReceiver.cc \
        $$BASEDIR/src/VideoStreaming/VideoSurface.cc \
        $$BASEDIR/src/VideoStreaming/VideoStreaming.cc
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
        QMAKE_POST_LINK += && $${BASEDIR}/tools/prepare_gstreamer_framework.sh $${DESTDIR}/gstwork $${DESTDIR}/$${TARGET}.app $${TARGET}
        QMAKE_POST_LINK += && mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && cd $${DESTDIR} && $$dirname(QMAKE_QMAKE)/macdeployqt OpenHD.app -appstore-compliant -verbose=2 -qmldir=$${BASEDIR}/qml
        QMAKE_POST_LINK += && cd $${OUT_PWD}
        QMAKE_POST_LINK += && hdiutil create -verbose -stretch 3g -layout SPUD -srcfolder $${DESTDIR}/OpenHD.app -volname OpenHD $${DESTDIR}/package/OpenHD.dmg
    }
    WindowsBuild {
        QMAKE_POST_LINK += $$escape_expand(\\n) cd $$BASEDIR_WIN && $$quote("\"C:\\Program Files \(x86\)\\NSIS\\makensis.exe\"" /NOCD "\"/XOutFile $${DESTDIR_WIN}\\OpenHD-installer.exe\"" "$$BASEDIR_WIN\\deploy\\openhd_installer.nsi")
        OTHER_FILES += deploy/openhd_installer.nsi
    }
    AndroidBuild {
        QMAKE_POST_LINK += && mkdir -p $${DESTDIR}/package
        QMAKE_POST_LINK += && make install INSTALL_ROOT=$${DESTDIR}/android-build/
        QMAKE_POST_LINK += && androiddeployqt --input android-libOpenHD.so-deployment-settings.json --output $${DESTDIR}/android-build --deployment bundled --gradle --sign $${BASEDIR}/android/android_release.keystore dagar --storepass $$(ANDROID_STOREPASS)
        QMAKE_POST_LINK += && cp $${DESTDIR}/android-build/build/outputs/apk/android-build-release-signed.apk $${DESTDIR}/package/OpenHD-$$QOPENHD_VERSION.apk
    }
}



contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}





