import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: headingWidget
    width: 48
    height: 48

    visible: settings.show_heading

    defaultYOffset: 50

    widgetIdentifier: "heading_widget"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Toggle Inav"
                color: "white"
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.heading_inav
                onCheckedChanged: settings.heading_inav = checked
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Text {
            id: hdg_text
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height - 24
            color: settings.color_text
            text: Number(
                      settings.heading_inav ? OpenHD.hdg * 100 : OpenHD.hdg).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Shape {
            id: outline
            anchors.fill: parent
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: 0
                PathLine {
                    x: 0
                    y: 0
                }
                PathLine {
                    x: 48
                    y: 0
                }
                PathLine {
                    x: 48
                    y: 24
                }
                PathLine {
                    x: 32
                    y: 24
                }
                PathLine {
                    x: 24
                    y: 32
                }
                PathLine {
                    x: 16
                    y: 24
                }
                PathLine {
                    x: 0
                    y: 24
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }
    }
}
