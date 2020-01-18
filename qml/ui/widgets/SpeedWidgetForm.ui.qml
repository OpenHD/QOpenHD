import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedWidget
    width: 64
    height: 24

    visible: settings.show_speed

    defaultXOffset: 20
    defaultVCenter: true

    widgetIdentifier: "speed_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Airspeed or GPS"
                horizontalAlignment: Text.AlignRight
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value("airpeed_gps",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("airspeed_gps", checked)
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: "black"
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            anchors.fill: parent
            id: speed_text
            color: "white"
            text: Number(OpenHD.speed).toLocaleString(Qt.locale(), 'f', 0);
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Shape {
            id: outline
            anchors.fill: parent
            rotation: 180
            ShapePath {
                strokeColor: "white"
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: 12
                PathLine { x: 0;                  y: 12 }
                PathLine { x: 12;                 y: 0 }
                PathLine { x: 58;                 y: 0 }
                PathLine { x: 58;                 y: 24 }
                PathLine { x: 12;                 y: 24 }
                PathLine { x: 0;                  y: 12 }
            }
        }
    }
}

/*##^##
Designer {
    D{i:5;anchors_height:15;anchors_width:30}
}
##^##*/

