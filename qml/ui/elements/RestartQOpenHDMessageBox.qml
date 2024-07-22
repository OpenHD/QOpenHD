import QtQuick 2.12
import QtQuick.Controls 2.12
 
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

// See corresponding .cpp for more info
Card {
    id: restartqopenhdmessagebox
    width: 300
    height: 200
    z: 6.0
    anchors.centerIn: parent
    cardName: qsTr("QOpenHD")
    cardNameColor: "black"
    visible:  _restartqopenhdmessagebox.visible
    Rectangle {
        width: parent.width-24
        height: parent.height-75
        color: "transparent"
        anchors.centerIn: parent

        Column {
            anchors.fill: parent

            Text {
                id: text
                text: _restartqopenhdmessagebox.text
                width: parent.width - 24
                height: parent.height
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        Button {
            width: 120
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Grey
            highlighted: true
            text:  qsTr("Restart")
            onPressed: {
                _restartqopenhdmessagebox.hide_element()
                // Let service restart
                _qopenhd.quit_qopenhd();
            }
        }
        Button {
            width: 120
            height: 48
            anchors.left: parent.left
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Green
            highlighted: true
            text:  qsTr("Cancel")
            onPressed: {
                _restartqopenhdmessagebox.hide_element();
            }
        }
    }
}
