import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

// See corresponding .cpp for more info
Card {
    id: restartqopenhdmessagebox
    width: 320
    height: 240
    z: 6.0
    anchors.centerIn: parent
    cardName: qsTr("QOpenHD")
    cardNameColor: "black"
    visible:  _restartqopenhdmessagebox.visible
    cardBody: Column {
        height: 200
        width: 320
        Text {
            id: text
            text:  _restartqopenhdmessagebox.text
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
            Material.accent: Material.Grey
            highlighted: true
            text:  qsTr("Restart now")
            onPressed: {
                _restartqopenhdmessagebox.hide_element()
                // Let service restart
                _qopenhd.quit_qopenhd();
            }
        }
        Button {
            width: 140
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
