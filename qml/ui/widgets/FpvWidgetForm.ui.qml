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

        transform: Translate {
            x: OpenHD.vy
            //to get pitch relative to ahi add pitch in
            y: OpenHD.vz + OpenHD.pitch_raw
        }
        antialiasing: true

        Text {
            id: widgetGlyph
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\ufdd5"
            bottomPadding: 17
            leftPadding: 33
            horizontalAlignment: Text.AlignHCenter
            font.capitalization: Font.MixedCase
            renderType: Text.QtRendering
            textFormat: Text.AutoText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free-Solid-900.otf"
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 24
        }
    }
}

/*##^##
Designer {
    D{i:3;anchors_height:24;anchors_width:24;anchors_y:0}
}
##^##*/

