import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 50

    widgetIdentifier: "fpv_widget"

    defaultHCenter: true
    defaultVCenter: true

    Item {
        id: widgetInner
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        //so that fpv sits aligned in horizon must add margin
        width: 40
        anchors.verticalCenter: parent.verticalCenter

        transformOrigin: Item.Center
        rotation: -OpenHD.roll_raw
        transform: Translate {
            x: OpenHD.vy
            y: OpenHD.vz
        }
        antialiasing: true

        Text {
            id: fpv_glyph
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\ue8ce"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: "osdicons.ttf"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }
    }
}

/*##^##
Designer {
    D{i:3;anchors_height:24;anchors_width:24;anchors_y:0}
}
##^##*/

