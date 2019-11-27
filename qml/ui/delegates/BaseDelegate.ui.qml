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

    property bool showingDetail: false

    clip: true

    Behavior on height {
       NumberAnimation { duration: 200 }
    }

    Text {
        id: showInfoButton
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 18

        text: showingDetail ? "\uf106" : "\uf059"

        Behavior on text {
           PropertyAnimation { duration: 200 }
        }

        font.family: "Font Awesome 5 Free"
        color: "#aa0648f9"

        width: 36
        height: 64
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            // @disable-check M222
            onClicked: {
                //delegateInfo.open()
                if (showingDetail) {
                    showingDetail = false;
                    baseDelegate.height -= 64;
                } else {
                    showingDetail = true;
                    baseDelegate.height += 64;
                }
            }
        }
    }


    Text {
        text: model.title
        anchors.leftMargin: 36
        anchors.top: parent.top
        anchors.topMargin: 16
        verticalAlignment: Text.AlignVCenter
        width: 192
        height: 32
        font.bold: true
        font.pixelSize: 13
        anchors.left: parent.left
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        text: infoText
        wrapMode: Text.WordWrap
        font.pixelSize: 12
        visible: true
    }
}

