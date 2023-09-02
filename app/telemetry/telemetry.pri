INCLUDEPATH += $$PWD

#INCLUDEPATH += $$PWD/../../lib/mavlink-headers

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
