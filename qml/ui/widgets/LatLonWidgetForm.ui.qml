import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: latLongWidget
    width: 104
    height: 48

    widgetIdentifier: "lat_long_widget"


    defaultAlignment: 3
    defaultXOffset: 96
    defaultYOffset: 0
    defaultHCenter: false
    defaultVCenter: false

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: lat
            width: 92
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.homelat
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            anchors.top: parent.top
            font.pixelSize: 14
        }

        Text {
            id: lon
            width: 92
            height: 24
            color: "#ffffff"
            text: MavlinkTelemetry.homelon
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            anchors.bottom: parent.bottom
            font.pixelSize: 14
        }
    }
}
