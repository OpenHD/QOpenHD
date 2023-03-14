INCLUDEPATH += $$PWD

SOURCES += \
    $$PWD/adsb.cpp \
    $$PWD/markermodel.cpp \
    $$PWD/ADSBVehicle.cpp \
    $$PWD/ADSBVehicleManager.cpp \
    $$PWD/QmlObjectListModel.cpp \


HEADERS += \
    $$PWD/adsb.h \
    $$PWD/markermodel.h \
    $$PWD/ADSBVehicle.h \
    $$PWD/ADSBVehicleManager.h \
    $$PWD/QmlObjectListModel.h \


QT += positioning
QT += concurrent

# used in main.cpp / qml to enable/disable adsb depending on weather the needed platform dependencies were found
DEFINES += QOPENHD_ENABLE_ADSB_LIBRARY
