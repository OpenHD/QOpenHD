import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: bitrateWidget
    width: 112
    height: 48

    visible: settings.show_bitrate

    widgetIdentifier: "bitrate_widget"

    defaultAlignment: 1
    defaultXOffset: 224
    defaultYOffset: 0
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
                text: qsTr("Measured:")
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
                text: qsTr("Set:")
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
                text: qsTr("Skipped packets:")
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
                text: qsTr("Injection failed:")
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
                text: qsTr("Transparency")
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
                text: qsTr("Show skip / fail count")
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
                checked: settings.bitrate_show_skip_fail_count
                onCheckedChanged: settings.bitrate_show_skip_fail_count = checked
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
            height: 48
            color: settings.color_text
            text: Number(OpenHD.kbitrate/1024.0).toLocaleString(Qt.locale(), 'f', 1) + " Mbit";
            anchors.verticalCenterOffset: 0
            anchors.left: camera_icon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            clip: false
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 18
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: camera_icon
            y: 0
            width: 24
            height: 48
            color: {
                if (OpenHD.kbitrate_measured <= 0.1) {
                    return settings.color_shape;
                }

                return (OpenHD.kbitrate / OpenHD.kbitrate_measured) >= 0.70 ? ((OpenHD.kbitrate / OpenHD.kbitrate_measured) >= 0.80 ? "#ff0000" : "#fbfd15") : settings.color_shape
            }
            text: "\uf03d"
            anchors.left: parent.left
            anchors.leftMargin: -2
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
            style: Text.Outline
            styleColor: settings.color_glow
        }

        Text {
            id: allDataText
            visible: settings.bitrate_show_skip_fail_count
            text: Number(OpenHD.injection_fail_cnt).toLocaleString(Qt.locale(), 'f', 0) + "/" + Number(OpenHD.skipped_packet_cnt).toLocaleString(Qt.locale(), 'f', 0)
            color: settings.color_text
            anchors.top: kbitrate.bottom
            anchors.topMargin: -16
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
