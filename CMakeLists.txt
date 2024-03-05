cmake_minimum_required(VERSION 3.16)

project(QOpenHDProject VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(X_QT_VERSION 6.4)


find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Core)
find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Quick)
find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Gui)
find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Widgets)

qt_standard_project_setup(REQUIRES ${X_QT_VERSION})

set(QOPENHD_SOURCE_FILES_LIST
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
    #
    app/telemetry/tutil/geodesi_helper.cpp

    ###
    #app/videostreaming/vscommon/custom/rawreceiver.cpp
    #app/videostreaming/vscommon/rtp/rtpreceiver.cpp
    #app/videostreaming/vscommon/rtp/ParseRTP.cpp
    app/videostreaming/vscommon/decodingstatistcs.cpp
    app/videostreaming/vscommon/audio_playback.cpp
    app/videostreaming/vscommon/rtp/ParseRTP.cpp
    app/videostreaming/vscommon/rtp/rtpreceiver.cpp
    app/videostreaming/vscommon/udp/UDPReceiver.cpp
    app/videostreaming/vscommon/decodingstatistcs.cpp
)

qt_add_executable(QOpenHDApp
    MANUAL_FINALIZATION
    ${QOPENHD_SOURCE_FILES_LIST}
    ##
    lib/geographiclib-c-2.0/src/geodesic.c
    ##
    qml/qml.qrc
    ##
    androidqt6/AndroidManifest.xml
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
target_include_directories(QOpenHDApp PUBLIC lib/geographiclib-c-2.0/src)

#qt_add_qml_module(QOpenHDApp
#    URI hello
#    VERSION 1.0
#    QML_FILES
#        qml/main.qml
#        qml/ui/AnyParamBusyIndicator.qml
#        qml/ui/HUDOverlayGrid.qml
#        qml/ui/elements/
#        qml/ui/sidebar/
#        qml/ui/widgets/
#)
#qt6_add_resources(qml_QRC
#    PREFIX "/"
#    qml/qml.qrc)


target_link_libraries(QOpenHDApp
    PRIVATE Qt6::Core Qt6::Quick Qt6::Gui Qt6::Widgets
)

set_property(TARGET QOpenHDApp APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
             ${CMAKE_CURRENT_SOURCE_DIR}/androidqt6)

include(lib/h264/h264.cmake)
#include(app/videostreaming/avcodec/avcodec_video.cmake)
#include(app/videostreaming/android/videostreamingandroid.cmake)
#include(app/videostreaming/gstreamer/gst_video.cmake)

qt_finalize_executable(QOpenHDApp)
#include(GNUInstallDirs)
#install(TARGETS QOpenHD
#    BUNDLE DESTINATION .
#    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#)
