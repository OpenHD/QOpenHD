import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    property alias gaugeAngle: throttleArc.sweepAngle

    id: throttleWidget
    width: 96
    height: 68

    widgetIdentifier: "throttle_widget"

    defaultAlignment: 2
    defaultXOffset: 72
    defaultYOffset: 58
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {

    }

    Item {
        id: widgetInner

        anchors.fill: parent
        Text {
            id: throttle_percent
            y: 0
            width: 24
            height: 18
            color: "#ffffff"
            text: OpenHD.throttle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 18
        }

        Shape {
            id: throttleGauge
            anchors.fill: parent

            scale: 1.0

            ShapePath {
                id: throttleShape

                fillColor: "transparent"
                strokeColor: "white"
                strokeWidth: 9
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    id: throttleArc
                    centerX: 48; centerY: 48
                    radiusX: 32; radiusY: 32
                    startAngle: -180
                }
            }
        }

        Text {
            id: throttle_description
            y: 0
            width: parent.width
            height: 14
            color: "#ffffff"
            text: qsTr("throttle")
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }
    }
}
