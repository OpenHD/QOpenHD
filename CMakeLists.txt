cmake_minimum_required(VERSION 3.16)

project(QOpenHDProject VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CMakeDependentOption)

cmake_dependent_option(ENABLE_FORCE_EGLFS
    "Force use of EGLFS"
    OFF
    "NOT WIN32"
    OFF)

if(ENABLE_FORCE_EGLFS)
    add_definitions(-DFORCE_EGLFS)
endif()

# v4l2 not available on windows. But also not enabled by default on linux
cmake_dependent_option(ENABLE_V4L2_GL_PLAYER
    "Enable built-in V4L2 decoding and GL presenting (Linux only)"
    OFF
    "NOT WIN32"
    OFF)

if(ENABLE_V4L2_GL_PLAYER AND WIN32)
    message(FATAL_ERROR "V4L2 is a Linux kernel API and cannot be used on Windows")
endif()

if(ENABLE_V4L2_GL_PLAYER)
    add_definitions(-DENABLE_V4L2_GL_PLAYER)
endif()

# v4l2-qt player use uvgRTP for RTP RX
cmake_dependent_option(ENABLE_UVGRTP
    "Enable uvgRTP library for rtp receiving"
    ON
    "ENABLE_V4L2_GL_PLAYER"
    OFF)

if(ENABLE_UVGRTP)
    include(FetchContent)

    FetchContent_Declare(
        uvgRTP
        GIT_REPOSITORY https://github.com/ultravideo/uvgRTP.git
        GIT_TAG v3.1.6
    )
    set(UVGRTP_DISABLE_TESTS ON CACHE INTERNAL "")
    set(UVGRTP_DISABLE_EXAMPLES ON CACHE INTERNAL "")
    set(UVGRTP_DISABLE_CRYPTO ON CACHE INTERNAL "")
    set(UVGRTP_DISABLE_INSTALL ON CACHE INTERNAL "")

    if(CMAKE_BUILD_TYPE MATCHES "^(Release|RelWithDebInfo|MinSizeRel)$")
        set(UVGRTP_DISABLE_PRINTS 1 CACHE INTERNAL "")
    endif()

    FetchContent_MakeAvailable(uvgRTP)
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(X_QT_VERSION 6.4)

find_package(Qt6 ${X_QT_VERSION} REQUIRED COMPONENTS
    Core
    Quick
    Gui
    Widgets
    LinguistTools
    Charts
    Core5Compat
    Qml
    QuickControls2
    ShaderTools
)

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
    app/telemetry/models/mavlinkmessagestatsmodel.cpp
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

# Compile shaders for Qt6
qt_add_shaders(QOpenHDApp "colorwheel_shaders"
    BATCHABLE
    PRECOMPILE
    OPTIMIZED
    PREFIX
        "/shaders"
    FILES
        qml/ui/elements/colorwheel/colorwheel.vert
        qml/ui/elements/colorwheel/colorwheel.frag
)

# Translation files
set(QOPENHD_TS_FILES
    translations/QOpenHD_en.ts
    translations/QOpenHD_de.ts
    translations/QOpenHD_uk.ts
    translations/QOpenHD_ru.ts
    translations/QOpenHD_nl.ts
    translations/QOpenHD_es.ts
    translations/QOpenHD_fr.ts
    translations/QOpenHD_zh.ts
    translations/QOpenHD_it.ts
    translations/QOpenHD_ro.ts
)

qt_add_translations(QOpenHDApp
    TS_FILES ${QOPENHD_TS_FILES}
    QM_FILES_OUTPUT_VARIABLE QOPENHD_QM_FILES
    LUPDATE_OPTIONS -no-obsolete
    LRELEASE_OPTIONS -compress
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


target_link_libraries(QOpenHDApp
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::Widgets
        Qt6::Charts
        Qt6::Core5Compat
        Qt6::Qml
        Qt6::QuickControls2
)

set_property(TARGET QOpenHDApp APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
             ${CMAKE_CURRENT_SOURCE_DIR}/androidqt6)

include(lib/h264/h264.cmake)
#include(app/videostreaming/avcodec/avcodec_video.cmake)
#include(app/videostreaming/android/videostreamingandroid.cmake)
#include(app/videostreaming/gstreamer/gst_video.cmake)

# Manual finalization instead of qt_finalize_executable() to avoid
# QML plugin import warnings. The project uses dynamic QML loading via qrc.
if(ANDROID)
    _qt_internal_android_generate_deployment_settings(QOpenHDApp)
    _qt_internal_android_create_deployment_target(QOpenHDApp)
endif()

if(WIN32)
    set_target_properties(QOpenHDApp PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

if(APPLE AND NOT IOS)
    set_target_properties(QOpenHDApp PROPERTIES MACOSX_BUNDLE TRUE)
endif()

# Copy generated .qm files to qml directory for qml.qrc
foreach(QM_FILE ${QOPENHD_QM_FILES})
    get_filename_component(QM_FILENAME ${QM_FILE} NAME)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/qml/${QM_FILENAME}
        COMMAND ${CMAKE_COMMAND} -E copy ${QM_FILE} ${CMAKE_CURRENT_SOURCE_DIR}/qml/${QM_FILENAME}
        DEPENDS ${QM_FILE}
        COMMENT "Copying ${QM_FILENAME} to qml directory for qrc inclusion"
    )
    list(APPEND QM_COPY_FILES ${CMAKE_CURRENT_SOURCE_DIR}/qml/${QM_FILENAME})
endforeach()

add_custom_target(copy_qm_files ALL DEPENDS ${QM_COPY_FILES})

# Ensure generated translation files exist before processing the qml.qrc resource
if(TARGET QOpenHDApp_autogen)
    add_dependencies(QOpenHDApp_autogen copy_qm_files)
endif()

#include(GNUInstallDirs)
#install(TARGETS QOpenHD
#    BUNDLE DESTINATION .
#    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
#)
