import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0


BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    widgetIdentifier: "horizon_widget"

    defaultHCenter: true
    defaultVCenter: true

    Item {
        id: widgetInner
        height: 2
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        transformOrigin: Item.Center
        rotation: -MavlinkTelemetry.roll_raw
        transform: Translate {
            x: Item.Center
            y: MavlinkTelemetry.pitch_raw
        }
        antialiasing: true

        Rectangle {
            width: 100
            height: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }

        Rectangle {
            width: 100
            height: 2
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
        }
    }
}
