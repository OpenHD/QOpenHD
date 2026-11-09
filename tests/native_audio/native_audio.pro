QT += core gui multimedia network qml testlib
qtHaveModule(texttospeech) {
    QT += texttospeech
    DEFINES += ENABLE_SPEECH
}
CONFIG += console c++17 testcase
CONFIG -= app_bundle
TEMPLATE = app
TARGET = native_audio_test
DEFINES += QOPENHD_ENABLE_QT_AUDIO
INCLUDEPATH += ../../app
SOURCES += tst_native_audio.cpp ../../app/util/audioannouncements.cpp ../../app/videostreaming/vscommon/qt_audio_player.cpp
HEADERS += ../../app/util/audioannouncements.h ../../app/videostreaming/vscommon/qt_audio_player.h

RESOURCES += startup_audio.qrc
