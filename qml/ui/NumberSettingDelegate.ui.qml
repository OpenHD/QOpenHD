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

    SpinBox {
        id: spinBox
        x: 382
        y: 8
        width: 210
        height: 48
        font.pixelSize: 14
        from: 0
        to: 100
        stepSize: 1
        value: model.value
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        onValueChanged: model.modified = true
    }
}
