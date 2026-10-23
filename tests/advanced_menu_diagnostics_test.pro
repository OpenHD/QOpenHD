QT = core gui quick
CONFIG += console c++17
CONFIG -= app_bundle
TARGET = advanced_menu_diagnostics_test
INCLUDEPATH += ../app
SOURCES += advanced_menu_diagnostics_test.cpp ../app/util/advancedmenudiagnostics.cpp
HEADERS += ../app/util/advancedmenudiagnostics.h
