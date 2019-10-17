import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightTimerWidget
    width: 96
    height: 24

    widgetIdentifier: "flight_timer_widget"

    defaultAlignment: 2
    defaultXOffset: 0
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: flight_timer_text
            y: 0
            width: 64
            height: 24
            color: "#ffffff"
            text: qsTr("0:00")
            elide: Text.ElideRight
            anchors.right: parent.right
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
        }

        Text {
            id: time_icon
            x: 0
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf017"
            font.family: "Font Awesome 5 Free"
            anchors.right: flight_timer_text.left
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            styleColor: "#f7f7f7"
            anchors.rightMargin: 6
            font.pixelSize: 14
        }
    }
}
