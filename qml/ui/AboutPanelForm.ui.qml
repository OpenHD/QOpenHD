import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

Rectangle {
    id: element2
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: "#000000"
    property alias license: license

    Text {
        id: title
        height: 48
        color: "#eaffffff"
        text: qsTr("QOpenHD")
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 247
        anchors.left: image.right
        anchors.leftMargin: 12
        verticalAlignment: Text.AlignTop
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 36
    }


    Image {
        id: image
        width: 48
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 24
        height: 48
        source: "qrc:/ic.png"
        fillMode: Image.PreserveAspectFit
    }

    Text {
        id: qopenhd_version
        width: 173
        height: 14
        color: "#b3ffffff"
        text: QOPENHD_VERSION
        anchors.left: title.left
        anchors.leftMargin: 0
        anchors.top: title.bottom
        anchors.topMargin: 0
        font.pixelSize: 12
    }

    Text {
        id: openhd_version
        width: 173
        height: 14
        clip: true
        color: "#b3ffffff"
        text: qsTr("Ground: ") + GroundStatusMicroservice.openHDVersion
        anchors.left: title.left
        anchors.leftMargin: 0
        anchors.top: qopenhd_version.bottom
        anchors.topMargin: 0
        font.pixelSize: 12
    }

    Text {
        id: builder_version
        width: 173
        height: 14
        clip: true
        color: "#b3ffffff"
        text: qsTr("Air: ") + AirStatusMicroservice.openHDVersion
        anchors.left: title.left
        anchors.leftMargin: 0
        anchors.top: openhd_version.bottom
        anchors.topMargin: 0
        font.pixelSize: 12
    }

    Text {
        id: gstreamer_version
        width: 173
        height: 14
        color: "#b3ffffff"
        text: "GStreamer " + OpenHD.gstreamer_version
        anchors.left: title.left
        anchors.leftMargin: 0
        anchors.top: builder_version.bottom
        anchors.topMargin: 0
        font.pixelSize: 12
    }

    Text {
        id: qt_version
        width: 173
        height: 14
        color: "#b3ffffff"
        text: "Qt " + OpenHD.qt_version
        anchors.left: title.left
        anchors.leftMargin: 0
        anchors.top: gstreamer_version.bottom
        anchors.topMargin: 0
        font.pixelSize: 12
    }


    Text {
        id: license
        color: "#b3ffffff"
        text: qsTr("License: GPLv3")
        onLinkActivated: {
            Qt.openUrlExternally("https://github.com/OpenHD/QOpenHD/blob/master/LICENSE")
        }

        font.pointSize: 12
        anchors.top: qt_version.bottom
        anchors.topMargin: 0
        anchors.left: title.left
        anchors.leftMargin: 0
    }
}

/*##^##
Designer {
    D{i:1;anchors_width:224;anchors_x:71;anchors_y:8}D{i:2;anchors_height:15;anchors_width:488;anchors_x:8;anchors_y:91}
D{i:3;anchors_height:106;anchors_width:282;anchors_x:35;anchors_y:110}
}
##^##*/
