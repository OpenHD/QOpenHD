import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

// Allows the user to switch between simple and advanced view
Rectangle {
    width: parent.width
    height: rowHeight*2 / 3;
    //color: "green"
    //color: "#8cbfd7f3"
    color: "#8cbfd7f3"
    //color: "#333c4c"

    property bool m_is_advanced_selected: false

    Switch{
        text: m_is_advanced_selected ? "ADVANCED" : "SIMPLE"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.left: parent.left
        //anchors.leftMargin: 10
        //font.pixelSize: 20
        checked: m_is_advanced_selected
        onCheckedChanged: {
            m_is_advanced_selected=checked
        }
    }

    Rectangle{
        width: parent.width
        height: 2
        color: "black"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }
}
