QT = core network testlib
CONFIG += console c++17
CONFIG -= app_bundle
TARGET = async_ping_test
INCLUDEPATH += ../app/util
SOURCES += async_ping_test.cpp ../app/util/asyncping.cpp ../app/util/asynccommandrunner.cpp
HEADERS += ../app/util/asyncping.h ../app/util/asynccommandrunner.h
