import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

Rectangle {
    id: rectangle
    width: 504
    height: 64
    color: index % 2 == 0 ? "#8cbfd7f3" : "white"

    Text {
        text: model.title
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        verticalAlignment: Text.AlignVCenter
        width: 192
        height: 32
        font.bold: true
        font.pixelSize: 13
        anchors.left: parent.left
    }

    Switch {
        anchors.right: parent.right
        checked: model.value
        font.pixelSize: 16
        topPadding: 0
        anchors.verticalCenter: parent.verticalCenter
        bottomPadding: 0
        anchors.rightMargin: 12
        width: 32
        height: 32
    }
}
