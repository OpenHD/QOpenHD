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
    }

    Glow {
        anchors.fill: widgetInner
        visible: settings.show_fpv
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.fpv_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        width: 40
        anchors.verticalCenter: parent.verticalCenter

        rotation: settings.fpv_dynamic ? (settings.horizon_invert_roll ? OpenHD.roll : -OpenHD.roll) : 0

        //had to add another item to compensate for rotation above
        Item {
            id: fpvInner

            height: 40
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            anchors.verticalCenter: parent.verticalCenter

            transformOrigin: Item.Center
            transform: Translate {

                x: settings.fpv_dynamic ? OpenHD.lateral_speed * settings.fpv_sensitivity : 0

                //to get pitch relative to ahi add pitch in
                y: settings.fpv_dynamic ? (settings.horizon_invert_pitch ? (-OpenHD.vz * settings.fpv_sensitivity) - OpenHD.pitch :
                                               (OpenHD.vz * settings.fpv_sensitivity) + OpenHD.pitch) : 0
             }


            antialiasing: true

            Text {
                id: widgetGlyph
                width: 24
                height: 24
                color: settings.color_shape
                opacity: settings.fpv_opacity
                text: "\ufdd5"
                bottomPadding: 17
                leftPadding: 33
                horizontalAlignment: Text.AlignHCenter
                font.capitalization: Font.MixedCase
                renderType: Text.QtRendering
                textFormat: Text.AutoText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: "Font Awesome 5 Free"
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 24
            }
        }
    }
}



