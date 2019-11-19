import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: flightModeWidget
    width: 212
    height: 48

    widgetIdentifier: "flight_mode_widget"

    defaultAlignment: 3
    defaultHCenter: true
    defaultVCenter: false

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: flight_mode_icon
            width: 24
            height: 48
            color: "#ffffff"
            text: "\uf072"
            anchors.right: flight_mode_text.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 20
        }

        Text {
            id: flight_mode_text

            height: 48
            color: "#ffffff"
            text: OpenHD.flight_mode
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 24
            elide: Text.ElideRight
        }
    }
}
