import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: gpsWidget
    width: 96
    height: 24

    visible: settings.show_gps

    widgetIdentifier: "gps_widget"

    defaultAlignment: 2
    defaultXOffset: 96
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailHeight: 192

    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Lat:")
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.lat).toLocaleString(Qt.locale(), 'f', 6);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Lon:")
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.lon).toLocaleString(Qt.locale(), 'f', 6);
                color: "white";
                font.bold: true;
                height: parent.height
                font.pixelSize: detailPanelFontPixels;
                anchors.right: parent.right
                verticalAlignment: Text.AlignVCenter
            }
        }

        Shape {
            id: line
            height: 32
            width: parent.width

            ShapePath {
                strokeColor: "white"
                strokeWidth: 2
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: line.height / 2
                PathLine { x: 0;          y: line.height / 2 }
                PathLine { x: line.width; y: line.height / 2 }
            }
        }

        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: qsTr("Transparency")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: gps_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.gps_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.gps_opacity = gps_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Size")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: gps_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.gps_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.gps_size = gps_size_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Always show lat/lon")
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
                checked: settings.gps_show_all
                onCheckedChanged: settings.gps_show_all = checked
            }
        }
    }

    Item {
        id: widgetInner

        anchors.fill: parent
        scale: settings.gps_size

        Text {
            id: satellite_icon
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            opacity: settings.gps_opacity
            text: "\uf0ac"
            anchors.right: satellites_visible.left
            anchors.rightMargin: 6
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: satellites_visible
            y: 0
            width: 24
            height: 24
            color: settings.color_text
            opacity: settings.gps_opacity
            text: OpenHD.satellites_visible
            anchors.right: gps_hdop.left
            anchors.rightMargin: 2
            elide: Text.ElideNone
            clip: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 16
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: gps_hdop
            width: 48
            height: 24
            color: settings.color_text
            opacity: settings.gps_opacity
            text: qsTr("%L1").arg(OpenHD.gps_hdop)
            anchors.right: parent.right
            anchors.rightMargin: 0
            verticalAlignment: Text.AlignTop
            font.pixelSize: 10
            horizontalAlignment: Text.AlignLeft
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Column {
            id: lat_lon_column
            anchors.bottom: parent.top
            anchors.left: parent.left
            anchors.leftMargin: -12

            spacing: 0

            Row {
                spacing: 6
                height: 16

                Text {//need better icon
                    id: lat_icon
                    visible: settings.gps_show_all
                    height: parent.height
                    width: 32
                    color: settings.color_shape
                    opacity: settings.gps_opacity
                    //font.family: "Font Awesome 5 Free"
                    text: "Lat:"
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 14
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: lat_onscreen
                    visible: settings.gps_show_all
                    text: Number(OpenHD.lat).toLocaleString(Qt.locale(), 'f', 6);
                    color: settings.color_text
                    opacity: settings.gps_opacity
                    font.bold: true;
                    height: parent.height
                    width: 92
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }


            Row {
                spacing: 6
                height: 16

                Text {//need better icon
                    id: lon_icon
                    visible: settings.gps_show_all
                    height: parent.height
                    width: 32
                    color: settings.color_shape
                    opacity: settings.gps_opacity
                    //font.family: "Font Awesome 5 Free"
                    text: "Lon:"
                    horizontalAlignment: Text.AlignLeft
                    font.pixelSize: 14
                    style: Text.Outline
                    styleColor: settings.color_glow
                }

                Text {
                    id: lon_onscreen
                    visible: settings.gps_show_all
                    text: Number(OpenHD.lon).toLocaleString(Qt.locale(), 'f', 6);
                    color: settings.color_text
                    opacity: settings.gps_opacity
                    font.bold: true
                    height: parent.height
                    width: 92
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                    style: Text.Outline
                    styleColor: settings.color_glow
                }
            }
        }
    }
}
