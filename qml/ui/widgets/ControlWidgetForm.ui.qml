import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: controlWidget
    width: 100
    height: 100

    visible: settings.show_control

    widgetIdentifier: "control_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: Column {
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
                id: control_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.control_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.control_opacity = control_opacity_Slider.value
                }
            }
        }
    }

    Item {
        id: widgetInner
        height: parent.height
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        opacity: settings.control_opacity

        antialiasing: true

        Rectangle {
            id: left_control
            anchors.centerIn: parent
            width: (parent.width<parent.height?parent.width:parent.height)*.1
            height: width
            color: settings.color_shape
            radius: width*0.5

            visible: {
                if (OpenHD.control_throttle < 1000){
                    console.log("Throttle control < 1000");
                    left_control.visible=false;
                }else {
                     left_control.visible=true;
                }
            }

            transformOrigin: Item.Center

            transform: Translate {
                x: (OpenHD.control_yaw-1500)/10
                y: ((OpenHD.control_throttle-2000)/10)*-1 -50
            }

        }

        Rectangle {
            id: circle
            anchors.centerIn: parent
            width: parent.width<parent.height?parent.width:parent.height
            height: width
            color: "transparent"
            radius: width*0.5

            border.color: settings.color_shape
            border.width: 1
        }

        Rectangle {
            id: right_control
            anchors.centerIn: parent
            width: (parent.width<parent.height?parent.width:parent.height)*.1
            height: width
            color: settings.color_shape
            radius: width*0.5

            visible: {
                if (OpenHD.control_throttle < 1000){
                    console.log("Throttle control < 1000");
                    right_control.visible=false;
                }else {
                     right_control.visible=true;
                }
            }

            transformOrigin: Item.Center

            transform: Translate {
                x: (OpenHD.control_roll-1500)/10
                y: (OpenHD.control_pitch-1500)/10
            }

        }

        Glow {
            anchors.fill: left_control
            radius: 4
            samples: 17
            color: settings.color_glow
            opacity: settings.control_opacity
            source: left_control
        }

        Glow {
            anchors.fill: circle
            radius: 4
            samples: 17
            color: settings.color_glow
            opacity: settings.control_opacity
            source: circle
        }

        Glow {
            anchors.fill: right_control
            radius: 4
            samples: 17
            color: settings.color_glow
            opacity: settings.control_opacity
            source: right_control
        }

    }
}
