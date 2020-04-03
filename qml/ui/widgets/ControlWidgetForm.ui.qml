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

    defaultAlignment: 1
    defaultXOffset: 128
    defaultYOffset: 128
    defaultHCenter: false
    defaultVCenter: false

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
                id: controlOpacitySlider
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
                    settings.control_opacity = controlOpacitySlider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: displaySwitcher
                text: "Controls: Two / One"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.control_version
                onCheckedChanged: settings.control_version = checked
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

/*------------------------------ Single Circle Version start------------------
        this could all be simplified and condensed with either or type of logic. However
        might add a 3rd type of display version then the either or logic would have to
        be undone...
*/
        Item {
            id: singleCircle
            height: parent.height
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            visible: settings.control_version ? true : false

            Rectangle {
                id: circle
                anchors.centerIn: singleCircle
                width: parent.width<parent.height?parent.width:parent.height
                height: width
                color: "transparent"
                radius: width*0.5

                border.color: settings.color_shape
                border.width: 1
            }

            Rectangle {
                id: left_control
                anchors.centerIn: singleCircle
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
                id: right_control
                anchors.centerIn: singleCircle
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
        }

//------------------------------ Double Circle Version start------------------

        Item {
            id: doubleCircle
            height: parent.height
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            visible: settings.control_version ? false : true

            Rectangle {
                id: leftCircle

            //    anchors.right: rightCircle.left
                width: (parent.width<parent.height?parent.width:parent.height)/2
                height: width
                color: "transparent"
                radius: width*0.5


                border.color: settings.color_shape
                border.width: .5
            }

            Rectangle {
                id: rightCircle

                anchors.left: leftCircle.right
                anchors.leftMargin: 5
                width: (parent.width<parent.height?parent.width:parent.height)/2
                height: width
                color: "transparent"
                radius: width*0.5

                border.color: settings.color_shape
                border.width: .5
            }

            Rectangle {
                id: left_control_double
                anchors.centerIn: leftCircle
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
                    x: ((OpenHD.control_yaw-1500)/10)/2
                    y: (((OpenHD.control_throttle-2000)/10)*-1 -50)/2
                }

            }

            Rectangle {
                id: right_control_double
                anchors.centerIn: rightCircle
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
                    x: ((OpenHD.control_roll-1500)/10)/2
                    y: ((OpenHD.control_pitch-1500)/10)/2
                }

            }
        }

        Glow {
            anchors.fill: doubleCircle
            visible: settings.control_version ? false : true
            radius: 2
            samples: 17
            color: settings.color_glow
            opacity: settings.control_opacity
            source: doubleCircle
        }

        Glow {
            anchors.fill: singleCircle
            visible: settings.control_version ? true : false
            radius: 3
            samples: 17
            color: settings.color_glow
            opacity: settings.control_opacity
            source: circle
        }



    }
}
