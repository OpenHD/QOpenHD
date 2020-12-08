import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 50

    visible: settings.show_fpv

    widgetIdentifier: "fpv_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                text: qsTr("Dynamic")
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
                checked: settings.fpv_dynamic
                onCheckedChanged: settings.fpv_dynamic = checked
            }
        }
        /* might add this back in if ppl dont like actual only fpv
        Item {
            width: parent.width
            height: 32
            Text {
                id: sensitivityTitle
                text: qsTr("Sensitivity")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: fpvSlider
                orientation: Qt.Horizontal
                from: 1
                value: settings.fpv_sensitivity
                to: 20
                stepSize: 1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fpv_sensitivity = fpvSlider.value
                }
            }
        }
        */
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
                id: fpv_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.fpv_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fpv_opacity = fpv_opacity_Slider.value
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
                id: fpv_size_Slider
                orientation: Qt.Horizontal
                from: .5
                value: settings.fpv_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fpv_size = fpv_size_Slider.value
                }
            }
        }
        Item {
            width: 230
            height: 32
            Text {
                text: qsTr("Invert Pitch")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.fpv_invert_pitch
                onCheckedChanged: settings.fpv_invert_pitch = checked
            }
        }
        /* not really needed
        Item {
            width: 230
            height: 32
            Text {
                id: invertTitle
                text: qsTr("Invert Roll")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.fpv_invert_roll
                onCheckedChanged: settings.fpv_invert_roll = checked
            }
        }
        */
    }



    Item {
        id: widgetInner
        height: 40

        width: 40

        anchors.centerIn: parent

        visible: settings.show_fpv
        opacity: settings.fpv_opacity


        Item {
            id: flightPathVector

            anchors.centerIn: parent

            visible: settings.show_fpv

            //transform: Scale { origin.x: 0; origin.y: 0; xScale: settings.fpv_size ; yScale: settings.fpv_size}


            FlightPathVector {
                id: fpvC
                anchors.centerIn: parent
                /* could turn the width and height into settings and thereby clip the fpv
                  *even theough clipping is false it still clips
                */
                width: 1200
                height: 800
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                fpvInvertPitch: settings.fpv_invert_pitch
                fpvInvertRoll: settings.fpv_invert_roll
/*
                fpvSensitivity:
                fpvActual:
                fpvPipper:
*/
                pitch: settings.fpv_dynamic ? OpenHD.pitch : 0.0
                roll: settings.fpv_dynamic ? OpenHD.roll : 0.0

                lateral: settings.fpv_dynamic ? OpenHD.vehicle_vx_angle : 0.0
                vertical: settings.fpv_dynamic ? OpenHD.vehicle_vz_angle : 0.0

                // referencing the horizon so that fpv moves accurately
                horizonSpacing: settings.horizon_ladder_spacing
                horizonWidth: settings.horizon_width
                fpvSize: settings.fpv_size
            }
        }
    }
}


