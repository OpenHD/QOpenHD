import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

Item {
    height: 24
    clip: true

    Text {
        id: messageIcon
        width: 24
        height: 24
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        font.family: "Font Awesome 5 Free"
        font.pixelSize: 18

        // @disable-check M223
        color: {
            switch (model.level) {
            case 0: return "#fa0000"; // error
            case 1: return "#fa0000"; // error
            case 2: return "#fa0000"; // error
            case 3: return "#fa0000"; // error
            case 4: return "#fffa00"; // warning
            case 5: return "#ffffff"; // notice
            case 6: return "#00ea00"; // info
            case 7: return "#0000ea"; // debug
            default: return "#00ea00";
            }
        }

        // @disable-check M223
        text: {
            switch (model.level) {

            case 0: return "\uf057"; // red error
            case 1: return "\uf057"; // red error
            case 2: return "\uf057"; // red error
            case 3: return "\uf057"; // red error
            case 4: return "\uf071"; // yellow warning
            case 5: return "\uf05a"; // white info
            case 6: return "\uf05a"; // blue info
            case 7: return "\uf188"; // green debug
            default: return "\uf05a";
            }
        }

        font.bold: true
    }

    Text {
        height: parent.height
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.bold: true
        color: "#ffffffff"
        anchors.left: messageIcon.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - 24
        text: model.text
        leftPadding: 6
        rightPadding: 0
    }
}
