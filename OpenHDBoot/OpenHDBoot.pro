!equals(QT_MAJOR_VERSION, 5) | !greaterThan(QT_MINOR_VERSION, 12) {
    error("Unsupported Qt version, 5.12+ is required")
}

BASEDIR = $$IN_PWD

LANGUAGE = C++
CONFIG += c++11
CONFIG+=sdk_no_version_check

include($$PWD/../platforms.pri)

include($$PWD/../git.pri)

include ($$PWD/../lib/SortFilterProxyModel/SortFilterProxyModel.pri)

QT += quick concurrent opengl gui


# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

INCLUDEPATH += $$PWD/../inc
INCLUDEPATH += $$PWD/../lib/mavlink_generated/include/mavlink/v2.0

SOURCES += \
        main.cpp \
        $$PWD/../src/util.cpp \
        $$PWD/../src/MavlinkBase.cpp \
        $$PWD/../src/statusmicroservice.cpp \
        $$PWD/../src/statuslogmodel.cpp \
        smartsync.cpp

HEADERS += \
    $$PWD/../inc/util.h \
    $$PWD/../inc/mavlinkbase.h \
    $$PWD/../inc/statusmicroservice.h \
    $$PWD/../inc/statuslogmodel.h \
    smartsync.h

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
