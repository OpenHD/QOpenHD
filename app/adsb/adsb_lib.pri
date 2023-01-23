INCLUDEPATH += $$PWD

SOURCES += \
    $$PWD/adsb.cpp \
    $$PWD/markermodel.cpp \
    $$PWD/ADSBVehicle.cpp \
    $$PWD/ADSBVehicleManager.cpp \

HEADERS += \
    $$PWD/adsb.h \
    $$PWD/markermodel.h \
    $$PWD/ADSBVehicle.h \
    $$PWD/ADSBVehicleManager.h \


QT += positioning
QT += concurrent

# used in main.cpp to enable/disable adsb
DEFINES += QOPENHD_ENABLE_ADSB_LIBRARY
