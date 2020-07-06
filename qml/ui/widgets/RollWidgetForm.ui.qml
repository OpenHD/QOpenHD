import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: rollWidget
    width: 100
    height:30

    visible: settings.show_roll

    widgetIdentifier: "roll_widget"

    defaultXOffset: 0
    defaultYOffset: 90
    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailHeight: 175
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Transparency"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: roll_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.roll_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96
                onValueChanged: {
                    settings.roll_opacity = roll_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Invert Roll")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.roll_invert
                onCheckedChanged: settings.roll_invert = checked
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Show Arc")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.roll_show_arc
                onCheckedChanged: settings.roll_show_arc = checked
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Show Numbers")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.roll_show_numbers
                onCheckedChanged: settings.roll_show_numbers = checked
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Sky Pointer")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.roll_sky_pointer
                onCheckedChanged: settings.roll_sky_pointer = checked
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        visible: settings.show_roll
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.control_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        //anchors.fill: parent
        x: -50
        y: -30

        Item {
            id:rollTicks
            anchors.fill: parent
            opacity: settings.roll_opacity

            Shape {
                width: 200
                height: 200
                x: 0
                y: 0
                layer.enabled: true
                layer.samples: 4
                visible: settings.roll_show_arc

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: settings.color_shape
                    strokeWidth: 2
                    capStyle: ShapePath.FlatCap

                    PathAngleArc {
                        centerX: 100; centerY: 150
                        radiusX: 100; radiusY: 100
                        startAngle: -150
                        sweepAngle: 120
                    }
                }
            }

            Item {
                id:right_60_roll
                x: 194
                y: 92

                Rectangle {
                    id:right_60_roll_rect

                    width: 4
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "60"
                    anchors.bottom: right_60_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 0;
                    origin.y: 0;
                    angle: 60
                }
            }

            Item {
                id:right_40_roll
                x: 169
                y: 64

                Rectangle {
                    id:right_40_roll_rect

                    width: 3
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "40"
                    anchors.bottom: right_40_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 0;
                    origin.y: 0;
                    angle: 40
                }
            }

            Item {
                id:right_20_roll
                x: 133
                y: 45

                Rectangle {
                    id:right_20_roll_rect

                    width: 3
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "20"
                    anchors.bottom: right_20_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 2;
                    origin.y: 10;
                    angle: 20
                }
            }

            Shape {
                anchors.fill: parent
                antialiasing: true

                ShapePath {
                    capStyle: ShapePath.RoundCap
                    strokeColor: settings.color_glow
                    fillColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine

                    startX: 100 //bottom point
                    startY: 48
                    PathLine { x: 107;                 y: 41  }//right upper edge
                    PathLine { x: 93;                 y: 41  }//left upper edge
                    PathLine { x: 100;                 y: 48 }
                }
            }

            Item {
                id:left_60_roll
                x: 4
                y: 95
                anchors.leftMargin: 0

                Rectangle {
                    id:left_60_roll_rect

                    width: 3
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "60"
                    anchors.bottom: left_60_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 0;
                    origin.y: 0;
                    angle: -60
                }
            }

            Item {
                id:left_40_roll
                x: 27
                y: 66

                Rectangle {
                    id:left_40_roll_rect

                    width: 3
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "40"
                    anchors.bottom: left_40_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 0;
                    origin.y: 0;
                    angle: -40
                }
            }

            Item {
                id:left_20_roll
                x: 60
                y: 46

                Rectangle {
                    id:left_20_roll_rect

                    width: 3
                    height: 10
                    color: settings.color_shape
                }

                Text {
                    color: settings.color_shape
                    visible: settings.roll_show_numbers
                    text: "20"
                    anchors.bottom: left_20_roll_rect.top
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }

                transform: Rotation {
                    origin.x: 0;
                    origin.y: 0;
                    angle: -20
                }
            }

            transform: Rotation {
                origin.x: 100;
                origin.y: 150;
                angle: settings.roll_sky_pointer ? 0 : (settings.roll_invert ? OpenHD.roll : OpenHD.roll*-1)
            }
        }

        Shape {
            id: pointer
            anchors.fill: parent
            antialiasing: true
            opacity: settings.roll_opacity

            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_glow
                fillColor: settings.color_text
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine

                startX: 100 //top point
                startY: 50
                PathLine { x: 110;                 y: 60  }//right lower edge of arrow
                PathLine { x: 90;                 y: 60  }//left lower edge
                PathLine { x: 100;                 y: 50 }//bottom right edge
            }

            transform: Rotation {
                origin.x: 100;
                origin.y: 150;
                angle: settings.roll_sky_pointer ? (settings.roll_invert ? OpenHD.roll : OpenHD.roll*-1) : 0
            }
        }
    }
}

