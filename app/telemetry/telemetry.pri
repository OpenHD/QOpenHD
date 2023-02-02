INCLUDEPATH += $$PWD

# NOTE: MAVSDK needs to be built and installed manually (since it doesn't support QMake's .pro)
# also note that mavlink (openhd flavour) comes with MAVSDK (since it is needed for building MAVSDK anyways)
# uncomment out below if you wanna use MAVSDK shared for some reason
#CONFIG += QOPENHD_LINK_MAVSDK_SHARED
QOPENHD_LINK_MAVSDK_SHARED {
    # mavsdk needs to be built and installed locally with BUILD_SHARED_LIBS=ON
    message(mavsdk shared)
    message(not recommended and only supported on linux)
    # We have the include path 2 times here, from MAVSDK docs:
    # The mavsdk library installed via a .deb or .rpm file will be installed in /usr/ while the built library will be installed in /usr/local
    INCLUDEPATH += /usr/local/include/mavsdk
    INCLUDEPATH += /usr/include/mavsdk
    LIBS += -L/usr/local/lib -lmavsdk
} else {
    # mavsdk needs to be built and (semi-installed) locally with BUILD_SHARED_LIBS=OFF
    # This is for packaging / releases / recommended for development, since we then have one fever package to install and no issues with updating
    # QOpenHD and/or MAVSDK during development
    message(mavsdk static)
    android {
        message(mavsdk static android)

        INCLUDEPATH += /home/consti10//Downloads/MAVSDK/mavsdk-android-android-arm/build/android-arm/install/include
        LIBS += -L/home/consti10/Downloads/MAVSDK/mavsdk-android-android-arm/build/android-arm/install/lib/ -lmavsdk
        #ANDROID_EXTRA_LIBS
    } windows {
        message(mavsdk static windows)
    }else{
        message(mavsdk static linux)
        INCLUDEPATH += /usr/local/include/mavsdk
        LIBS += -L/usr/local/lib/libmavsdk.a -lmavsdk
        # weird rpi
        LIBS += -latomic
    }
}

SOURCES += \
    app/telemetry/models/aohdsystem.cpp \
    app/telemetry/models/camerastreammodel.cpp \
    app/telemetry/models/rcchannelsmodel.cpp \
    app/telemetry/models/wificard.cpp \
    app/telemetry/settings/improvedintsetting.cpp \
    app/telemetry/settings/improvedstringsetting.cpp \
    app/telemetry/settings/synchronizedsettings.cpp \
    app/telemetry/MavlinkTelemetry.cpp \
    app/telemetry/settings/mavlinksettingsmodel.cpp \
    app/telemetry/models/fcmavlinksystem.cpp \

HEADERS += \
    app/telemetry/mavsdk_include.h \
    app/telemetry/models/aohdsystem.h \
    app/telemetry/models/camerastreammodel.h \
    app/telemetry/models/rcchannelsmodel.h \
    app/telemetry/models/wificard.h \
    app/telemetry/openhd_defines.hpp \
    app/telemetry/qopenhdmavlinkhelper.hpp \
    app/telemetry/settings/improvedintsetting.h \
    app/telemetry/settings/improvedstringsetting.h \
    app/telemetry/settings/synchronizedsettings.h \
    app/telemetry/telemetryutil.hpp \
    app/telemetry/MavlinkTelemetry.h \
    app/telemetry/settings/mavlinksettingsmodel.h \
    app/telemetry/models/fcmavlinksystem.h \

DEFINES += QOPENHD_HAS_MAVSDK_MAVLINK_TELEMETRY
