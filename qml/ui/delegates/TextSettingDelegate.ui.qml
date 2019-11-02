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
        anchors.leftMargin: 12
        verticalAlignment: Text.AlignVCenter
        width: 192
        height: 32
        font.bold: true
        font.pixelSize: 13
        anchors.left: parent.left
    }

    TextField {
        anchors.right: parent.right
        font.pixelSize: 14
        topPadding: 0
        anchors.verticalCenter: parent.verticalCenter
        bottomPadding: 8
        horizontalAlignment: Text.AlignRight
        anchors.rightMargin: 12
        width: 192
        height: 32
        // @disable-check M223
        Component.onCompleted: {
            text = model.value
            cursorPosition = 0
        }
        // @disable-check M223
        onTextChanged: {
            model.value = text;
            model.modified = true;
        }
        enabled: !model.blacklisted
    }
}
