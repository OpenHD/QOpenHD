QT = core network qml testlib
CONFIG += console c++17
CONFIG -= app_bundle
TARGET = adsb_internet_test
INCLUDEPATH += ../app ../app/adsb
SOURCES += adsb_internet_test.cpp \
    ../app/adsb/adsbvehiclemanager.cpp \
    ../app/adsb/adsbvehicle.cpp \
    ../app/adsb/qmlobjectlistmodel.cpp
HEADERS += ../app/adsb/adsbvehiclemanager.h \
    ../app/adsb/adsbvehicle.h \
    ../app/adsb/qmlobjectlistmodel.h
