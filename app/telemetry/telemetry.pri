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
    # mavsdk needs to be built and (semi-installed) locally with BUILD_SHARED_LIBS=OFF (aka as a static library)
    # This is for packaging / releases / recommended for development, since we then have one fever package to install and no issues with updating
    # QOpenHD and/or MAVSDK during development
    # (compared to building and linking shared / dynamically)
    message(mavsdk static (default))
    android {
        message(mavsdk static android)
        MAVSDK_PREBUILTS_PATH= $$PWD/../../lib/mavsdk_prebuilts
        #MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk-android-android-arm/build/android-arm/install
        MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk-android-android-arm/build/android-arm/install
        message($$MAVSDK_PATH)
        INCLUDEPATH += $$MAVSDK_PATH/include
        LIBS += -L$$MAVSDK_PATH/lib/ -lmavsdk
        #ANDROID_EXTRA_LIBS
    } windows {
        message(mavsdk static windows)
        message(todo hard code path to mavsdk)
    }else{
        message(mavsdk static linux)
        # We use the installation path mavsdk uses when it is built and installed on the host system
        MAVSDK_INCLUDE_PATH= /usr/local/include/mavsdk
        MAVSDK_LIB_PATH= /usr/local/lib/libmavsdk.a
        exists($$MAVSDK_LIB_PATH){
            message(MAVSDK lib file exists)
        }else{
            message(see the readme on how to build / install MAVSDK)
        }
        INCLUDEPATH += $$MAVSDK_INCLUDE_PATH
        LIBS += -L$$MAVSDK_LIB_PATH -lmavsdk
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
    app/telemetry/models/fcmavlinkmissionitemsmodel.cpp \

HEADERS += \
    app/telemetry/mavsdk_helper.hpp \
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
    app/telemetry/models/fcmavlinkmissionitemsmodel.h \

DEFINES += QOPENHD_HAS_MAVSDK_MAVLINK_TELEMETRY
