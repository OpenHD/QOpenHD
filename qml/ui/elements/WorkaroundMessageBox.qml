import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

// We need this one to display popup messages to the user on platforms that don't support
// QMessageBox (e.g. eglfs) since QMessageBox wants to open a new window
// TODO make me less dirty / hacky
// See the corrseponding .cpp class for more info
Card {
    id: workaroundMessageBox
    width: 360
    height: 340
    z: 20.0
    anchors.centerIn: parent
    cardName: qsTr("QOpenHD")+(_messageBoxInstance.remaining_time_seconds==-1 ? "" : ("   "+_messageBoxInstance.remaining_time_seconds+"s"))
    cardNameColor: "black"
    visible: _messageBoxInstance.visible
    cardBody: Column {
        height: 200
        width: 320
        Text {
            id: workaroundMessageBox_text
            text: _messageBoxInstance.text
            width: parent.width-24
            height:parent.height
            leftPadding: 12
            rightPadding: 12
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
                _messageBoxInstance.okay_button_clicked()
                hudOverlayGrid.regain_focus()
            }
            // In case the message is removed automatically after 1 or less seconds, we don't show it
            visible: (_messageBoxInstance.remaining_time_seconds==-1) || (_messageBoxInstance.remaining_time_seconds>1)
        }
    }
}
