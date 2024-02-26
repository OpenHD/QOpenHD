import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
 

// UI element for a header
// consisting of a title an a close button
Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 32

    property string m_text: "FILL ME"

    // should be overridden by implementation
    signal closeButtonClicked();

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
        anchors.top: parent.top
        anchors.right: parent.right
        id:closeButton
        text: "X"
        height:42
        width:42
        background: Rectangle {
            Layout.fillHeight: parent
            Layout.fillWidth: parent
            color: closeButton.hovered ? "darkgrey" : "lightgrey"
        }
        onClicked: {
            closeButtonClicked();
        }
    }



}
