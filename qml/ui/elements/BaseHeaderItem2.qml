import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

Item {
    width: parent.width
    height: 32

    property string m_text: "FILL ME"

    Rectangle{
        anchors.fill: parent
        color: "#8cbfd7f3"
    }

    Rectangle{
        width: parent.width
        height: 2
        color: "black"
        anchors.bottom: parent.bottom
    }

    Text{
        text: qsTr(m_text)
        font.weight: Font.Bold
        font.pixelSize: 13
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Button {
        id:closeButton
        text: "X"
        height:42
        width:42
        anchors.right: parent.right
        anchors.rightMargin: 2
        background: Rectangle {
            Layout.fillHeight: parent
            Layout.fillWidth: parent
            color: closeButton.hovered ? "darkgrey" : "lightgrey"
        }
        onClicked: {
            close()
        }
    }
}
