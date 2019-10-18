import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: gpsWidget
    width: 96
    height: 24

    widgetIdentifier: "gps_widget"

    defaultAlignment: 2
    defaultXOffset: 96
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text { text: "Lat:";  color: "white"; font.bold: true; anchors.left: parent.left }
            Text { text: OpenHD.lat; color: "white"; font.bold: true; anchors.right: parent.right }
        }
        Item {
            width: parent.width
            height: 24
            Text { text: "Long:";  color: "white"; font.bold: true; anchors.left: parent.left }
            Text { text: OpenHD.lon; color: "white"; font.bold: true; anchors.right: parent.right }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            id: satellite_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf0ac"
            anchors.right: satellites_visible.left
            anchors.rightMargin: 6
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            styleColor: "#f7f7f7"
            font.pixelSize: 14
        }

        Text {
            id: satellites_visible
            y: 0
            width: 20
            height: 24
            color: "#ffffff"
            text: OpenHD.satellites_visible
            anchors.right: gps_hdop.left
            anchors.rightMargin: 2
            elide: Text.ElideRight
            clip: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 16
        }

        Text {
            id: gps_hdop
            width: 48
            height: 24
            color: "#ffffff"
            text: "(%1)".arg(OpenHD.gps_hdop)
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignTop
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
        }
    }
}
