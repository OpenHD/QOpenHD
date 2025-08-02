cmake_minimum_required(VERSION 3.16)

project(QOpenHDProject VERSION 0.1 LANGUAGES C CXX)

# Use the same Qt version you're installing (6.6.3)
set(X_QT_VERSION 6.6.3)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt policy to avoid JSON generator-expression warning on Android
qt_policy(QTP0002 NEW)

# Find required Qt modules in one call
find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS Core Quick Gui Widgets)

# Standard project setup (optional, keeps consistent behavior)
qt_standard_project_setup(REQUIRES ${X_QT_VERSION})

# Ensure an Android ABI is defined (fallback if not passed from outside)
if(NOT DEFINED QT_ANDROID_ABIS)
  set(QT_ANDROID_ABIS "arm64-v8a" CACHE STRING "Android ABIs to build for")
endif()

# Source list
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
    app/telemetry/action/impl/cmdsender.cpp
    app/telemetry/action/impl/xparam.cpp
    app/telemetry/connection/mavlinkchannel.cpp
    app/telemetry/connection/tcp_connection.cpp
    app/telemetry/connection/udp_connection.cpp
    app/telemetry/models/aohdsystem.cpp
    app/telemetry/models/camerastreammodel.cpp
    app/telemetry/models/fcmapmodel.cpp
    app/telemetry/models/fcmavlinkmissionitemsmodel.cpp
    app/telemetry/models/fcmavlinksystem.cpp
    app/telemetry/models/markermodel.cpp
    app/telemetry/models/rcchannelsmodel.cpp
    app/telemetry/models/wificard.cpp
    app/telemetry/settings/documentedparam.cpp
    app/telemetry/settings/frequencyhelper.cpp
    app/telemetry/settings/improvedintsetting.cpp
    app/telemetry/settings/improvedstringsetting.cpp
    app/telemetry/settings/mavlinksettingsmodel.cpp
    app/telemetry/settings/pollutionhelper.cpp
    app/telemetry/settings/wblinksettingshelper.cpp
    app/telemetry/tutil/geodesi_helper.cpp
    #
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

# Define the executable
qt_add_executable(QOpenHDApp
    MANUAL_FINALIZATION
    ${QOPENHD_SOURCE_FILES_LIST}
    lib/geographiclib-c-2.0/src/geodesic.c
    qml/qml.qrc
    androidqt6/AndroidManifest.xml
)

# Include directories
target_include_directories(QOpenHDApp PUBLIC
    app
    app/common
    app/adsb
    app/logging
    app/osd
    app/util
    app/telemetry
    app/telemetry/util
    app/videostreaming/vscommon
    lib
    lib/geographiclib-c-2.0/src
)

# Link Qt libraries
target_link_libraries(QOpenHDApp
    PRIVATE Qt6::Core Qt6::Quick Qt6::Gui Qt6::Widgets
)

# Android packaging source
set_property(TARGET QOpenHDApp APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
             ${CMAKE_CURRENT_SOURCE_DIR}/androidqt6)

# Optional: include additional cmake fragments
include(lib/h264/h264.cmake)
# include(app/videostreaming/avcodec/avcodec_video.cmake)
# include(app/videostreaming/android/videostreamingandroid.cmake)
# include(app/videostreaming/gstreamer/gst_video.cmake)

# Finalize the executable (needed because of MANUAL_FINALIZATION)
qt_finalize_executable(QOpenHDApp)
