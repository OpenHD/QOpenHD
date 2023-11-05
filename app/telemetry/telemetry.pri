INCLUDEPATH += $$PWD

#INCLUDEPATH += $$PWD/../../lib/mavlink-headers

SOURCES += \
    $$PWD/action/impl/cmdsender.cpp \
    $$PWD/action/fcaction.cpp \
    $$PWD/action/fcmissionhandler.cpp \
    $$PWD/action/fcmsgintervalhandler.cpp \
    $$PWD/action/ohdaction.cpp \
    $$PWD/connection/tcp_connection.cpp \
    $$PWD/connection/udp_connection.cpp \
    $$PWD/models/fcmapmodel.cpp \
    $$PWD/settings/documentedparam.cpp \
    $$PWD/settings/pollutionhelper.cpp \
    $$PWD/settings/wblinksettingshelper.cpp \
    $$PWD/action/impl/xparam.cpp \
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
    $$PWD/action/impl/cmdsender.h \
    $$PWD/action/create_cmd_helper.hpp \
    $$PWD/action/fcaction.h \
    $$PWD/action/fcmissionhandler.h \
    $$PWD/action/fcmsgintervalhandler.h \
    $$PWD/action/ohdaction.h \
    $$PWD/connection/tcp_connection.h \
    $$PWD/settings/documentedparam.h \
    $$PWD/action/impl/xparam.h \
    $$PWD/settings/pollutionhelper.h \
    $$PWD/util/geodesi_helper.h \
    $$PWD/util/mavlink_enum_to_string.h \
    $$PWD//util/openhd_defines.hpp \
    $$PWD//util/qopenhdmavlinkhelper.hpp \
    $$PWD//util/telemetryutil.hpp \
    $$PWD/util/mavlink_include.h \
    $$PWD/models/fcmapmodel.h \
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

WindowsBuild{
    LIBS += -lws2_32
}
