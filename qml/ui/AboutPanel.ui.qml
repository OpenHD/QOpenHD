import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

Rectangle {
    id: element2
    width: 504
    height: 300
    color: "#000000"

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

    TextArea {
        id: license
        text: qsTr("")
        color: "#b3ffffff"
        placeholderText: "GPL license here"
        font.pointSize: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: title.bottom
        anchors.topMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24
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
}

/*##^##
Designer {
    D{i:1;anchors_width:224;anchors_x:71;anchors_y:8}D{i:2;anchors_height:15;anchors_width:488;anchors_x:8;anchors_y:91}
D{i:3;anchors_height:106;anchors_width:282;anchors_x:35;anchors_y:110}
}
##^##*/
