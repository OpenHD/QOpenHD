QT = core gui widgets qml quick charts testlib
CONFIG += console c++17
CONFIG -= app_bundle
TARGET = channel_survey_test
SOURCES += channel_survey_test.cpp ../app/telemetry/settings/pollutionhelper.cpp ../app/telemetry/settings/frequencyhelper.cpp
HEADERS += ../app/telemetry/settings/pollutionhelper.h ../app/telemetry/settings/frequencyhelper.h
RESOURCES += channel_survey_test.qrc
