import QtQuick 2.12
import QtQuick.Controls 2.12

import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

// We need this one to display popup messages to the user on platforms that don't support
// QMessageBox (e.g. eglfs) since QMessageBox wants to open a new window
// TODO make me less dirty / hacky
// See the corrseponding .cpp class for more info
Card {
    id: errorMessageBox
    width: 360
    height: 340
    z: 20.0
    anchors.centerIn: parent
    cardName: qsTr("ERROR")
    cardNameColor: "red"
    visible: _qopenhd.error_message_text!==""
    cardBody: ScrollView {
        contentHeight: errorMessageBox_text.height
        contentWidth: errorMessageBox_text.width
        ScrollBar.vertical.interactive: true
        height: 200
        width: 350
        clip:true
        anchors.centerIn: parent.Center
        Text {
            id: errorMessageBox_text
            width: 320
            text: _qopenhd.error_message_text
            leftPadding: 12
            rightPadding: 12
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Green
            highlighted: true
            text:  qsTr("Okay")
            onPressed: {
                _qopenhd.show_error_message("")
                hudOverlayGrid.regain_focus()
            }
        }
    }
}
