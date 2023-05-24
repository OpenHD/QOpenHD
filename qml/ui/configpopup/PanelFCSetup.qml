import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true

    property int rowHeight: 64
    property int text_minHeight: 20

    color: "#eaeaea"

    ColumnLayout{
        Layout.fillWidth: true
        Layout.minimumHeight: 30
        spacing: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Button{
            height: 24
            text: "Set Ardupilot Message rates"
            onClicked:{

            }
        }
    }
}

