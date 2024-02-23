cmake_minimum_required(VERSION 3.16)

project(QOpenHDProject VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core)
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)
find_package(Qt6 6.5 REQUIRED COMPONENTS Gui)
find_package(Qt6 6.5 REQUIRED COMPONENTS Widgets)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(QOpenHDApp
    app/main.cpp
    #
    app/adsb/adsbvehicle.cpp
    app/adsb/adsbvehiclemanager.cpp
    app/adsb/qmlobjectlistmodel.cpp
    #
    app/util/WorkaroundMessageBox.cpp
    app/util/mousehelper.cpp
    app/util/qopenhd.cpp
    app/util/qrenderstats.cpp
    app/util/restartqopenhdmessagebox.cpp
    #
    app/osd/altitudeladder.cpp
    app/osd/aoagauge.cpp
    app/osd/flightpathvector.cpp
    app/osd/headingladder.cpp
    app/osd/horizonladder.cpp
    app/osd/speedladder.cpp
    #
    app/logging/hudlogmessagesmodel.cpp
    app/logging/logmessagesmodel.cpp
    #
    app/telemetry/MavlinkTelemetry.cpp
    app/telemetry/action/fcaction.cpp
    app/telemetry/action/fcmissionhandler.cpp
    app/telemetry/action/fcmsgintervalhandler.cpp
    app/telemetry/action/ohdaction.cpp
    #
    app/telemetry/action/impl/cmdsender.cpp
    app/telemetry/action/impl/xparam.cpp
    ##
    app/telemetry/connection/mavlinkchannel.cpp
    app/telemetry/connection/tcp_connection.cpp
    app/telemetry/connection/udp_connection.cpp
    #
    app/telemetry/models/aohdsystem.cpp
    app/telemetry/models/camerastreammodel.cpp
    app/telemetry/models/fcmapmodel.cpp
    app/telemetry/models/fcmavlinkmissionitemsmodel.cpp
    app/telemetry/models/fcmavlinksystem.cpp
    app/telemetry/models/markermodel.cpp
    app/telemetry/models/rcchannelsmodel.cpp
    app/telemetry/models/wificard.cpp
    #
    app/telemetry/settings/documentedparam.cpp
    app/telemetry/settings/frequencyhelper.cpp
    app/telemetry/settings/improvedintsetting.cpp
    app/telemetry/settings/improvedstringsetting.cpp
    app/telemetry/settings/mavlinksettingsmodel.cpp
    app/telemetry/settings/pollutionhelper.cpp
    app/telemetry/settings/wblinksettingshelper.cpp

    ###
    #app/videostreaming/vscommon/custom/rawreceiver.cpp
    #app/videostreaming/vscommon/rtp/rtpreceiver.cpp
    #app/videostreaming/vscommon/rtp/ParseRTP.cpp
    app/videostreaming/vscommon/decodingstatistcs.cpp
    app/videostreaming/vscommon/decodingstatistcs.h
    ##
    lib/geographiclib-c-2.0/src/geodesic.c
)

target_include_directories(QOpenHDApp PUBLIC app)
target_include_directories(QOpenHDApp PUBLIC app/common)
target_include_directories(QOpenHDApp PUBLIC app/adsb)
target_include_directories(QOpenHDApp PUBLIC app/logging)
target_include_directories(QOpenHDApp PUBLIC app/osd)
target_include_directories(QOpenHDApp PUBLIC app/util)
target_include_directories(QOpenHDApp PUBLIC app/telemetry)
target_include_directories(QOpenHDApp PUBLIC app/telemetry/util)

target_include_directories(QOpenHDApp PUBLIC app/videostreaming/vscommon)
target_include_directories(QOpenHDApp PUBLIC lib)

qt_add_qml_module(QOpenHDApp
    URI QOpenHDUI
    VERSION 1.0
    QML_FILES qml/main.qml
)


target_link_libraries(QOpenHDApp
    PRIVATE Qt6::Core Qt6::Quick Qt6::Gui Qt6::Widgets
)

#include(GNUInstallDirs)
#install(TARGETS QOpenHD
#    BUNDLE DESTINATION .
#    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#)
