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
        MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk_android/android-arm/install
        #MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk-android-android-arm64/build/android-arm64/install

        # Set the right folder for the compile arch
        contains(ANDROID_TARGET_ARCH, armeabi-v7a) {
            MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk_android/android-arm/install
        } else:contains(ANDROID_TARGET_ARCH, arm64-v8a) {
            MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk_android/android-arm64/install
            #MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk-android-android-arm64-extra
        } else:contains(ANDROID_TARGET_ARCH, x86_64) {
            MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk_android/android-x86_64/install
        } else:contains(ANDROID_TARGET_ARCH, x86) {
            MAVSDK_PATH= $$MAVSDK_PREBUILTS_PATH/mavsdk_android/android-x86/install
        } else {
            message(Unknown ANDROID_TARGET_ARCH $$ANDROID_TARGET_ARCH)
        }
        message(mavsdk path android)
        message($$MAVSDK_PATH)
        INCLUDEPATH += $$MAVSDK_PATH/include
        LIBS += -L$$MAVSDK_PATH/lib/ -lmavsdk
        #ANDROID_EXTRA_LIBS
    } else: windows {
        message(mavsdk static windows)
        MAVSDK_PREBUILT_PATH = $$PWD/../../lib/mavsdk_prebuilts/windows/mavsdk-windows-x64-release
        message(mavsdk path:)
        message($$MAVSDK_PREBUILT_PATH)
        MAVSDK_INCLUDE_PATH= $$MAVSDK_PREBUILT_PATH/include
        MAVSDK_LIB_PATH= $$MAVSDK_PREBUILT_PATH/lib
        INCLUDEPATH +=  $$MAVSDK_INCLUDE_PATH
        LIBS += -L$$MAVSDK_LIB_PATH -lmavsdk
    }else {
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
    $$PWD/action/cmdsender.cpp \
    $$PWD/action/fcaction.cpp \
    $$PWD/action/fcmissionhandler.cpp \
    $$PWD/action/fcmsgintervalhandler.cpp \
    $$PWD/action/ohdaction.cpp \
    $$PWD/connection/udp_connection.cpp \
    $$PWD/models/fcmapmodel.cpp \
    $$PWD/settings/documentedparam.cpp \
    $$PWD/settings/wblinksettingshelper.cpp \
    $$PWD/settings/xparam.cpp \
    app/telemetry/models/aohdsystem.cpp \
    app/telemetry/models/camerastreammodel.cpp \
    app/telemetry/models/rcchannelsmodel.cpp \
    app/telemetry/models/wificard.cpp \
    app/telemetry/settings/improvedintsetting.cpp \
    app/telemetry/settings/improvedstringsetting.cpp \
    app/telemetry/MavlinkTelemetry.cpp \
    app/telemetry/settings/mavlinksettingsmodel.cpp \
    app/telemetry/models/fcmavlinksystem.cpp \
    app/telemetry/models/fcmavlinkmissionitemsmodel.cpp \

HEADERS += \
    $$PWD/action/cmdsender.h \
    $$PWD/action/create_cmd_helper.hpp \
    $$PWD/action/fcaction.h \
    $$PWD/action/fcmissionhandler.h \
    $$PWD/action/fcmsgintervalhandler.h \
    $$PWD/action/ohdaction.h \
    $$PWD/link/mudplink.h \
    $$PWD/settings/documentedparam.h \
    $$PWD/settings/xparam.h \
    $$PWD/util/geodesi_helper.h \
    $$PWD/util/mavlink_enum_to_string.h \
    $$PWD//util/mavsdk_helper.hpp \
    $$PWD//util/mavsdk_include.h \
    $$PWD//util/openhd_defines.hpp \
    $$PWD//util/qopenhdmavlinkhelper.hpp \
    $$PWD//util/telemetryutil.hpp \
    $$PWD/util/mavlink_include.h \
    $$PWD/models/fcmapmodel.h \
    $$PWD/models/fcmessageintervalhelper.hpp \
    $$PWD/settings/wblinksettingshelper.h \
    app/telemetry/models/aohdsystem.h \
    app/telemetry/models/camerastreammodel.h \
    app/telemetry/models/rcchannelsmodel.h \
    app/telemetry/models/wificard.h \
    app/telemetry/settings/improvedintsetting.h \
    app/telemetry/settings/improvedstringsetting.h \
    app/telemetry/MavlinkTelemetry.h \
    app/telemetry/settings/mavlinksettingsmodel.h \
    app/telemetry/models/fcmavlinksystem.h \
    app/telemetry/models/fcmavlinkmissionitemsmodel.h \
    app/telemetry/models/fcmessageintervalhelper.hpp \

DEFINES += QOPENHD_HAS_MAVSDK_MAVLINK_TELEMETRY
