INCLUDEPATH += $$PWD

#INCLUDEPATH += $$PWD/../../lib/mavlink-headers

SOURCES += \
    $$PWD/action/impl/cmdsender.cpp \
    $$PWD/action/fcaction.cpp \
    $$PWD/action/fcmissionhandler.cpp \
    $$PWD/action/fcmsgintervalhandler.cpp \
    $$PWD/action/ohdaction.cpp \
    $$PWD/connection/mavlinkchannel.cpp \
    $$PWD/connection/tcp_connection.cpp \
    $$PWD/connection/udp_connection.cpp \
    $$PWD/models/fcmapmodel.cpp \
    $$PWD/models/markermodel.cpp \
    $$PWD/settings/documentedparam.cpp \
    $$PWD/settings/frequencyhelper.cpp \
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
    $$PWD/connection/mavlinkchannel.h \
    $$PWD/connection/tcp_connection.h \
    $$PWD/models/markermodel.h \
    $$PWD/models/openhd_core/platform.hpp \
    $$PWD/settings/documentedparam.h \
    $$PWD/action/impl/xparam.h \
    $$PWD/settings/frequencyhelper.h \
    $$PWD/settings/pollutionhelper.h \
    $$PWD/settings/wifi_channel.h \
    $$PWD/tutil/geodesi_helper.h \
    $$PWD/tutil/mavlink_enum_to_string.h \
    $$PWD//tutil/openhd_defines.hpp \
    $$PWD//tutil/qopenhdmavlinkhelper.hpp \
    $$PWD//tutil/telemetryutil.hpp \
    $$PWD/tutil/mavlink_include.h \
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
    app/telemetry/models/openhd_core/camera.hpp \

WindowsBuild{
    LIBS += -lws2_32
}
