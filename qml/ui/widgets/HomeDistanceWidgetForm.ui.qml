import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: homeDistanceWidget
    width: 96
    height: 24

    widgetIdentifier: "home_distance_widget"

    defaultAlignment: 2
    defaultXOffset: 0
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: home_icon
            x: 0

            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf015"
            anchors.right: home_distance_text.left
            anchors.rightMargin: 6
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: home_distance_text
            width: 64
            height: 24
            color: "#ffffff"
            text: qsTr("00000ft")
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
        }
    }
}
