import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: bitrateWidget
    width: 104
    height: 24

    visible: settings.show_bitrate

    widgetIdentifier: "bitrate_widget"

    defaultAlignment: 0
    defaultXOffset: 60
    defaultYOffset: 24
    defaultHCenter: false
    defaultVCenter: false


    hasWidgetDetail: true
    widgetDetailWidth: 256
    widgetDetailHeight: 280
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Measured:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.kbitrate_measured/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
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
                text: "Set:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.kbitrate_set/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
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
                text: "Skipped packets:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.skipped_packet_cnt).toLocaleString(Qt.locale(), 'f', 0);
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
                text: "Injection failed:"
                color: "white"
                font.bold: true
                height: parent.height
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: Number(OpenHD.injection_fail_cnt).toLocaleString(Qt.locale(), 'f', 0);
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
                text: "Opacity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: bitrate_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.bitrate_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.bitrate_opacity = bitrate_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Show all data (No) / (Yes)"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.bitrate_showall
                onCheckedChanged: settings.bitrate_showall = checked
            }
        }
    }


    Item {
        id: widgetInner

        anchors.fill: parent
        opacity: settings.bitrate_opacity

        Text {
            id: kbitrate
            y: 0
            width: 84
            height: 24
            color: settings.color_text
            text: Number(OpenHD.kbitrate/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignTop
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 24
            color: settings.color_shape
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: 0
            verticalAlignment: Text.AlignTop
            font.family: "Font Awesome 5 Free"
            styleColor: "#f7f7f7"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id:skipped_text
            visible: settings.bitrate_showall ? true : false
            text:Number(OpenHD.skipped_packet_cnt).toLocaleString(Qt.locale(), 'f', 0)+" Skipped";
            color: settings.color_text
            anchors.top: kbitrate.bottom
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            id:failed_text
            visible: settings.bitrate_showall ? true : false
            text:Number(OpenHD.injection_fail_cnt).toLocaleString(Qt.locale(), 'f', 0)+" Failed";
            color: settings.color_text
            anchors.top: skipped_text.bottom
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }
}
