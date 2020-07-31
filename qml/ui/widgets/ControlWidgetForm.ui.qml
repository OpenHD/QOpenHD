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
    defaultXOffset: 20
    defaultYOffset: 50
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: controlSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: controlSettingsColumn
            spacing:0
            clip: true
            Item {
                width: 240
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
                width: 240
                height: 32
                Text {
                    id: displaySwitcher
                    text: qsTr("Show two controls")
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
                    checked: settings.double_control
                    onCheckedChanged: settings.double_control = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Pitch")
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
                    checked: settings.control_rev_pitch
                    onCheckedChanged: settings.control_rev_pitch = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Roll")
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
                    checked: settings.control_rev_roll
                    onCheckedChanged: settings.control_rev_roll = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse yaw")
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
                    checked: settings.control_rev_yaw
                    onCheckedChanged: settings.control_rev_yaw = checked
                }
            }
            Item {
                width: 240
                height: 32
                Text {
                    text: qsTr("Reverse Throttle")
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
                    checked: settings.control_rev_throttle
                    onCheckedChanged: settings.control_rev_throttle = checked
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

            visible: !settings.double_control

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
                color: settings.color_text
                //radius: width*0.5

                visible: OpenHD.control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_yaw ? ((OpenHD.control_yaw-1500)/10)*-1:(OpenHD.control_yaw-1500)/10
                    y: settings.control_rev_throttle ? ((OpenHD.control_throttle-2000)/10)+50:((OpenHD.control_throttle-2000)/10)*-1 -50
                }

            }

            Rectangle {
                id: right_control
                anchors.centerIn: singleCircle
                width: (parent.width<parent.height?parent.width:parent.height)*.1
                height: width
                color: settings.color_text
                radius: width*0.5

                visible: OpenHD.control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_roll ? ((OpenHD.control_roll-1500)/10)*-1:(OpenHD.control_roll-1500)/10
                    y: settings.control_rev_pitch ? ((OpenHD.control_pitch-1500)/10)*-1:(OpenHD.control_pitch-1500)/10
                }

            }
        }

//------------------------------ Double Circle Version start------------------

        Item {
            id: doubleCircle
            height: parent.height
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            visible: settings.double_control

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
                color: settings.color_text
                radius: width*0.5

                visible: OpenHD.control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_yaw ? (((OpenHD.control_yaw-1500)/10)/2)*-1:((OpenHD.control_yaw-1500)/10)/2
                    y: settings.control_rev_throttle ? ((((OpenHD.control_throttle-2000)/10)*-1 -50)/2)*-1:(((OpenHD.control_throttle-2000)/10)*-1 -50)/2
                }

            }

            Rectangle {
                id: right_control_double
                anchors.centerIn: rightCircle
                width: (parent.width<parent.height?parent.width:parent.height)*.1
                height: width
                color: settings.color_text
                radius: width*0.5

                visible: OpenHD.control_throttle < 1000 ? false : true

                transformOrigin: Item.Center

                transform: Translate {
                    x: settings.control_rev_roll ? (((OpenHD.control_roll-1500)/10)/2)*-1:((OpenHD.control_roll-1500)/10)/2
                    y: settings.control_rev_pitch ? (((OpenHD.control_pitch-1500)/10)/2)*-1:((OpenHD.control_pitch-1500)/10)/2
                }

            }
        }
    }
}
