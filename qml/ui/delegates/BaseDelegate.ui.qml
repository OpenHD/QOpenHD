import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13
import QtQuick.Shapes 1.0

Rectangle {
    id: baseDelegate
    width: 504
    height: 64
    color: index % 2 == 0 ? "#8cbfd7f3" : "white"

    property string infoText: model.info


    Text {
        id: showInfoButton
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 18

        text: "\uf059"
        font.family: "Font Awesome 5 Free"
        color: "#aa0648f9"

        width: 36
        height: parent.height
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            // @disable-check M222
            onClicked: delegateInfo.open()
        }
    }


    Text {
        text: model.title
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 36
        verticalAlignment: Text.AlignVCenter
        width: 192
        height: 32
        font.bold: true
        font.pixelSize: 13
        anchors.left: parent.left
    }

    // intended to be overriden by widgets, anything in this item will show up inside the
    // detail popover
    property Item infoComponent: Item {
        anchors.fill: parent

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            z: 1.1
            text: infoText
            wrapMode: Text.WordWrap
        }
        Shape {
            z: 1.0
            id: outline
            anchors.fill: parent
            ShapePath {
                strokeColor: "#8a000000"
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "white"
                startX: 12
                startY: 0
                PathLine { x: delegateInfo.width;     y: 0 }
                PathLine { x: delegateInfo.width;     y: delegateInfo.height }
                PathLine { x: 12;                     y: delegateInfo.height }
                PathLine { x: 12;                     y: 48 }
                PathLine { x: 0;                      y: 40 }
                PathLine { x: 12;                     y: 32 }
                PathLine { x: 12;                     y: 0 }

            }
        }
    }

    Popup {
        id: delegateInfo

        width: 160
        height: 80

        background: Item {}

        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        parent: showInfoButton
        x: 36
        y: -8

        contentItem: infoComponent
    }
}

