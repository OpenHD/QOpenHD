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
            case 0: return "#00ff00"; // green debug
            case 1: return "#0000ea"; // blue info
            case 2: return "#0000ea"; // blue notice
            case 3: return "#eaea00"; // yellow warning
            case 4: return "#ea0000"; // red error
            case 5: return "#ea0000"; // red critical
            case 6: return "#ea0000"; // red alert
            case 7: return "#ea0000"; // red emergency
            default: return "#ffffff";
            }
        }

        // @disable-check M223
        text: {
            switch (model.level) {
            case 0: return "\uf188"; // green debug
            case 1: return "\uf05a"; // blue info
            case 2: return "\uf05a"; // blue notice
            case 3: return "\uf071"; // yellow warning
            case 4: return "\uf071"; // red error
            case 5: return "\uf057"; // red critical
            case 6: return "\uf057"; // red alert
            case 7: return "\uf057"; // red emergency
            default: return "\uf05a";
            }
        }

        font.bold: true
        opacity: 0.9 //model.timeout

        // @disable-check M224
        //Behavior on opacity {
        //    NumberAnimation { duration: 1000 }
        //}
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
        opacity: 0.9 //model.timeout
        leftPadding: 6
        rightPadding: 0

        // @disable-check M224
        //Behavior on opacity {
        //    NumberAnimation { duration: 1000 }
        //}


    }
}
